#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "stream_consumer_abi.h"

#include "../vendor/picohttpparser/picohttpparser.c"

#define LE_HTTP1_MAX_HEADERS 256

#define LE_HTTP_BODY_NONE 0
#define LE_HTTP_BODY_CONTENT_LENGTH 1
#define LE_HTTP_BODY_CHUNKED 2

#define LE_HTTP_RESPONSE_SERVER_DEFAULT_FINAL 0x01
#define LE_HTTP_RESPONSE_SERVER_SCALAR_SIMPLE 0x02
#define LE_HTTP_RESPONSE_SERVER_HTTP10        0x04
#define LE_HTTP_RESPONSE_SERVER_OBJECT        0x08

#define LE_HTTP_SEMANTICS_OK 0
#define LE_HTTP_SEMANTICS_BAD_REQUEST 400
#define LE_HTTP_SEMANTICS_NOT_IMPLEMENTED 501

typedef struct {
    size_t name_offset;
    size_t name_length;
    size_t value_offset;
    size_t value_length;
} le_http_header_slice;

typedef struct {
    int body_mode;
    int keep_alive;
    int has_content_length;
    int expect_mode;
    UV content_length;
} le_http_request_semantics;

typedef struct {
    int consumed;
    int minor_version;
    int body_mode;
    int keep_alive;
    int has_content_length;
    int expect_mode;
    UV content_length;
    size_t method_offset;
    size_t method_length;
    size_t target_offset;
    size_t target_length;
    size_t num_headers;
    le_http_header_slice *headers;
    char *bytes;
} le_http_request_state;

static void
validate_limits(STRLEN buffer_len, UV last_len, UV max_headers)
{
    if (last_len > (UV)buffer_len)
        croak("last_len exceeds buffer length");
    if (max_headers == 0 || max_headers > LE_HTTP1_MAX_HEADERS)
        croak("max_headers must be between 1 and %d", LE_HTTP1_MAX_HEADERS);
}

static int
parse_request_strict(
    const char *buf,
    size_t buffer_len,
    const char **method,
    size_t *method_len,
    const char **path,
    size_t *path_len,
    int *minor_version,
    struct phr_header *headers,
    size_t *num_headers,
    size_t last_len
)
{
    int consumed = phr_parse_request(
        buf,
        buffer_len,
        method,
        method_len,
        path,
        path_len,
        minor_version,
        headers,
        num_headers,
        last_len
    );
    size_t i;

    if (consumed <= 0)
        return consumed;

    /*
     * RFC 9112 permits a server either to reject or normalize obs-fold.
     * Linux::Event::HTTP rejects it. pico marks continuation lines by
     * returning a header entry with name == NULL.
     */
    for (i = 0; i < *num_headers; ++i) {
        if (headers[i].name == NULL)
            return -1;
    }

    return consumed;
}

static int
ascii_equal_ci(const char *left, size_t left_len, const char *right, size_t right_len)
{
    size_t i;

    if (left_len != right_len)
        return 0;

    for (i = 0; i < left_len; ++i) {
        unsigned char a = (unsigned char)left[i];
        unsigned char b = (unsigned char)right[i];

        if (a >= 'A' && a <= 'Z')
            a = (unsigned char)(a + ('a' - 'A'));
        if (b >= 'A' && b <= 'Z')
            b = (unsigned char)(b + ('a' - 'A'));
        if (a != b)
            return 0;
    }

    return 1;
}

static int
is_ows(unsigned char c)
{
    return c == ' ' || c == '\t';
}

static int
is_tchar(unsigned char c)
{
    if ((c >= '0' && c <= '9') ||
        (c >= 'A' && c <= 'Z') ||
        (c >= 'a' && c <= 'z'))
        return 1;

    switch (c) {
        case '!': case '#': case '$': case '%': case '&': case '\'':
        case '*': case '+': case '-': case '.': case '^': case '_':
        case '`': case '|': case '~':
            return 1;
        default:
            return 0;
    }
}

static int
valid_field_name(const char *name, size_t len)
{
    size_t i;

    if (len == 0)
        return 0;

    for (i = 0; i < len; ++i) {
        if (!is_tchar((unsigned char)name[i]))
            return 0;
    }

    return 1;
}

static int
valid_output_field_value(const char *value, size_t len)
{
    size_t i;

    for (i = 0; i < len; ++i) {
        unsigned char c = (unsigned char)value[i];

        if (c == '\t')
            continue;
        if (c < 0x20 || c == 0x7f)
            return 0;
    }

    return 1;
}

static int
valid_reason_phrase(const char *value, size_t len)
{
    return valid_output_field_value(value, len);
}

static int
valid_host_value(const char *value, size_t len)
{
    size_t i;
    size_t close_bracket = (size_t)-1;
    size_t colon_count = 0;

    if (len == 0)
        return 1;

    for (i = 0; i < len; ++i) {
        unsigned char c = (unsigned char)value[i];

        if (c <= 0x20 || c >= 0x7f)
            return 0;
        if (c == '/' || c == '?' || c == '#' || c == '@')
            return 0;
    }

    if (value[0] == '[') {
        for (i = 1; i < len; ++i) {
            if (value[i] == ']') {
                close_bracket = i;
                break;
            }
        }

        if (close_bracket == (size_t)-1 || close_bracket == 1)
            return 0;

        if (close_bracket + 1 == len)
            return 1;

        if (value[close_bracket + 1] != ':')
            return 0;

        for (i = close_bracket + 2; i < len; ++i) {
            if (value[i] < '0' || value[i] > '9')
                return 0;
        }

        return 1;
    }

    for (i = 0; i < len; ++i) {
        if (value[i] == ':') {
            size_t j;

            ++colon_count;
            if (colon_count > 1)
                return 0;

            for (j = i + 1; j < len; ++j) {
                if (value[j] < '0' || value[j] > '9')
                    return 0;
            }
            break;
        }
    }

    return 1;
}

static int
parse_content_length_field(
    const char *value,
    size_t len,
    UV *content_length,
    int *has_content_length
)
{
    size_t pos = 0;
    int members = 0;
    const UV uv_max = ~(UV)0;

    while (1) {
        UV parsed = 0;
        int digits = 0;

        while (pos < len && is_ows((unsigned char)value[pos]))
            ++pos;

        if (pos == len)
            return 0;

        while (pos < len && value[pos] >= '0' && value[pos] <= '9') {
            UV digit = (UV)(value[pos] - '0');

            if (parsed > uv_max / 10 ||
                (parsed == uv_max / 10 && digit > uv_max % 10))
                return 0;

            parsed = parsed * 10 + digit;
            ++pos;
            ++digits;
        }

        if (digits == 0)
            return 0;

        while (pos < len && is_ows((unsigned char)value[pos]))
            ++pos;

        if (*has_content_length) {
            if (*content_length != parsed)
                return 0;
        } else {
            *content_length = parsed;
            *has_content_length = 1;
        }

        ++members;

        if (pos == len)
            break;

        if (value[pos] != ',')
            return 0;

        ++pos;
    }

    return members != 0;
}

static int
parse_connection_options(
    const char *value,
    size_t len,
    int *saw_close,
    int *saw_keep_alive
)
{
    size_t pos = 0;

    while (pos < len) {
        size_t start;
        size_t end;

        while (pos < len && is_ows((unsigned char)value[pos]))
            ++pos;

        start = pos;
        while (pos < len && value[pos] != ',')
            ++pos;
        end = pos;

        while (end > start && is_ows((unsigned char)value[end - 1]))
            --end;

        if (end > start) {
            if (ascii_equal_ci(value + start, end - start, "close", 5))
                *saw_close = 1;
            else if (ascii_equal_ci(
                         value + start,
                         end - start,
                         "keep-alive",
                         10
                     ))
                *saw_keep_alive = 1;
        }

        if (pos < len)
            ++pos;
    }

    return 1;
}

static int
parse_transfer_encoding_field(
    const char *value,
    size_t len,
    int *coding_count,
    int *chunked_count,
    int *final_is_chunked,
    int *unsupported
)
{
    size_t pos = 0;

    while (1) {
        size_t start;
        size_t token_end;
        size_t member_end;
        int is_chunked;

        while (pos < len && is_ows((unsigned char)value[pos]))
            ++pos;

        if (pos == len)
            return 0;

        start = pos;
        while (pos < len && is_tchar((unsigned char)value[pos]))
            ++pos;
        token_end = pos;

        if (token_end == start)
            return 0;

        while (pos < len && value[pos] != ',')
            ++pos;
        member_end = pos;

        while (member_end > token_end &&
               is_ows((unsigned char)value[member_end - 1]))
            --member_end;

        is_chunked = ascii_equal_ci(
            value + start,
            token_end - start,
            "chunked",
            7
        );

        if (is_chunked) {
            size_t tail = token_end;

            while (tail < member_end && is_ows((unsigned char)value[tail]))
                ++tail;

            if (tail != member_end)
                return 0;

            ++*chunked_count;
        } else {
            *unsupported = 1;
        }

        ++*coding_count;
        *final_is_chunked = is_chunked;

        if (pos == len)
            break;

        ++pos;
    }

    return *coding_count != 0;
}

static int
parse_expect_field(const char *value, size_t len)
{
    size_t pos = 0;
    int members = 0;

    while (1) {
        size_t start;
        size_t end;

        while (pos < len && is_ows((unsigned char)value[pos]))
            ++pos;

        start = pos;
        while (pos < len && value[pos] != ',')
            ++pos;
        end = pos;

        while (end > start && is_ows((unsigned char)value[end - 1]))
            --end;

        if (end == start ||
            !ascii_equal_ci(value + start, end - start, "100-continue", 12))
            return -1;

        ++members;
        if (pos == len)
            break;
        ++pos;
    }

    return members ? 1 : -1;
}

static int
validate_request_semantics(
    int minor_version,
    const struct phr_header *headers,
    size_t num_headers,
    le_http_request_semantics *semantics,
    const char **detail
)
{
    size_t i;
    int host_count = 0;
    int transfer_encoding_present = 0;
    int coding_count = 0;
    int chunked_count = 0;
    int final_is_chunked = 0;
    int unsupported_transfer = 0;
    int saw_close = 0;
    int saw_keep_alive = 0;

    Zero(semantics, 1, le_http_request_semantics);
    semantics->body_mode = LE_HTTP_BODY_NONE;

    for (i = 0; i < num_headers; ++i) {
        const char *name = headers[i].name;
        size_t name_len = headers[i].name_len;
        const char *value = headers[i].value;
        size_t value_len = headers[i].value_len;

        if (ascii_equal_ci(name, name_len, "Host", 4)) {
            ++host_count;
            if (!valid_host_value(value, value_len)) {
                *detail = "invalid Host field";
                return LE_HTTP_SEMANTICS_BAD_REQUEST;
            }
        } else if (ascii_equal_ci(name, name_len, "Content-Length", 14)) {
            if (!parse_content_length_field(
                    value,
                    value_len,
                    &semantics->content_length,
                    &semantics->has_content_length
                )) {
                *detail = "invalid or conflicting Content-Length";
                return LE_HTTP_SEMANTICS_BAD_REQUEST;
            }
        } else if (ascii_equal_ci(name, name_len, "Transfer-Encoding", 17)) {
            transfer_encoding_present = 1;
            if (!parse_transfer_encoding_field(
                    value,
                    value_len,
                    &coding_count,
                    &chunked_count,
                    &final_is_chunked,
                    &unsupported_transfer
                )) {
                *detail = "invalid Transfer-Encoding";
                return LE_HTTP_SEMANTICS_BAD_REQUEST;
            }
        } else if (ascii_equal_ci(name, name_len, "Connection", 10)) {
            parse_connection_options(
                value,
                value_len,
                &saw_close,
                &saw_keep_alive
            );
        } else if (ascii_equal_ci(name, name_len, "Expect", 6)) {
            int expect = parse_expect_field(value, value_len);
            if (minor_version != 1 || expect < 0)
                semantics->expect_mode = -1;
            else if (semantics->expect_mode >= 0)
                semantics->expect_mode = 1;
        }
    }

    if (host_count > 1) {
        *detail = "multiple Host fields";
        return LE_HTTP_SEMANTICS_BAD_REQUEST;
    }

    if (minor_version >= 1 && host_count != 1) {
        *detail = "HTTP/1.1 request requires exactly one Host field";
        return LE_HTTP_SEMANTICS_BAD_REQUEST;
    }

    if (transfer_encoding_present && semantics->has_content_length) {
        *detail = "Transfer-Encoding and Content-Length cannot be combined";
        return LE_HTTP_SEMANTICS_BAD_REQUEST;
    }

    if (transfer_encoding_present) {
        if (chunked_count != 1 || !final_is_chunked) {
            *detail = "chunked must be the final and only chunked transfer coding";
            return LE_HTTP_SEMANTICS_BAD_REQUEST;
        }

        if (unsupported_transfer) {
            *detail = "unsupported transfer coding";
            return LE_HTTP_SEMANTICS_NOT_IMPLEMENTED;
        }

        semantics->body_mode = LE_HTTP_BODY_CHUNKED;
    } else if (semantics->has_content_length) {
        semantics->body_mode = LE_HTTP_BODY_CONTENT_LENGTH;
    }

    if (saw_close)
        semantics->keep_alive = 0;
    else if (minor_version >= 1)
        semantics->keep_alive = 1;
    else if (minor_version == 0 && saw_keep_alive)
        semantics->keep_alive = 1;
    else
        semantics->keep_alive = 0;

    *detail = NULL;
    return LE_HTTP_SEMANTICS_OK;
}

static void
croak_semantic_error(int status, const char *detail)
{
    if (detail == NULL)
        detail = "invalid HTTP/1 request semantics";

    croak("HTTP/1 request semantic error (%d): %s", status, detail);
}

static le_http_request_state *
request_state_from_object(pTHX_ SV *self)
{
    SV *inner;
    le_http_request_state *state;

    if (!SvROK(self) || !sv_derived_from(self, "Linux::Event::HTTP::Request"))
        croak("not a Linux::Event::HTTP::Request object");

    inner = SvRV(self);
    state = INT2PTR(le_http_request_state *, SvIV(inner));
    if (state == NULL)
        croak("HTTP request state has already been released");

    return state;
}

static SV *
request_slice_sv(pTHX_ le_http_request_state *state, size_t offset, size_t length)
{
    size_t buffer_len = (size_t)state->consumed;

    if (offset > buffer_len || length > buffer_len - offset)
        croak("corrupt HTTP request slice");

    return newSVpvn(state->bytes + offset, length);
}

static SV *
new_request_object(
    pTHX_
    const char *buf,
    int consumed,
    int minor_version,
    const char *method,
    size_t method_len,
    const char *path,
    size_t path_len,
    const struct phr_header *headers,
    size_t num_headers,
    const le_http_request_semantics *semantics
)
{
    le_http_request_state *state;
    le_http_header_slice *slices;
    unsigned char *allocation;
    SV *object;
    size_t slice_bytes;
    size_t total_bytes;
    size_t max_size = (size_t)-1;
    size_t i;

    slice_bytes = num_headers * sizeof(le_http_header_slice);
    if ((size_t)consumed > max_size - sizeof(le_http_request_state) - slice_bytes)
        croak("HTTP request head is too large to retain");

    total_bytes = sizeof(le_http_request_state) + slice_bytes + (size_t)consumed;
    Newxz(allocation, total_bytes, unsigned char);

    state = (le_http_request_state *)allocation;
    slices = (le_http_header_slice *)(allocation + sizeof(le_http_request_state));

    state->consumed = consumed;
    state->minor_version = minor_version;
    state->body_mode = semantics->body_mode;
    state->keep_alive = semantics->keep_alive;
    state->has_content_length = semantics->has_content_length;
    state->expect_mode = semantics->expect_mode;
    state->content_length = semantics->content_length;
    state->method_offset = (size_t)(method - buf);
    state->method_length = method_len;
    state->target_offset = (size_t)(path - buf);
    state->target_length = path_len;
    state->num_headers = num_headers;
    state->headers = slices;
    state->bytes = (char *)(allocation + sizeof(le_http_request_state) + slice_bytes);

    Copy(buf, state->bytes, (size_t)consumed, char);

    for (i = 0; i < num_headers; ++i) {
        slices[i].name_offset = (size_t)(headers[i].name - buf);
        slices[i].name_length = headers[i].name_len;
        slices[i].value_offset = (size_t)(headers[i].value - buf);
        slices[i].value_length = headers[i].value_len;
    }

    object = newSV(0);
    sv_setref_pv(
        object,
        "Linux::Event::HTTP::Request",
        (void *)state
    );

    return object;
}

enum {
    LE_HTTP_RAW_INPUT_REQUEST = 0,
    LE_HTTP_RAW_INPUT_FALLBACK = 1,
    LE_HTTP_RAW_INPUT_CONTENT_LENGTH_DRAIN = 2,
    LE_HTTP_RAW_INPUT_CONTENT_LENGTH_BODY = 3,
    LE_HTTP_RAW_INPUT_CHUNKED_DRAIN = 4,
    LE_HTTP_RAW_INPUT_CHUNKED_BODY = 5
};

typedef struct {
    const les_consumer_host_api_v1_t *host;
    void *host_context;
    SV *stream;
    CV *request_cv;
    CV *fallback_cv;
    CV *content_length_body_cv;
    CV *content_length_complete_cv;
    CV *chunked_body_cv;
    CV *chunked_complete_cv;
    CV *chunked_error_cv;
    CV *protocol_400_cv;
    CV *protocol_431_cv;
    CV *protocol_501_cv;
    int input_mode;
    UV content_length_remaining;
    struct phr_chunked_decoder chunked_decoder;
} le_http_raw_consumer_context;

static CV *
le_http_raw_method_cv(
    pTHX_
    le_http_raw_consumer_context *context,
    CV **slot,
    const char *method_name
)
{
    GV *gv;
    CV *cv;

    if (*slot != NULL)
        return *slot;

    if (!SvROK(context->stream))
        croak("Linux::Event HTTP raw consumer stream is not an object");

    gv = gv_fetchmethod_autoload(
        SvSTASH(SvRV(context->stream)),
        method_name,
        0
    );
    if (gv == NULL || (cv = GvCV(gv)) == NULL)
        croak("Linux::Event HTTP raw consumer method %s is unavailable",
            method_name);

    *slot = (CV *)SvREFCNT_inc((SV *)cv);
    return *slot;
}

static int
le_http_raw_call_scalar_int(
    pTHX_
    le_http_raw_consumer_context *context,
    CV **slot,
    const char *method_name,
    SV *arg,
    int store_fallback
)
{
    const les_consumer_host_api_v1_t *host;
    void *host_context;
    CV *cv;
    int result = 0;
    int count;
    int jump_status;
    dJMPENV;
    dSP;

    host = context->host;
    host_context = context->host_context;
    if (!host
        || host->struct_size < LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE
        || !host->retain || !host->release)
        croak("Linux::Event raw consumer host lifetime extension is unavailable");

    cv = le_http_raw_method_cv(aTHX_ context, slot, method_name);

    if (!host->retain(aTHX_ host_context))
        croak("Linux::Event raw consumer host is no longer available");

    JMPENV_PUSH(jump_status);
    if (jump_status == 0) {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(context->stream);
        if (arg != NULL)
            XPUSHs(arg);
        PUTBACK;
        count = call_sv((SV *)cv, G_SCALAR);
        SPAGAIN;
        if (count > 0)
            result = POPi;
        PUTBACK;
        FREETMPS;
        LEAVE;
        JMPENV_POP;
    } else {
        JMPENV_POP;
        host->release(aTHX_ host_context);
        JMPENV_JUMP(jump_status);
    }

    if (store_fallback)
        context->input_mode = result
            ? LE_HTTP_RAW_INPUT_FALLBACK
            : LE_HTTP_RAW_INPUT_REQUEST;

    host->release(aTHX_ host_context);
    return result;
}

static int
le_http_raw_call_request(
    pTHX_
    le_http_raw_consumer_context *context,
    SV *request,
    UV content_length
)
{
    const les_consumer_host_api_v1_t *host;
    void *host_context;
    CV *cv;
    int result = 0;
    int count;
    int jump_status;
    dJMPENV;
    dSP;

    host = context->host;
    host_context = context->host_context;
    if (!host
        || host->struct_size < LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE
        || !host->retain || !host->release)
        croak("Linux::Event raw consumer host lifetime extension is unavailable");

    cv = le_http_raw_method_cv(
        aTHX_ context,
        &context->request_cv,
        "_http_native_request"
    );

    if (!host->retain(aTHX_ host_context))
        croak("Linux::Event raw consumer host is no longer available");

    JMPENV_PUSH(jump_status);
    if (jump_status == 0) {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(context->stream);
        XPUSHs(request);
        PUTBACK;
        count = call_sv((SV *)cv, G_SCALAR);
        SPAGAIN;
        if (count > 0)
            result = POPi;
        PUTBACK;
        FREETMPS;
        LEAVE;
        JMPENV_POP;
    } else {
        JMPENV_POP;
        host->release(aTHX_ host_context);
        JMPENV_JUMP(jump_status);
    }

    if (result < LE_HTTP_RAW_INPUT_REQUEST
        || result > LE_HTTP_RAW_INPUT_CHUNKED_BODY)
        croak("Linux::Event HTTP raw consumer returned invalid input mode");

    context->input_mode = result;
    context->content_length_remaining
        = (result == LE_HTTP_RAW_INPUT_CONTENT_LENGTH_DRAIN
            || result == LE_HTTP_RAW_INPUT_CONTENT_LENGTH_BODY)
        ? content_length : 0;

    if (result == LE_HTTP_RAW_INPUT_CHUNKED_DRAIN
        || result == LE_HTTP_RAW_INPUT_CHUNKED_BODY) {
        Zero(&context->chunked_decoder, 1, struct phr_chunked_decoder);
        context->chunked_decoder.consume_trailer = 1;
    }

    host->release(aTHX_ host_context);
    return result;
}

static int
le_http_raw_call_content_length_body(
    pTHX_
    le_http_raw_consumer_context *context,
    SV *bytes,
    int done
)
{
    const les_consumer_host_api_v1_t *host;
    void *host_context;
    CV *cv;
    int result = 0;
    int count;
    int jump_status;
    dJMPENV;
    dSP;

    host = context->host;
    host_context = context->host_context;
    if (!host
        || host->struct_size < LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE
        || !host->retain || !host->release)
        croak("Linux::Event raw consumer host lifetime extension is unavailable");

    cv = le_http_raw_method_cv(
        aTHX_ context,
        &context->content_length_body_cv,
        "_http_native_content_length_body"
    );

    if (!host->retain(aTHX_ host_context))
        croak("Linux::Event raw consumer host is no longer available");

    if (done)
        context->input_mode = LE_HTTP_RAW_INPUT_REQUEST;

    JMPENV_PUSH(jump_status);
    if (jump_status == 0) {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(context->stream);
        XPUSHs(bytes);
        mPUSHi(done ? 1 : 0);
        PUTBACK;
        count = call_sv((SV *)cv, G_SCALAR);
        SPAGAIN;
        if (count > 0)
            result = POPi;
        PUTBACK;
        FREETMPS;
        LEAVE;
        JMPENV_POP;
    } else {
        JMPENV_POP;
        host->release(aTHX_ host_context);
        JMPENV_JUMP(jump_status);
    }

    if (!result)
        context->input_mode = LE_HTTP_RAW_INPUT_REQUEST;

    host->release(aTHX_ host_context);
    return result;
}

static int
le_http_raw_call_chunked_body(
    pTHX_
    le_http_raw_consumer_context *context,
    SV *bytes,
    int done
)
{
    const les_consumer_host_api_v1_t *host;
    void *host_context;
    CV *cv;
    int result = 0;
    int count;
    int jump_status;
    dJMPENV;
    dSP;

    host = context->host;
    host_context = context->host_context;
    if (!host
        || host->struct_size < LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE
        || !host->retain || !host->release)
        croak("Linux::Event raw consumer host lifetime extension is unavailable");

    cv = le_http_raw_method_cv(
        aTHX_ context,
        &context->chunked_body_cv,
        "_http_native_chunked_body"
    );

    if (!host->retain(aTHX_ host_context))
        croak("Linux::Event raw consumer host is no longer available");

    if (done)
        context->input_mode = LE_HTTP_RAW_INPUT_REQUEST;

    JMPENV_PUSH(jump_status);
    if (jump_status == 0) {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(context->stream);
        XPUSHs(bytes);
        mPUSHi(done ? 1 : 0);
        PUTBACK;
        count = call_sv((SV *)cv, G_SCALAR);
        SPAGAIN;
        if (count > 0)
            result = POPi;
        PUTBACK;
        FREETMPS;
        LEAVE;
        JMPENV_POP;
    } else {
        JMPENV_POP;
        host->release(aTHX_ host_context);
        JMPENV_JUMP(jump_status);
    }

    if (!result)
        context->input_mode = LE_HTTP_RAW_INPUT_REQUEST;

    host->release(aTHX_ host_context);
    return result;
}

static void *
le_http_raw_consumer_create(
    pTHX_
    const les_consumer_host_api_v1_t *host,
    void *host_context,
    SV *stream
)
{
    le_http_raw_consumer_context *context;

    if (!host
        || host->abi_version != LES_CONSUMER_ABI_VERSION
        || host->struct_size < LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE
        || !host->retain || !host->release)
        return NULL;

    Newxz(context, 1, le_http_raw_consumer_context);
    if (context == NULL)
        return NULL;

    context->host = host;
    context->host_context = host_context;
    context->stream = SvREFCNT_inc(stream);
    context->input_mode = LE_HTTP_RAW_INPUT_REQUEST;
    context->content_length_remaining = 0;
    return context;
}

static int
le_http_raw_consumer_input(
    pTHX_
    void *opaque,
    const char *buf,
    size_t buffer_len,
    size_t *host_consumed
)
{
    le_http_raw_consumer_context *context
        = (le_http_raw_consumer_context *)opaque;
    const char *method;
    size_t method_len;
    const char *path;
    size_t path_len;
    int minor_version;
    struct phr_header headers[LE_HTTP1_MAX_HEADERS];
    size_t num_headers = 100;
    int consumed;
    le_http_request_semantics semantics;
    const char *detail;
    int semantic_status;
    SV *request;

    *host_consumed = 0;

    if (context->input_mode == LE_HTTP_RAW_INPUT_CONTENT_LENGTH_DRAIN
        || context->input_mode == LE_HTTP_RAW_INPUT_CONTENT_LENGTH_BODY) {
        UV remaining = context->content_length_remaining;
        size_t take = buffer_len;
        int done;

        if (remaining == 0)
            croak("Linux::Event HTTP raw Content-Length mode has no body remaining");
        if (remaining < (UV)take)
            take = (size_t)remaining;

        done = (UV)take == remaining ? 1 : 0;
        *host_consumed = take;
        context->content_length_remaining -= (UV)take;

        if (context->input_mode == LE_HTTP_RAW_INPUT_CONTENT_LENGTH_BODY) {
            SV *bytes = sv_2mortal(newSVpvn(buf, (STRLEN)take));
            (void)le_http_raw_call_content_length_body(
                aTHX_ context,
                bytes,
                done
            );
            return LES_CONSUMER_CONTINUE;
        }

        if (done) {
            context->input_mode = LE_HTTP_RAW_INPUT_REQUEST;
            (void)le_http_raw_call_scalar_int(
                aTHX_ context,
                &context->content_length_complete_cv,
                "_http_native_content_length_complete",
                NULL,
                0
            );
        }
        return LES_CONSUMER_CONTINUE;
    }

    if (context->input_mode == LE_HTTP_RAW_INPUT_CHUNKED_DRAIN
        || context->input_mode == LE_HTTP_RAW_INPUT_CHUNKED_BODY) {
        char *scratch;
        size_t decoded_len = buffer_len;
        ssize_t result;
        size_t leftover = 0;
        int emit = context->input_mode == LE_HTTP_RAW_INPUT_CHUNKED_BODY;
        int done;

        Newx(scratch, buffer_len ? buffer_len : 1, char);
        if (buffer_len)
            Copy(buf, scratch, buffer_len, char);

        result = phr_decode_chunked(
            &context->chunked_decoder,
            scratch,
            &decoded_len
        );

        if (result == -1) {
            Safefree(scratch);
            *host_consumed = buffer_len;
            context->input_mode = LE_HTTP_RAW_INPUT_REQUEST;
            (void)le_http_raw_call_scalar_int(
                aTHX_ context,
                &context->chunked_error_cv,
                "_http_native_chunked_error",
                NULL,
                0
            );
            return LES_CONSUMER_CONTINUE;
        }

        done = result >= 0 ? 1 : 0;
        if (done) {
            leftover = (size_t)result;
            if (leftover > buffer_len)
                croak("Linux::Event HTTP raw chunked decoder returned invalid leftover");
            *host_consumed = buffer_len - leftover;
            context->input_mode = LE_HTTP_RAW_INPUT_REQUEST;
        } else {
            *host_consumed = buffer_len;
        }

        if (emit) {
            SV *bytes = sv_2mortal(newSVpvn(scratch, (STRLEN)decoded_len));
            Safefree(scratch);
            (void)le_http_raw_call_chunked_body(
                aTHX_ context,
                bytes,
                done
            );
            return LES_CONSUMER_CONTINUE;
        }

        Safefree(scratch);
        if (done) {
            (void)le_http_raw_call_scalar_int(
                aTHX_ context,
                &context->chunked_complete_cv,
                "_http_native_chunked_complete",
                NULL,
                0
            );
        }
        return LES_CONSUMER_CONTINUE;
    }

    if (context->input_mode == LE_HTTP_RAW_INPUT_FALLBACK) {
        SV *bytes = sv_2mortal(newSVpvn(buf, (STRLEN)buffer_len));
        *host_consumed = buffer_len;
        (void)le_http_raw_call_scalar_int(
            aTHX_ context,
            &context->fallback_cv,
            "_http_native_fallback_input",
            bytes,
            1
        );
        return LES_CONSUMER_CONTINUE;
    }

    consumed = parse_request_strict(
        buf,
        buffer_len,
        &method,
        &method_len,
        &path,
        &path_len,
        &minor_version,
        headers,
        &num_headers,
        0
    );

    if (consumed == -2) {
        if (buffer_len > 65536) {
            *host_consumed = buffer_len;
            (void)le_http_raw_call_scalar_int(
                aTHX_ context,
                &context->protocol_431_cv,
                "_http_native_protocol_431",
                NULL,
                0
            );
        }
        return LES_CONSUMER_CONTINUE;
    }

    if (consumed == -1) {
        *host_consumed = buffer_len;
        (void)le_http_raw_call_scalar_int(
            aTHX_ context,
            &context->protocol_400_cv,
            "_http_native_protocol_400",
            NULL,
            0
        );
        return LES_CONSUMER_CONTINUE;
    }

    semantic_status = validate_request_semantics(
        minor_version,
        headers,
        num_headers,
        &semantics,
        &detail
    );
    if (semantic_status != LE_HTTP_SEMANTICS_OK) {
        *host_consumed = (size_t)consumed;
        if (semantic_status == LE_HTTP_SEMANTICS_NOT_IMPLEMENTED)
            (void)le_http_raw_call_scalar_int(
                aTHX_ context,
                &context->protocol_501_cv,
                "_http_native_protocol_501",
                NULL,
                0
            );
        else
            (void)le_http_raw_call_scalar_int(
                aTHX_ context,
                &context->protocol_400_cv,
                "_http_native_protocol_400",
                NULL,
                0
            );
        return LES_CONSUMER_CONTINUE;
    }

    request = new_request_object(
        aTHX_
        buf,
        consumed,
        minor_version,
        method,
        method_len,
        path,
        path_len,
        headers,
        num_headers,
        &semantics
    );

    *host_consumed = (size_t)consumed;
    (void)le_http_raw_call_request(
        aTHX_ context,
        sv_2mortal(request),
        semantics.content_length
    );
    return LES_CONSUMER_CONTINUE;
}

static void
le_http_raw_consumer_event(
    pTHX_
    void *opaque,
    uint32_t event,
    int error,
    const char *message
)
{
    PERL_UNUSED_ARG(opaque);
    PERL_UNUSED_ARG(event);
    PERL_UNUSED_ARG(error);
    PERL_UNUSED_ARG(message);
    PERL_UNUSED_CONTEXT;
}

static void
le_http_raw_consumer_destroy(pTHX_ void *opaque)
{
    le_http_raw_consumer_context *context
        = (le_http_raw_consumer_context *)opaque;

    PERL_UNUSED_CONTEXT;

    if (context == NULL)
        return;

    if (context->request_cv != NULL)
        SvREFCNT_dec((SV *)context->request_cv);
    if (context->fallback_cv != NULL)
        SvREFCNT_dec((SV *)context->fallback_cv);
    if (context->content_length_body_cv != NULL)
        SvREFCNT_dec((SV *)context->content_length_body_cv);
    if (context->content_length_complete_cv != NULL)
        SvREFCNT_dec((SV *)context->content_length_complete_cv);
    if (context->chunked_body_cv != NULL)
        SvREFCNT_dec((SV *)context->chunked_body_cv);
    if (context->chunked_complete_cv != NULL)
        SvREFCNT_dec((SV *)context->chunked_complete_cv);
    if (context->chunked_error_cv != NULL)
        SvREFCNT_dec((SV *)context->chunked_error_cv);
    if (context->protocol_400_cv != NULL)
        SvREFCNT_dec((SV *)context->protocol_400_cv);
    if (context->protocol_431_cv != NULL)
        SvREFCNT_dec((SV *)context->protocol_431_cv);
    if (context->protocol_501_cv != NULL)
        SvREFCNT_dec((SV *)context->protocol_501_cv);
    if (context->stream != NULL)
        SvREFCNT_dec(context->stream);
    Safefree(context);
}

static const les_consumer_ops_v1_t le_http_raw_consumer_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "Linux::Event::HTTP::_HTTP1 raw input",
    LES_CONSUMER_F_RAW_INPUT,
    le_http_raw_consumer_create,
    NULL,
    le_http_raw_consumer_event,
    le_http_raw_consumer_destroy,
    NULL,
    le_http_raw_consumer_input
};

static const char *
default_reason_phrase(int status)
{
    switch (status) {
        case 100: return "Continue";
        case 101: return "Switching Protocols";
        case 103: return "Early Hints";
        case 200: return "OK";
        case 201: return "Created";
        case 202: return "Accepted";
        case 204: return "No Content";
        case 206: return "Partial Content";
        case 300: return "Multiple Choices";
        case 301: return "Moved Permanently";
        case 302: return "Found";
        case 303: return "See Other";
        case 304: return "Not Modified";
        case 307: return "Temporary Redirect";
        case 308: return "Permanent Redirect";
        case 400: return "Bad Request";
        case 401: return "Unauthorized";
        case 403: return "Forbidden";
        case 404: return "Not Found";
        case 405: return "Method Not Allowed";
        case 408: return "Request Timeout";
        case 409: return "Conflict";
        case 410: return "Gone";
        case 411: return "Length Required";
        case 413: return "Content Too Large";
        case 414: return "URI Too Long";
        case 415: return "Unsupported Media Type";
        case 417: return "Expectation Failed";
        case 421: return "Misdirected Request";
        case 422: return "Unprocessable Content";
        case 426: return "Upgrade Required";
        case 428: return "Precondition Required";
        case 429: return "Too Many Requests";
        case 431: return "Request Header Fields Too Large";
        case 451: return "Unavailable For Legal Reasons";
        case 500: return "Internal Server Error";
        case 501: return "Not Implemented";
        case 502: return "Bad Gateway";
        case 503: return "Service Unavailable";
        case 504: return "Gateway Timeout";
        case 505: return "HTTP Version Not Supported";
        default: return "";
    }
}

static int
valid_output_content_length(const char *value, size_t len)
{
    size_t i;

    if (len == 0)
        return 0;

    for (i = 0; i < len; ++i) {
        if (value[i] < '0' || value[i] > '9')
            return 0;
    }

    return 1;
}

static struct phr_chunked_decoder *
decoder_from_object(pTHX_ SV *self)
{
    SV *inner;
    struct phr_chunked_decoder *decoder;

    if (!SvROK(self) ||
        !sv_derived_from(
            self,
            "Linux::Event::HTTP::_HTTP1::Chunked"
        ))
        croak("not an HTTP/1 chunked decoder object");

    inner = SvRV(self);
    decoder = INT2PTR(struct phr_chunked_decoder *, SvIV(inner));
    if (decoder == NULL)
        croak("HTTP/1 chunked decoder state has already been released");

    return decoder;
}

static int
request_method_is_head(le_http_request_state *state)
{
    return state->method_length == 4 &&
        memEQ(state->bytes + state->method_offset, "HEAD", 4);
}

static HV *
response_hv_from_object(pTHX_ SV *self)
{
    if (!SvROK(self) ||
        !sv_derived_from(self, "Linux::Event::HTTP::Response") ||
        SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("not a Linux::Event::HTTP::Response object");

    return (HV *)SvRV(self);
}

static int
response_hv_true(pTHX_ HV *hv, const char *key, I32 key_len)
{
    SV **value = hv_fetch(hv, key, key_len, 0);
    return value != NULL && SvTRUE(*value);
}

static UV
response_server_flags(pTHX_ HV *hv)
{
    SV **value = hv_fetch(
        hv,
        "_server_flags",
        (I32)(sizeof("_server_flags") - 1),
        0
    );
    return value != NULL && SvOK(*value) ? SvUV(*value) : 0;
}

static void
response_clear_server_flags(pTHX_ HV *hv, UV mask)
{
    SV **value = hv_fetch(
        hv,
        "_server_flags",
        (I32)(sizeof("_server_flags") - 1),
        0
    );
    UV flags;

    if (value == NULL || !SvOK(*value))
        return;

    flags = SvUV(*value);
    flags &= ~mask;
    sv_setuv(*value, flags);
}

static const char *
response_input_bytes(
    pTHX_
    SV *input,
    const char *label,
    SV **temporary,
    STRLEN *length
)
{
    if (!SvOK(input) || SvROK(input))
        croak("%s must be a defined scalar byte string", label);

    *temporary = NULL;

    if (SvPOK(input) && !SvUTF8(input) && !SvGMAGICAL(input))
        return SvPVbyte(input, *length);

    *temporary = sv_2mortal(newSVsv(input));
    if (SvUTF8(*temporary) &&
        !sv_utf8_downgrade(*temporary, TRUE))
        croak("%s contains wide characters; encode it to bytes first", label);

    return SvPVbyte(*temporary, *length);
}

static SV *
response_header_pair_sv(
    pTHX_
    const char *name,
    STRLEN name_len,
    const char *value,
    STRLEN value_len
)
{
    AV *pair = newAV();
    av_extend(pair, 1);
    av_push(pair, newSVpvn(name, name_len));
    av_push(pair, newSVpvn(value, value_len));
    return newRV_noinc((SV *)pair);
}

static int
response_header_row_matches(
    pTHX_
    SV *row_ref,
    const char *wanted,
    STRLEN wanted_len
)
{
    AV *row;
    SV **name_ptr;
    STRLEN name_len;
    const char *name;

    if (!SvROK(row_ref) || SvTYPE(SvRV(row_ref)) != SVt_PVAV)
        croak("response header entry is invalid");

    row = (AV *)SvRV(row_ref);
    name_ptr = av_fetch(row, 0, 0);
    if (name_ptr == NULL || !SvOK(*name_ptr) || SvROK(*name_ptr))
        croak("response header entry requires a scalar name");

    name = SvPVbyte(*name_ptr, name_len);
    return ascii_equal_ci(
        name,
        (size_t)name_len,
        wanted,
        (size_t)wanted_len
    );
}

static void
response_set_header_native(
    pTHX_
    SV *self,
    SV *name_sv,
    SV *value_sv
)
{
    HV *hv = response_hv_from_object(aTHX_ self);
    SV *name_tmp;
    SV *value_tmp;
    STRLEN name_len;
    STRLEN value_len;
    const char *name;
    const char *value;
    SV **headers_ptr;
    AV *headers;
    SSize_t max_index;
    SSize_t first = -1;
    UV matches = 0;
    SSize_t i;
    int framing_header = 0;

    if (response_hv_true(aTHX_ hv, "committed", 9))
        croak("response metadata cannot change after message commit");

    name = response_input_bytes(
        aTHX_ name_sv, "response header field name",
        &name_tmp, &name_len
    );
    if (!valid_field_name(name, (size_t)name_len))
        croak("invalid response header field name");

    framing_header =
        ascii_equal_ci(name, (size_t)name_len, "Content-Length", 14) ||
        ascii_equal_ci(name, (size_t)name_len, "Transfer-Encoding", 17) ||
        ascii_equal_ci(name, (size_t)name_len, "Connection", 10);

    value = response_input_bytes(
        aTHX_ value_sv, "response header field value",
        &value_tmp, &value_len
    );
    if (!valid_output_field_value(value, (size_t)value_len))
        croak("response header field value contains invalid control characters");

    headers_ptr = hv_fetch(hv, "headers", 7, 0);
    if (headers_ptr == NULL) {
        headers = NULL;
        max_index = -1;
    } else {
        if (!SvROK(*headers_ptr) ||
            SvTYPE(SvRV(*headers_ptr)) != SVt_PVAV)
            croak("response headers storage is invalid");
        headers = (AV *)SvRV(*headers_ptr);
        max_index = av_len(headers);
    }

    /*
     * Fresh server Responses share one immutable empty array. Never append to
     * it in place: replace the hash slot with a private one-element array.
     */
    if (max_index < 0) {
        AV *new_headers = newAV();
        av_push(
            new_headers,
            response_header_pair_sv(aTHX_ name, name_len, value, value_len)
        );
        hv_store(
            hv, "headers", 7,
            newRV_noinc((SV *)new_headers), 0
        );
        response_clear_server_flags(
            aTHX_
            hv,
            framing_header
                ? LE_HTTP_RESPONSE_SERVER_DEFAULT_FINAL
                    | LE_HTTP_RESPONSE_SERVER_SCALAR_SIMPLE
                : LE_HTTP_RESPONSE_SERVER_DEFAULT_FINAL
        );
        return;
    }

    for (i = 0; i <= max_index; ++i) {
        SV **row_ptr = av_fetch(headers, i, 0);
        if (row_ptr == NULL)
            croak("response header entry is missing");

        if (response_header_row_matches(
                aTHX_ *row_ptr, name, name_len
            )) {
            if (matches == 0)
                first = i;
            ++matches;
        }
    }

    if (matches == 0) {
        av_push(
            headers,
            response_header_pair_sv(aTHX_ name, name_len, value, value_len)
        );
    } else if (matches == 1) {
        av_store(
            headers,
            first,
            response_header_pair_sv(aTHX_ name, name_len, value, value_len)
        );
    } else {
        AV *new_headers = newAV();
        int inserted = 0;

        av_extend(new_headers, max_index - (SSize_t)matches + 1);

        for (i = 0; i <= max_index; ++i) {
            SV **row_ptr = av_fetch(headers, i, 0);
            int is_match;

            if (row_ptr == NULL)
                croak("response header entry is missing");

            is_match = response_header_row_matches(
                aTHX_ *row_ptr, name, name_len
            );

            if (is_match) {
                if (!inserted) {
                    av_push(
                        new_headers,
                        response_header_pair_sv(
                            aTHX_
                            name, name_len, value, value_len
                        )
                    );
                    inserted = 1;
                }
                continue;
            }

            av_push(new_headers, SvREFCNT_inc(*row_ptr));
        }

        hv_store(
            hv, "headers", 7,
            newRV_noinc((SV *)new_headers), 0
        );
    }

    response_clear_server_flags(
        aTHX_
        hv,
        framing_header
            ? LE_HTTP_RESPONSE_SERVER_DEFAULT_FINAL
                | LE_HTTP_RESPONSE_SERVER_SCALAR_SIMPLE
            : LE_HTTP_RESPONSE_SERVER_DEFAULT_FINAL
    );
}

static void
response_set_body_native(pTHX_ SV *self, SV *body_sv)
{
    HV *hv = response_hv_from_object(aTHX_ self);
    SV **kind_ptr;
    SV *body_tmp;
    STRLEN body_len;
    const char *body;

    if (response_hv_true(aTHX_ hv, "committed", 9))
        croak("response metadata cannot change after message commit");

    kind_ptr = hv_fetch(hv, "body_kind", 9, 0);
    if (kind_ptr != NULL && SvOK(*kind_ptr) &&
        strEQ(SvPV_nolen(*kind_ptr), "stream"))
        croak("body(): response already has an incremental body producer");

    body = response_input_bytes(
        aTHX_ body_sv, "body(): body",
        &body_tmp, &body_len
    );

    hv_store(hv, "body", 4, newSVpvn(body, body_len), 0);
    hv_store(hv, "body_kind", 9, newSVpvs("scalar"), 0);
    hv_store(hv, "complete", 8, newSViv(1), 0);
}

static SV *
response_build_simple_scalar_final(
    pTHX_
    SV *request,
    SV *response,
    SV *body_sv
)
{
    le_http_request_state *request_state;
    HV *hv;
    SV **status_ptr;
    SV **reason_ptr;
    SV **headers_ptr;
    AV *headers;
    SSize_t max_index;
    SSize_t i;
    IV status;
    const char *reason;
    STRLEN reason_len;
    SV *body_tmp;
    STRLEN body_len;
    const char *body;
    int head_request;
    int body_forbidden;
    SV *wire;

    request_state = request_state_from_object(aTHX_ request);
    hv = response_hv_from_object(aTHX_ response);

    if (!(response_server_flags(aTHX_ hv)
            & LE_HTTP_RESPONSE_SERVER_SCALAR_SIMPLE))
        return NULL;

    if (request_state->minor_version != 1 || !request_state->keep_alive)
        return NULL;

    status_ptr = hv_fetch(hv, "status", 6, 0);
    if (status_ptr == NULL)
        status = 200;
    else if (!SvOK(*status_ptr))
        return NULL;
    else
        status = SvIV(*status_ptr);
    if (status < 100 || status > 999)
        return NULL;

    if (status >= 100 && status < 200)
        croak("send_response(): informational responses require a future interim-response API");

    body = response_input_bytes(
        aTHX_ body_sv, "send_response(): body",
        &body_tmp, &body_len
    );

    head_request = request_method_is_head(request_state);
    body_forbidden = status == 204 || status == 304;
    if (body_forbidden && body_len != 0)
        croak("send_response(): this response status cannot carry a message body");

    reason_ptr = hv_fetch(hv, "reason", 6, 0);
    if (reason_ptr != NULL && SvOK(*reason_ptr)) {
        reason = SvPVbyte(*reason_ptr, reason_len);
        if (!valid_reason_phrase(reason, (size_t)reason_len))
            return NULL;
    } else {
        reason = default_reason_phrase((int)status);
        reason_len = (STRLEN)strlen(reason);
    }

    headers_ptr = hv_fetch(hv, "headers", 7, 0);
    if (headers_ptr == NULL) {
        headers = NULL;
        max_index = -1;
    } else {
        if (!SvROK(*headers_ptr) ||
            SvTYPE(SvRV(*headers_ptr)) != SVt_PVAV)
            return NULL;
        headers = (AV *)SvRV(*headers_ptr);
        max_index = av_len(headers);
    }

    /*
     * The marker is maintained by the public server Response mutation path,
     * but validate the actual header storage anyway. Direct hash tampering
     * must fall back to the general response state machine rather than turn
     * the fast path into a second, weaker protocol implementation.
     */
    for (i = 0; i <= max_index; ++i) {
        SV **row_ptr = av_fetch(headers, i, 0);
        AV *row;
        SV **name_ptr;
        SV **value_ptr;
        const char *name;
        const char *value;
        STRLEN name_len;
        STRLEN value_len;

        if (row_ptr == NULL ||
            !SvROK(*row_ptr) ||
            SvTYPE(SvRV(*row_ptr)) != SVt_PVAV)
            return NULL;

        row = (AV *)SvRV(*row_ptr);
        if (av_len(row) != 1)
            return NULL;

        name_ptr = av_fetch(row, 0, 0);
        value_ptr = av_fetch(row, 1, 0);
        if (name_ptr == NULL || value_ptr == NULL ||
            !SvOK(*name_ptr) || !SvOK(*value_ptr) ||
            SvROK(*name_ptr) || SvROK(*value_ptr))
            return NULL;

        name = SvPVbyte(*name_ptr, name_len);
        value = SvPVbyte(*value_ptr, value_len);
        if (!valid_field_name(name, (size_t)name_len) ||
            !valid_output_field_value(value, (size_t)value_len))
            return NULL;

        if (ascii_equal_ci(name, (size_t)name_len, "Content-Length", 14) ||
            ascii_equal_ci(name, (size_t)name_len, "Transfer-Encoding", 17) ||
            ascii_equal_ci(name, (size_t)name_len, "Connection", 10))
            return NULL;
    }

    wire = newSVpvf(
        "HTTP/1.1 %03" IVdf " ",
        status
    );
    sv_catpvn(wire, reason, reason_len);
    sv_catpvn(wire, "\r\n", 2);

    for (i = 0; i <= max_index; ++i) {
        SV **row_ptr = av_fetch(headers, i, 0);
        AV *row = (AV *)SvRV(*row_ptr);
        SV **name_ptr = av_fetch(row, 0, 0);
        SV **value_ptr = av_fetch(row, 1, 0);
        STRLEN name_len;
        STRLEN value_len;
        const char *name = SvPVbyte(*name_ptr, name_len);
        const char *value = SvPVbyte(*value_ptr, value_len);

        sv_catpvn(wire, name, name_len);
        sv_catpvn(wire, ": ", 2);
        sv_catpvn(wire, value, value_len);
        sv_catpvn(wire, "\r\n", 2);
    }

    if (!body_forbidden) {
        AV *pair = newAV();
        SV *length_sv = newSVpvf("%" UVuf, (UV)body_len);

        av_extend(pair, 1);
        av_push(pair, newSVpvs("Content-Length"));
        av_push(pair, SvREFCNT_inc(length_sv));

        if (max_index < 0) {
            AV *new_headers = newAV();
            av_push(new_headers, newRV_noinc((SV *)pair));
            hv_store(
                hv, "headers", 7,
                newRV_noinc((SV *)new_headers), 0
            );
        } else {
            av_push(headers, newRV_noinc((SV *)pair));
        }

        sv_catpvs(wire, "Content-Length: ");
        sv_catsv(wire, length_sv);
        sv_catpvn(wire, "\r\n", 2);
        SvREFCNT_dec(length_sv);
    }

    sv_catpvn(wire, "\r\n", 2);
    if (!head_request && !body_forbidden)
        sv_catpvn(wire, body, body_len);

    hv_store(hv, "committed", 9, newSViv(1), 0);
    return wire;
}


MODULE = Linux::Event::HTTP::_HTTP1    PACKAGE = Linux::Event::HTTP::_HTTP1
PROTOTYPES: DISABLE

UV
_raw_consumer_operations_address()
  CODE:
    RETVAL = PTR2UV(&le_http_raw_consumer_ops);
  OUTPUT:
    RETVAL

const char *
pico_version(CLASS)
    const char *CLASS
  CODE:
    (void)CLASS;
    RETVAL = PICOHTTPPARSER_VERSION;
  OUTPUT:
    RETVAL

int
probe_request(CLASS, buffer, last_len = 0, max_headers = 100)
    const char *CLASS
    SV *buffer
    UV last_len
    UV max_headers
  PREINIT:
    STRLEN buffer_len;
    const char *buf;
    const char *method;
    size_t method_len;
    const char *path;
    size_t path_len;
    int minor_version;
    struct phr_header headers[LE_HTTP1_MAX_HEADERS];
    size_t num_headers;
  CODE:
    (void)CLASS;
    buf = SvPVbyte(buffer, buffer_len);
    validate_limits(buffer_len, last_len, max_headers);
    num_headers = (size_t)max_headers;
    RETVAL = parse_request_strict(
        buf,
        (size_t)buffer_len,
        &method,
        &method_len,
        &path,
        &path_len,
        &minor_version,
        headers,
        &num_headers,
        (size_t)last_len
    );
  OUTPUT:
    RETVAL

SV *
parse_request(CLASS, buffer, last_len = 0, max_headers = 100)
    const char *CLASS
    SV *buffer
    UV last_len
    UV max_headers
  PREINIT:
    STRLEN buffer_len;
    const char *buf;
    const char *method;
    size_t method_len;
    const char *path;
    size_t path_len;
    int minor_version;
    struct phr_header headers[LE_HTTP1_MAX_HEADERS];
    size_t num_headers;
    int consumed;
    le_http_request_semantics semantics;
    const char *detail;
    int semantic_status;
  CODE:
    (void)CLASS;
    buf = SvPVbyte(buffer, buffer_len);
    validate_limits(buffer_len, last_len, max_headers);
    num_headers = (size_t)max_headers;
    consumed = parse_request_strict(
        buf,
        (size_t)buffer_len,
        &method,
        &method_len,
        &path,
        &path_len,
        &minor_version,
        headers,
        &num_headers,
        (size_t)last_len
    );

    if (consumed == -2)
        XSRETURN_UNDEF;
    if (consumed == -1)
        croak("malformed HTTP/1 request");

    semantic_status = validate_request_semantics(
        minor_version,
        headers,
        num_headers,
        &semantics,
        &detail
    );
    if (semantic_status != LE_HTTP_SEMANTICS_OK)
        croak_semantic_error(semantic_status, detail);

    RETVAL = new_request_object(
        aTHX_
        buf,
        consumed,
        minor_version,
        method,
        method_len,
        path,
        path_len,
        headers,
        num_headers,
        &semantics
    );
  OUTPUT:
    RETVAL

SV *
build_simple_scalar_final(CLASS, request, response, body)
    const char *CLASS
    SV *request
    SV *response
    SV *body
  PREINIT:
    SV *wire;
  CODE:
    (void)CLASS;
    wire = response_build_simple_scalar_final(
        aTHX_ request, response, body
    );
    if (wire == NULL)
        XSRETURN_UNDEF;
    RETVAL = wire;
  OUTPUT:
    RETVAL

SV *
_parse_server_request(CLASS, buffer, max_head = 65536, max_headers = 100)
    const char *CLASS
    SV *buffer
    UV max_head
    UV max_headers
  PREINIT:
    STRLEN buffer_len;
    const char *buf;
    const char *method;
    size_t method_len;
    const char *path;
    size_t path_len;
    int minor_version;
    struct phr_header headers[LE_HTTP1_MAX_HEADERS];
    size_t num_headers;
    int consumed;
    le_http_request_semantics semantics;
    const char *detail;
    int semantic_status;
  CODE:
    (void)CLASS;
    buf = SvPVbyte(buffer, buffer_len);
    validate_limits(buffer_len, 0, max_headers);
    num_headers = (size_t)max_headers;
    consumed = parse_request_strict(
        buf,
        (size_t)buffer_len,
        &method,
        &method_len,
        &path,
        &path_len,
        &minor_version,
        headers,
        &num_headers,
        0
    );

    if (consumed == -2) {
        if ((UV)buffer_len > max_head)
            RETVAL = newSViv(431);
        else
            XSRETURN_UNDEF;
    } else if (consumed == -1) {
        RETVAL = newSViv(400);
    } else {
        semantic_status = validate_request_semantics(
            minor_version,
            headers,
            num_headers,
            &semantics,
            &detail
        );
        if (semantic_status != LE_HTTP_SEMANTICS_OK) {
            RETVAL = newSViv(semantic_status);
        } else {
            RETVAL = new_request_object(
                aTHX_
                buf,
                consumed,
                minor_version,
                method,
                method_len,
                path,
                path_len,
                headers,
                num_headers,
                &semantics
            );
        }
    }
  OUTPUT:
    RETVAL

SV *
parse_request_offsets(CLASS, buffer, last_len = 0, max_headers = 100)
    const char *CLASS
    SV *buffer
    UV last_len
    UV max_headers
  PREINIT:
    STRLEN buffer_len;
    const char *buf;
    const char *method;
    size_t method_len;
    const char *path;
    size_t path_len;
    int minor_version;
    struct phr_header headers[LE_HTTP1_MAX_HEADERS];
    size_t num_headers;
    int consumed;
    size_t i;
    AV *result;
    AV *header_list;
    AV *row;
    le_http_request_semantics semantics;
    const char *detail;
    int semantic_status;
  CODE:
    (void)CLASS;
    buf = SvPVbyte(buffer, buffer_len);
    validate_limits(buffer_len, last_len, max_headers);
    num_headers = (size_t)max_headers;
    consumed = parse_request_strict(
        buf,
        (size_t)buffer_len,
        &method,
        &method_len,
        &path,
        &path_len,
        &minor_version,
        headers,
        &num_headers,
        (size_t)last_len
    );

    if (consumed == -2)
        XSRETURN_UNDEF;
    if (consumed == -1)
        croak("malformed HTTP/1 request");

    semantic_status = validate_request_semantics(
        minor_version,
        headers,
        num_headers,
        &semantics,
        &detail
    );
    if (semantic_status != LE_HTTP_SEMANTICS_OK)
        croak_semantic_error(semantic_status, detail);

    result = newAV();
    av_push(result, newSViv(consumed));
    av_push(result, newSViv(minor_version));
    av_push(result, newSVuv((UV)(method - buf)));
    av_push(result, newSVuv((UV)method_len));
    av_push(result, newSVuv((UV)(path - buf)));
    av_push(result, newSVuv((UV)path_len));

    header_list = newAV();
    for (i = 0; i < num_headers; ++i) {
        row = newAV();
        av_push(row, newSVuv((UV)(headers[i].name - buf)));
        av_push(row, newSVuv((UV)headers[i].name_len));
        av_push(row, newSVuv((UV)(headers[i].value - buf)));
        av_push(row, newSVuv((UV)headers[i].value_len));
        av_push(header_list, newRV_noinc((SV *)row));
    }
    av_push(result, newRV_noinc((SV *)header_list));

    RETVAL = newRV_noinc((SV *)result);
  OUTPUT:
    RETVAL

MODULE = Linux::Event::HTTP::_HTTP1    PACKAGE = Linux::Event::HTTP::Request

SV *
method(self)
    SV *self
  PREINIT:
    le_http_request_state *state;
  CODE:
    state = request_state_from_object(aTHX_ self);
    RETVAL = request_slice_sv(aTHX_ state, state->method_offset, state->method_length);
  OUTPUT:
    RETVAL

SV *
target(self)
    SV *self
  PREINIT:
    le_http_request_state *state;
  CODE:
    state = request_state_from_object(aTHX_ self);
    RETVAL = request_slice_sv(aTHX_ state, state->target_offset, state->target_length);
  OUTPUT:
    RETVAL

SV *
http_version(self)
    SV *self
  PREINIT:
    le_http_request_state *state;
  CODE:
    state = request_state_from_object(aTHX_ self);
    RETVAL = newSVpvf("1.%d", state->minor_version);
  OUTPUT:
    RETVAL

const char *
body_mode(self)
    SV *self
  PREINIT:
    le_http_request_state *state;
  CODE:
    state = request_state_from_object(aTHX_ self);
    if (state->body_mode == LE_HTTP_BODY_CONTENT_LENGTH)
        RETVAL = "content-length";
    else if (state->body_mode == LE_HTTP_BODY_CHUNKED)
        RETVAL = "chunked";
    else
        RETVAL = "none";
  OUTPUT:
    RETVAL

SV *
content_length(self)
    SV *self
  PREINIT:
    le_http_request_state *state;
  CODE:
    state = request_state_from_object(aTHX_ self);
    if (!state->has_content_length)
        XSRETURN_UNDEF;
    RETVAL = newSVuv(state->content_length);
  OUTPUT:
    RETVAL

int
keep_alive(self)
    SV *self
  PREINIT:
    le_http_request_state *state;
  CODE:
    state = request_state_from_object(aTHX_ self);
    RETVAL = state->keep_alive ? 1 : 0;
  OUTPUT:
    RETVAL

UV
header_count(self)
    SV *self
  PREINIT:
    le_http_request_state *state;
  CODE:
    state = request_state_from_object(aTHX_ self);
    RETVAL = (UV)state->num_headers;
  OUTPUT:
    RETVAL

SV *
header_name(self, index)
    SV *self
    UV index
  PREINIT:
    le_http_request_state *state;
    le_http_header_slice *header;
  CODE:
    state = request_state_from_object(aTHX_ self);
    if (index >= (UV)state->num_headers)
        croak("header index out of range");
    header = &state->headers[index];
    RETVAL = request_slice_sv(aTHX_ state, header->name_offset, header->name_length);
  OUTPUT:
    RETVAL

SV *
header_value(self, index)
    SV *self
    UV index
  PREINIT:
    le_http_request_state *state;
    le_http_header_slice *header;
  CODE:
    state = request_state_from_object(aTHX_ self);
    if (index >= (UV)state->num_headers)
        croak("header index out of range");
    header = &state->headers[index];
    RETVAL = request_slice_sv(aTHX_ state, header->value_offset, header->value_length);
  OUTPUT:
    RETVAL

SV *
header(self, name)
    SV *self
    SV *name
  PREINIT:
    le_http_request_state *state;
    STRLEN name_len;
    const char *wanted;
    size_t i;
  CODE:
    state = request_state_from_object(aTHX_ self);
    wanted = SvPVbyte(name, name_len);

    for (i = 0; i < state->num_headers; ++i) {
        le_http_header_slice *header = &state->headers[i];
        if (ascii_equal_ci(
                state->bytes + header->name_offset,
                header->name_length,
                wanted,
                (size_t)name_len
            )) {
            RETVAL = request_slice_sv(aTHX_ state, header->value_offset, header->value_length);
            goto header_found;
        }
    }

    XSRETURN_UNDEF;

  header_found:
  OUTPUT:
    RETVAL

void
header_values(self, name)
    SV *self
    SV *name
  PREINIT:
    le_http_request_state *state;
    STRLEN name_len;
    const char *wanted;
    size_t i;
  PPCODE:
    state = request_state_from_object(aTHX_ self);
    wanted = SvPVbyte(name, name_len);

    for (i = 0; i < state->num_headers; ++i) {
        le_http_header_slice *header = &state->headers[i];
        if (ascii_equal_ci(
                state->bytes + header->name_offset,
                header->name_length,
                wanted,
                (size_t)name_len
            )) {
            XPUSHs(sv_2mortal(request_slice_sv(
                aTHX_
                state,
                header->value_offset,
                header->value_length
            )));
        }
    }

int
_expect_continue(self)
    SV *self
  PREINIT:
    le_http_request_state *state;
  CODE:
    state = request_state_from_object(aTHX_ self);
    RETVAL = state->expect_mode;
  OUTPUT:
    RETVAL

IV
_consumed(self)
    SV *self
  PREINIT:
    le_http_request_state *state;
  CODE:
    state = request_state_from_object(aTHX_ self);
    RETVAL = (IV)state->consumed;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  PREINIT:
    SV *inner;
    le_http_request_state *state;
  CODE:
    if (!SvROK(self))
        XSRETURN_EMPTY;

    inner = SvRV(self);
    state = INT2PTR(le_http_request_state *, SvIV(inner));
    if (state == NULL)
        XSRETURN_EMPTY;

    Safefree(state);
    sv_setiv(inner, 0);


MODULE = Linux::Event::HTTP::_HTTP1    PACKAGE = Linux::Event::HTTP::Response

SV *
_new_server_default(CLASS, request)
    const char *CLASS
    SV *request
  PREINIT:
    le_http_request_state *state;
    HV *hv;
    UV flags;
    HV *stash;
  CODE:
    state = request_state_from_object(aTHX_ request);
    flags = LE_HTTP_RESPONSE_SERVER_DEFAULT_FINAL
        | LE_HTTP_RESPONSE_SERVER_SCALAR_SIMPLE
        | LE_HTTP_RESPONSE_SERVER_OBJECT;
    if (state->minor_version == 0)
        flags |= LE_HTTP_RESPONSE_SERVER_HTTP10;

    hv = newHV();
    hv_store(
        hv,
        "_server_flags",
        (I32)(sizeof("_server_flags") - 1),
        newSVuv(flags),
        0
    );

    RETVAL = newRV_noinc((SV *)hv);
    stash = gv_stashpv(CLASS, GV_ADD);
    sv_bless(RETVAL, stash);
  OUTPUT:
    RETVAL

void
_set_header_native(self, name, value)
    SV *self
    SV *name
    SV *value
  CODE:
    response_set_header_native(aTHX_ self, name, value);

void
_set_body_native(self, body)
    SV *self
    SV *body
  CODE:
    response_set_body_native(aTHX_ self, body);

SV *
_serialize_head(self, http_version = "1.1")
    SV *self
    const char *http_version
  PREINIT:
    HV *hv;
    SV **status_ptr;
    SV **reason_ptr;
    SV **headers_ptr;
    IV status;
    const char *reason;
    STRLEN reason_len;
    AV *headers;
    SSize_t max_index;
    SSize_t i;
    SV *head;
    int saw_content_length = 0;
    int saw_transfer_encoding = 0;
  CODE:
    if (!SvROK(self) ||
        !sv_derived_from(self, "Linux::Event::HTTP::Response") ||
        SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("not a Linux::Event::HTTP::Response object");

    if (strNE(http_version, "1.0") && strNE(http_version, "1.1"))
        croak("HTTP/1 response version must be 1.0 or 1.1");

    hv = (HV *)SvRV(self);

    status_ptr = hv_fetch(hv, "status", 6, 0);
    if (status_ptr == NULL) {
        if (!response_server_flags(aTHX_ hv))
            croak("response status is required");
        status = 200;
    } else {
        if (!SvOK(*status_ptr))
            croak("response status is required");
        status = SvIV(*status_ptr);
    }
    if (status < 100 || status > 999)
        croak("response status must be between 100 and 999");

    reason_ptr = hv_fetch(hv, "reason", 6, 0);
    if (reason_ptr != NULL && SvOK(*reason_ptr)) {
        reason = SvPVbyte(*reason_ptr, reason_len);
        if (!valid_reason_phrase(reason, (size_t)reason_len))
            croak("response reason phrase contains invalid control characters");
    } else {
        reason = default_reason_phrase((int)status);
        reason_len = (STRLEN)strlen(reason);
    }

    headers_ptr = hv_fetch(hv, "headers", 7, 0);
    if (headers_ptr == NULL) {
        if (!response_server_flags(aTHX_ hv))
            croak("response headers storage is invalid");
        headers = NULL;
    } else {
        if (!SvROK(*headers_ptr) ||
            SvTYPE(SvRV(*headers_ptr)) != SVt_PVAV)
            croak("response headers storage is invalid");
        headers = (AV *)SvRV(*headers_ptr);
    }

    head = newSVpvn("", 0);
    sv_catpvf(head, "HTTP/%s %03" IVdf " ", http_version, status);
    sv_catpvn(head, reason, reason_len);
    sv_catpvn(head, "\r\n", 2);

    max_index = headers == NULL ? -1 : av_len(headers);
    for (i = 0; i <= max_index; ++i) {
        SV **row_ptr = av_fetch(headers, i, 0);
        AV *row;
        SV **name_ptr;
        SV **value_ptr;
        const char *name;
        const char *value;
        STRLEN name_len;
        STRLEN value_len;

        if (row_ptr == NULL ||
            !SvROK(*row_ptr) ||
            SvTYPE(SvRV(*row_ptr)) != SVt_PVAV) {
            SvREFCNT_dec(head);
            croak("response header entry is invalid");
        }

        row = (AV *)SvRV(*row_ptr);
        name_ptr = av_fetch(row, 0, 0);
        value_ptr = av_fetch(row, 1, 0);

        if (name_ptr == NULL || value_ptr == NULL ||
            !SvOK(*name_ptr) || !SvOK(*value_ptr)) {
            SvREFCNT_dec(head);
            croak("response header entry requires name and value");
        }

        name = SvPVbyte(*name_ptr, name_len);
        value = SvPVbyte(*value_ptr, value_len);

        if (!valid_field_name(name, (size_t)name_len)) {
            SvREFCNT_dec(head);
            croak("invalid response header field name");
        }

        if (!valid_output_field_value(value, (size_t)value_len)) {
            SvREFCNT_dec(head);
            croak("response header field value contains invalid control characters");
        }

        if (ascii_equal_ci(name, (size_t)name_len, "Content-Length", 14)) {
            if (saw_content_length) {
                SvREFCNT_dec(head);
                croak("response must not contain multiple Content-Length fields");
            }
            if (!valid_output_content_length(value, (size_t)value_len)) {
                SvREFCNT_dec(head);
                croak("response Content-Length must be a decimal number");
            }
            saw_content_length = 1;
        } else if (ascii_equal_ci(
                       name,
                       (size_t)name_len,
                       "Transfer-Encoding",
                       17
                   )) {
            saw_transfer_encoding = 1;
        }

        sv_catpvn(head, name, name_len);
        sv_catpvn(head, ": ", 2);
        sv_catpvn(head, value, value_len);
        sv_catpvn(head, "\r\n", 2);
    }

    if (saw_content_length && saw_transfer_encoding) {
        SvREFCNT_dec(head);
        croak("response cannot contain both Transfer-Encoding and Content-Length");
    }

    if ((status >= 100 && status < 200) || status == 204) {
        if (saw_content_length) {
            SvREFCNT_dec(head);
            croak("1xx and 204 responses must not contain Content-Length");
        }
        if (saw_transfer_encoding) {
            SvREFCNT_dec(head);
            croak("1xx and 204 responses must not contain Transfer-Encoding");
        }
    }

    sv_catpvn(head, "\r\n", 2);
    RETVAL = head;
  OUTPUT:
    RETVAL

MODULE = Linux::Event::HTTP::_HTTP1    PACKAGE = Linux::Event::HTTP::_HTTP1::Chunked
PROTOTYPES: DISABLE

SV *
new(CLASS)
    const char *CLASS
  PREINIT:
    struct phr_chunked_decoder *decoder;
  CODE:
    Newxz(decoder, 1, struct phr_chunked_decoder);
    decoder->consume_trailer = 1;
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, CLASS, (void *)decoder);
  OUTPUT:
    RETVAL

void
feed(self, buffer, emit = 1)
    SV *self
    SV *buffer
    int emit
  PREINIT:
    struct phr_chunked_decoder *decoder;
    STRLEN buffer_len;
    char *buf;
    size_t decoded_len;
    ssize_t result;
    size_t leftover;
    SV *decoded = NULL;
  PPCODE:
    decoder = decoder_from_object(aTHX_ self);

    if (SvREADONLY(buffer))
        croak("chunked decoder input buffer must be writable");

    sv_force_normal(buffer);
    buf = SvPVbyte_force(buffer, buffer_len);
    decoded_len = (size_t)buffer_len;

    result = phr_decode_chunked(decoder, buf, &decoded_len);
    if (result == -1)
        croak("malformed HTTP/1 chunked request body");

    if (emit && decoded_len != 0)
        decoded = newSVpvn(buf, decoded_len);

    if (result >= 0) {
        leftover = (size_t)result;
        if (leftover != 0)
            memmove(buf, buf + decoded_len, leftover);
        SvCUR_set(buffer, (STRLEN)leftover);
        buf[leftover] = '\0';
    } else {
        SvCUR_set(buffer, 0);
        buf[0] = '\0';
    }
    SvUTF8_off(buffer);

    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(result >= 0 ? 1 : 0)));
    if (decoded != NULL)
        PUSHs(sv_2mortal(decoded));
    else
        PUSHs(&PL_sv_undef);

void
DESTROY(self)
    SV *self
  PREINIT:
    SV *inner;
    struct phr_chunked_decoder *decoder;
  CODE:
    if (!SvROK(self))
        XSRETURN_EMPTY;

    inner = SvRV(self);
    decoder = INT2PTR(struct phr_chunked_decoder *, SvIV(inner));
    if (decoder == NULL)
        XSRETURN_EMPTY;

    Safefree(decoder);
    sv_setiv(inner, 0);

MODULE = Linux::Event::HTTP::_HTTP1    PACKAGE = Linux::Event::HTTP::_HTTP1
PROTOTYPES: DISABLE

SV *
build_default_final(CLASS, request, body)
    const char *CLASS
    SV *request
    SV *body
  PREINIT:
    le_http_request_state *state;
    SV *body_copy = NULL;
    STRLEN body_len = 0;
    const char *body_bytes = "";
    SV *wire;
  CODE:
    (void)CLASS;
    state = request_state_from_object(aTHX_ request);

    /*
     * This is intentionally a very narrow experimental fast path. Anything
     * outside the common persistent HTTP/1.1 scalar-response case falls back
     * to the existing Perl response state machine.
     */
    if (state->minor_version != 1 || !state->keep_alive ||
        request_method_is_head(state))
        XSRETURN_UNDEF;

    if (SvROK(body))
        croak("end(): body must be a scalar byte string");

    /*
     * The common callback result is already an ordinary, non-magical byte
     * string. Read that scalar directly: final wire construction necessarily
     * copies the bytes, so an intermediate newSVsv() adds allocation/memcpy.
     *
     * Keep copy-based behavior for UTF-8, magical, and non-PV scalars so UTF-8
     * downgrade validation never mutates the caller's value.
     */
    if (!SvOK(body)) {
        body_bytes = "";
        body_len = 0;
    } else if (SvPOK(body) && !SvUTF8(body) && !SvGMAGICAL(body)) {
        body_bytes = SvPVbyte(body, body_len);
    } else {
        body_copy = newSVsv(body);
        if (SvUTF8(body_copy) && !sv_utf8_downgrade(body_copy, TRUE)) {
            SvREFCNT_dec(body_copy);
            croak("end(): body contains wide characters; encode it to bytes first");
        }
        body_bytes = SvPVbyte(body_copy, body_len);
    }

    wire = newSVpvf(
        "HTTP/1.1 200 OK\r\nContent-Length: %" UVuf "\r\n\r\n",
        (UV)body_len
    );
    sv_catpvn(wire, body_bytes, body_len);

    if (body_copy != NULL)
        SvREFCNT_dec(body_copy);

    RETVAL = wire;
  OUTPUT:
    RETVAL
