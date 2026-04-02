package Hypersonic::UA::Protocol::HTTP1;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use constant MAX_HEADER_SIZE => 16384;
use constant DECODE_BUF_SIZE => 1048576;

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    $class->gen_helpers($builder);
    $class->gen_xs_build_request($builder);
    $class->gen_xs_parse_status_line($builder);
    $class->gen_xs_parse_headers($builder);
    $class->gen_xs_find_body_start($builder);
    $class->gen_xs_get_content_length($builder);
    $class->gen_xs_decode_chunked($builder);
    $class->gen_xs_parse_response($builder);
}

sub get_xs_functions {
    return {
        'Hypersonic::UA::Protocol::HTTP1::build_request'      => { source => 'xs_http1_build_request', is_xs_native => 1 },
        'Hypersonic::UA::Protocol::HTTP1::parse_status_line'  => { source => 'xs_http1_parse_status_line', is_xs_native => 1 },
        'Hypersonic::UA::Protocol::HTTP1::parse_headers'      => { source => 'xs_http1_parse_headers', is_xs_native => 1 },
        'Hypersonic::UA::Protocol::HTTP1::find_body_start'    => { source => 'xs_http1_find_body_start', is_xs_native => 1 },
        'Hypersonic::UA::Protocol::HTTP1::get_content_length' => { source => 'xs_http1_get_content_length', is_xs_native => 1 },
        'Hypersonic::UA::Protocol::HTTP1::decode_chunked'     => { source => 'xs_http1_decode_chunked', is_xs_native => 1 },
        'Hypersonic::UA::Protocol::HTTP1::parse_response'     => { source => 'xs_http1_parse_response', is_xs_native => 1 },
    };
}

sub gen_helpers {
    my ($class, $builder) = @_;

    $builder->line("#define HTTP1_MAX_HEADER_SIZE " . MAX_HEADER_SIZE)
      ->line("#define HTTP1_DECODE_BUF_SIZE " . DECODE_BUF_SIZE)
      ->blank
      ->line("static char g_http1_decode_buf[HTTP1_DECODE_BUF_SIZE];")
      ->blank;

    $builder->comment('Parse HTTP/1.x response status line')
      ->comment('Returns: status code, or -1 on error')
      ->line('static int http1_parse_status_line(const char* buf, size_t len, int* http_minor) {')
      ->line('    int i;')
      ->line('    if (len < 12) return -1;')
      ->line('    if (memcmp(buf, "HTTP/1.", 7) != 0) return -1;')
      ->blank
      ->line('    *http_minor = buf[7] - \'0\';')
      ->line('    if (buf[8] != \' \') return -1;')
      ->blank
      ->line('    int status = 0;')
      ->line('    for (i = 9; i < 12; i++) {')
      ->line('        if (buf[i] < \'0\' || buf[i] > \'9\') return -1;')
      ->line('        status = status * 10 + (buf[i] - \'0\');')
      ->line('    }')
      ->line('    return status;')
      ->line('}')
      ->blank;

    $builder->comment('Find body start (after \\r\\n\\r\\n)')
      ->line('static const char* http1_find_body_start(const char* buf, size_t len) {')
      ->line('    if (len < 4) return NULL;')
      ->line('    const char* end = buf + len - 3;')
      ->line('    for (const char* p = buf; p < end; p++) {')
      ->line('        if (p[0] == \'\\r\' && p[1] == \'\\n\' && p[2] == \'\\r\' && p[3] == \'\\n\') {')
      ->line('            return p + 4;')
      ->line('        }')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->blank;

    $builder->comment('Parse response headers into Perl HV')
      ->line('static HV* http1_parse_headers_into_hv(const char* buf, size_t len) {')
      ->line('    HV* headers = newHV();')
      ->line('    const char* p = buf;')
      ->line('    const char* end = buf + len;')
      ->blank
      ->line('    while (p < end && *p != \'\\n\') p++;')
      ->line('    if (p < end) p++;')
      ->blank
      ->line('    while (p < end - 1) {')
      ->line('        if (p[0] == \'\\r\' && p[1] == \'\\n\') break;')
      ->line('        if (p[0] == \'\\n\') break;')
      ->blank
      ->line('        const char* colon = p;')
      ->line('        while (colon < end && *colon != \':\' && *colon != \'\\r\') colon++;')
      ->line('        if (colon >= end || *colon != \':\') break;')
      ->blank
      ->line('        int name_len = colon - p;')
      ->blank
      ->line('        const char* value = colon + 1;')
      ->line('        while (value < end && *value == \' \') value++;')
      ->blank
      ->line('        const char* vend = value;')
      ->line('        while (vend < end && *vend != \'\\r\' && *vend != \'\\n\') vend++;')
      ->blank
      ->line('        int i;')
      ->line('        char norm_name[256];')
      ->line('        if (name_len > 255) name_len = 255;')
      ->line('        for (i = 0; i < name_len; i++) {')
      ->line('            char c = p[i];')
      ->line('            if (c >= \'A\' && c <= \'Z\') c += 32;')
      ->line('            else if (c == \'-\') c = \'_\';')
      ->line('            norm_name[i] = c;')
      ->line('        }')
      ->blank
      ->line('        hv_store(headers, norm_name, name_len, newSVpvn(value, vend - value), 0);')
      ->blank
      ->line('        p = vend;')
      ->line('        if (p < end && *p == \'\\r\') p++;')
      ->line('        if (p < end && *p == \'\\n\') p++;')
      ->line('    }')
      ->blank
      ->line('    return headers;')
      ->line('}')
      ->blank;

    $builder->comment('Decode chunked transfer encoding')
      ->line('static ssize_t http1_decode_chunked_data(const char* input, size_t input_len, char* output, size_t output_size) {')
      ->line('    const char* p = input;')
      ->line('    const char* end = input + input_len;')
      ->line('    size_t out_pos = 0;')
      ->blank
      ->line('    while (p < end) {')
      ->line('        size_t chunk_size = 0;')
      ->line('        while (p < end && *p != \'\\r\' && *p != \'\\n\') {')
      ->line('            char c = *p;')
      ->line('            if (c >= \'0\' && c <= \'9\') chunk_size = chunk_size * 16 + (c - \'0\');')
      ->line('            else if (c >= \'a\' && c <= \'f\') chunk_size = chunk_size * 16 + (c - \'a\' + 10);')
      ->line('            else if (c >= \'A\' && c <= \'F\') chunk_size = chunk_size * 16 + (c - \'A\' + 10);')
      ->line('            else if (c == \';\') break;')
      ->line('            else break;')
      ->line('            p++;')
      ->line('        }')
      ->blank
      ->line('        while (p < end && *p != \'\\r\' && *p != \'\\n\') p++;')
      ->line('        if (p < end && *p == \'\\r\') p++;')
      ->line('        if (p < end && *p == \'\\n\') p++;')
      ->blank
      ->line('        if (chunk_size == 0) {')
      ->line('            while (p < end - 1 && !(p[0] == \'\\r\' && p[1] == \'\\n\')) {')
      ->line('                while (p < end && *p != \'\\n\') p++;')
      ->line('                if (p < end) p++;')
      ->line('            }')
      ->line('            return (ssize_t)out_pos;')
      ->line('        }')
      ->blank
      ->line('        if (p + chunk_size + 2 > end) return -1;')
      ->line('        if (out_pos + chunk_size > output_size) return -2;')
      ->blank
      ->line('        memcpy(output + out_pos, p, chunk_size);')
      ->line('        out_pos += chunk_size;')
      ->line('        p += chunk_size;')
      ->blank
      ->line('        if (p < end && *p == \'\\r\') p++;')
      ->line('        if (p < end && *p == \'\\n\') p++;')
      ->line('    }')
      ->blank
      ->line('    return -1;')
      ->line('}')
      ->blank;
}

sub gen_xs_build_request {
    my ($class, $builder) = @_;

    $builder->comment('Build HTTP/1.1 request string')
      ->xs_function('xs_http1_build_request')
      ->xs_preamble
      ->line('if (items < 4) croak("Usage: build_request(method, path, host, headers_hv, [body])");')
      ->blank
      ->line('STRLEN method_len, path_len, host_len;')
      ->line('const char* method = SvPV(ST(0), method_len);')
      ->line('const char* path = SvPV(ST(1), path_len);')
      ->line('const char* host = SvPV(ST(2), host_len);')
      ->line('HV* headers = (HV*)SvRV(ST(3));')
      ->line('SV* body_sv = (items > 4) ? ST(4) : NULL;')
      ->blank
      ->line('size_t request_size = method_len + 1 + path_len + 12 + 6 + host_len + 2;')
      ->blank
      ->line('hv_iterinit(headers);')
      ->line('HE* entry;')
      ->line('while ((entry = hv_iternext(headers)) != NULL) {')
      ->line('    SV* key_sv = hv_iterkeysv(entry);')
      ->line('    SV* val_sv = hv_iterval(headers, entry);')
      ->line('    STRLEN key_len, val_len;')
      ->line('    SvPV(key_sv, key_len);')
      ->line('    SvPV(val_sv, val_len);')
      ->line('    request_size += key_len + 2 + val_len + 2;')
      ->line('}')
      ->blank
      ->line('STRLEN body_len = 0;')
      ->if('body_sv && SvOK(body_sv)')
        ->line('SvPV(body_sv, body_len);')
        ->line('request_size += 20 + body_len;')
      ->endif
      ->line('request_size += 2;')
      ->blank
      ->line('SV* request = newSV(request_size);')
      ->line('SvPOK_on(request);')
      ->line('char* rp = SvPVX(request);')
      ->blank
      ->line('memcpy(rp, method, method_len); rp += method_len;')
      ->line('*rp++ = \' \';')
      ->line('memcpy(rp, path, path_len); rp += path_len;')
      ->line('memcpy(rp, " HTTP/1.1\\r\\n", 11); rp += 11;')
      ->blank
      ->line('memcpy(rp, "Host: ", 6); rp += 6;')
      ->line('memcpy(rp, host, host_len); rp += host_len;')
      ->line('*rp++ = \'\\r\'; *rp++ = \'\\n\';')
      ->blank
      ->line('hv_iterinit(headers);')
      ->line('while ((entry = hv_iternext(headers)) != NULL) {')
      ->line('    SV* key_sv = hv_iterkeysv(entry);')
      ->line('    SV* val_sv = hv_iterval(headers, entry);')
      ->line('    STRLEN key_len, val_len;')
      ->line('    const char* key = SvPV(key_sv, key_len);')
      ->line('    const char* val = SvPV(val_sv, val_len);')
      ->line('    memcpy(rp, key, key_len); rp += key_len;')
      ->line('    *rp++ = \':\'; *rp++ = \' \';')
      ->line('    memcpy(rp, val, val_len); rp += val_len;')
      ->line('    *rp++ = \'\\r\'; *rp++ = \'\\n\';')
      ->line('}')
      ->blank
      ->if('body_len > 0')
        ->line('rp += sprintf(rp, "Content-Length: %zu\\r\\n", body_len);')
      ->endif
      ->blank
      ->line('*rp++ = \'\\r\'; *rp++ = \'\\n\';')
      ->if('body_len > 0')
        ->line('const char* body = SvPV_nolen(body_sv);')
        ->line('memcpy(rp, body, body_len); rp += body_len;')
      ->endif
      ->blank
      ->line('SvCUR_set(request, rp - SvPVX(request));')
      ->line('ST(0) = sv_2mortal(request);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_parse_status_line {
    my ($class, $builder) = @_;

    $builder->comment('Parse status line, return status code')
      ->xs_function('xs_http1_parse_status_line')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: parse_status_line(raw)");')
      ->blank
      ->line('STRLEN raw_len;')
      ->line('const char* raw = SvPV(ST(0), raw_len);')
      ->line('int http_minor;')
      ->line('int status = http1_parse_status_line(raw, raw_len, &http_minor);')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(status));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_parse_headers {
    my ($class, $builder) = @_;

    $builder->comment('Parse headers into hashref')
      ->xs_function('xs_http1_parse_headers')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: parse_headers(raw)");')
      ->blank
      ->line('STRLEN raw_len;')
      ->line('const char* raw = SvPV(ST(0), raw_len);')
      ->blank
      ->line('const char* body_start = http1_find_body_start(raw, raw_len);')
      ->line('size_t headers_len = body_start ? (body_start - raw) : raw_len;')
      ->blank
      ->line('HV* headers = http1_parse_headers_into_hv(raw, headers_len);')
      ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)headers));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_find_body_start {
    my ($class, $builder) = @_;

    $builder->comment('Find offset of body start')
      ->xs_function('xs_http1_find_body_start')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: find_body_start(raw)");')
      ->blank
      ->line('STRLEN raw_len;')
      ->line('const char* raw = SvPV(ST(0), raw_len);')
      ->blank
      ->line('const char* body = http1_find_body_start(raw, raw_len);')
      ->if('body')
        ->line('ST(0) = sv_2mortal(newSViv(body - raw));')
      ->else
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_get_content_length {
    my ($class, $builder) = @_;

    $builder->comment('Extract Content-Length from headers')
      ->xs_function('xs_http1_get_content_length')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: get_content_length(headers_str)");')
      ->blank
      ->line('STRLEN len;')
      ->line('const char* headers = SvPV(ST(0), len);')
      ->blank
      ->line('const char* cl = strcasestr(headers, "\\r\\nContent-Length:");')
      ->line('if (!cl) cl = strcasestr(headers, "\\nContent-Length:");')
      ->if('!cl')
        ->line('ST(0) = sv_2mortal(newSViv(-1));')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('cl += (cl[0] == \'\\r\') ? 17 : 16;')
      ->line('while (*cl == \' \') cl++;')
      ->blank
      ->line('ssize_t length = 0;')
      ->line('while (*cl >= \'0\' && *cl <= \'9\') {')
      ->line('    length = length * 10 + (*cl - \'0\');')
      ->line('    cl++;')
      ->line('}')
      ->line('ST(0) = sv_2mortal(newSViv(length));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_decode_chunked {
    my ($class, $builder) = @_;

    $builder->comment('Decode chunked transfer encoding')
      ->xs_function('xs_http1_decode_chunked')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: decode_chunked(body)");')
      ->blank
      ->line('STRLEN input_len;')
      ->line('const char* input = SvPV(ST(0), input_len);')
      ->blank
      ->line('ssize_t decoded_len = http1_decode_chunked_data(input, input_len, g_http1_decode_buf, HTTP1_DECODE_BUF_SIZE);')
      ->if('decoded_len >= 0')
        ->line('ST(0) = sv_2mortal(newSVpvn(g_http1_decode_buf, decoded_len));')
      ->else
        ->line('ST(0) = &PL_sv_undef;')
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_parse_response {
    my ($class, $builder) = @_;

    $builder->comment('Parse raw HTTP response into [status, headers_hv, body, raw_headers]')
      ->xs_function('xs_http1_parse_response')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: parse_response(raw_response)");')
      ->blank
      ->line('STRLEN raw_len;')
      ->line('const char* raw = SvPV(ST(0), raw_len);')
      ->blank
      ->line('int http_minor;')
      ->line('int status = http1_parse_status_line(raw, raw_len, &http_minor);')
      ->if('status < 0')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('const char* body_start = http1_find_body_start(raw, raw_len);')
      ->if('!body_start')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('size_t headers_len = body_start - raw;')
      ->line('size_t body_len = raw_len - headers_len;')
      ->blank
      ->line('HV* headers = http1_parse_headers_into_hv(raw, headers_len);')
      ->blank
      ->line('SV** te = hv_fetch(headers, "transfer_encoding", 17, 0);')
      ->line('int chunked = (te && *te && strstr(SvPV_nolen(*te), "chunked"));')
      ->blank
      ->line('SV* body_sv;')
      ->if('chunked')
        ->line('ssize_t decoded_len = http1_decode_chunked_data(body_start, body_len, g_http1_decode_buf, HTTP1_DECODE_BUF_SIZE);')
        ->if('decoded_len >= 0')
          ->line('body_sv = newSVpvn(g_http1_decode_buf, decoded_len);')
        ->else
          ->line('body_sv = newSVpvn(body_start, body_len);')
        ->endif
      ->else
        ->line('body_sv = newSVpvn(body_start, body_len);')
      ->endif
      ->blank
      ->line('AV* result = newAV();')
      ->line('av_push(result, newSViv(status));')
      ->line('av_push(result, newRV_noinc((SV*)headers));')
      ->line('av_push(result, body_sv);')
      ->line('av_push(result, newSVpvn(raw, headers_len));')
      ->blank
      ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)result));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

1;
