#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "../vendor/picohttpparser/picohttpparser.c"

#define LE_HTTP1_MAX_HEADERS 256

#define LE_HTTP_BODY_NONE 0
#define LE_HTTP_BODY_CONTENT_LENGTH 1
#define LE_HTTP_BODY_CHUNKED 2

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
    UV content_length;
} le_http_request_semantics;

typedef struct {
    int consumed;
    int minor_version;
    int body_mode;
    int keep_alive;
    int has_content_length;
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

MODULE = Linux::Event::HTTP::_HTTP1    PACKAGE = Linux::Event::HTTP::_HTTP1
PROTOTYPES: DISABLE

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
    if (status_ptr == NULL || !SvOK(*status_ptr))
        croak("response status is required");

    status = SvIV(*status_ptr);
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
    if (headers_ptr == NULL ||
        !SvROK(*headers_ptr) ||
        SvTYPE(SvRV(*headers_ptr)) != SVt_PVAV)
        croak("response headers storage is invalid");

    headers = (AV *)SvRV(*headers_ptr);

    head = newSVpvn("", 0);
    sv_catpvf(head, "HTTP/%s %03" IVdf " ", http_version, status);
    sv_catpvn(head, reason, reason_len);
    sv_catpvn(head, "\r\n", 2);

    max_index = av_len(headers);
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
