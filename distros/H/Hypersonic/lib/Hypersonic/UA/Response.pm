package Hypersonic::UA::Response;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use constant {
    SLOT_STATUS         => 0,
    SLOT_STATUS_TEXT    => 1,
    SLOT_HEADERS        => 2,
    SLOT_BODY           => 3,
    SLOT_CONTENT_TYPE   => 4,
    SLOT_CONTENT_LENGTH => 5,
    SLOT_HTTP_VERSION   => 6,
    SLOT_REQUEST        => 7,
    SLOT_REDIRECTS      => 8,
    SLOT_TIMING         => 9,
    SLOT_JSON           => 10,
    SLOT_RAW_HEADERS    => 11,
    SLOT_COUNT          => 12,
};

use constant MAX_RESPONSES => 65536;

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    $class->gen_slot_constants($builder);
    $class->gen_xs_new($builder);
    $class->gen_xs_from_raw($builder);
    $class->gen_xs_status($builder);
    $class->gen_xs_status_text($builder);
    $class->gen_xs_body($builder);
    $class->gen_xs_headers($builder);
    $class->gen_xs_header($builder);
    $class->gen_xs_content_type($builder);
    $class->gen_xs_content_length($builder);
    $class->gen_xs_raw_headers($builder);
    $class->gen_xs_is_success($builder);
    $class->gen_xs_is_redirect($builder);
    $class->gen_xs_is_error($builder);
    $class->gen_xs_is_client_error($builder);
    $class->gen_xs_is_server_error($builder);
    $class->gen_xs_is_json($builder);
    $class->gen_xs_json($builder);
    $class->gen_xs_location($builder);
}

sub get_xs_functions {
    return {
        'Hypersonic::UA::Response::new'             => { source => 'xs_response_new', is_xs_native => 1 },
        'Hypersonic::UA::Response::from_raw'        => { source => 'xs_response_from_raw', is_xs_native => 1 },
        'Hypersonic::UA::Response::status'          => { source => 'xs_response_status', is_xs_native => 1 },
        'Hypersonic::UA::Response::status_text'     => { source => 'xs_response_status_text', is_xs_native => 1 },
        'Hypersonic::UA::Response::body'            => { source => 'xs_response_body', is_xs_native => 1 },
        'Hypersonic::UA::Response::headers'         => { source => 'xs_response_headers', is_xs_native => 1 },
        'Hypersonic::UA::Response::header'          => { source => 'xs_response_header', is_xs_native => 1 },
        'Hypersonic::UA::Response::content_type'    => { source => 'xs_response_content_type', is_xs_native => 1 },
        'Hypersonic::UA::Response::content_length'  => { source => 'xs_response_content_length', is_xs_native => 1 },
        'Hypersonic::UA::Response::raw_headers'     => { source => 'xs_response_raw_headers', is_xs_native => 1 },
        'Hypersonic::UA::Response::is_success'      => { source => 'xs_response_is_success', is_xs_native => 1 },
        'Hypersonic::UA::Response::is_redirect'     => { source => 'xs_response_is_redirect', is_xs_native => 1 },
        'Hypersonic::UA::Response::is_error'        => { source => 'xs_response_is_error', is_xs_native => 1 },
        'Hypersonic::UA::Response::is_client_error' => { source => 'xs_response_is_client_error', is_xs_native => 1 },
        'Hypersonic::UA::Response::is_server_error' => { source => 'xs_response_is_server_error', is_xs_native => 1 },
        'Hypersonic::UA::Response::is_json'         => { source => 'xs_response_is_json', is_xs_native => 1 },
        'Hypersonic::UA::Response::json'            => { source => 'xs_response_json', is_xs_native => 1 },
        'Hypersonic::UA::Response::location'        => { source => 'xs_response_location', is_xs_native => 1 },
    };
}

sub gen_slot_constants {
    my ($class, $builder) = @_;

    $builder->line('#define RESP_SLOT_STATUS ' . SLOT_STATUS)
      ->line('#define RESP_SLOT_STATUS_TEXT ' . SLOT_STATUS_TEXT)
      ->line('#define RESP_SLOT_HEADERS ' . SLOT_HEADERS)
      ->line('#define RESP_SLOT_BODY ' . SLOT_BODY)
      ->line('#define RESP_SLOT_CONTENT_TYPE ' . SLOT_CONTENT_TYPE)
      ->line('#define RESP_SLOT_CONTENT_LENGTH ' . SLOT_CONTENT_LENGTH)
      ->line('#define RESP_SLOT_HTTP_VERSION ' . SLOT_HTTP_VERSION)
      ->line('#define RESP_SLOT_REQUEST ' . SLOT_REQUEST)
      ->line('#define RESP_SLOT_REDIRECTS ' . SLOT_REDIRECTS)
      ->line('#define RESP_SLOT_TIMING ' . SLOT_TIMING)
      ->line('#define RESP_SLOT_JSON ' . SLOT_JSON)
      ->line('#define RESP_SLOT_RAW_HEADERS ' . SLOT_RAW_HEADERS)
      ->line('#define RESP_SLOT_COUNT ' . SLOT_COUNT)
      ->blank;

    $builder->line('static const char* resp_status_text(int status) {')
      ->line('    switch (status) {')
      ->line('        case 100: return "Continue";')
      ->line('        case 101: return "Switching Protocols";')
      ->line('        case 200: return "OK";')
      ->line('        case 201: return "Created";')
      ->line('        case 202: return "Accepted";')
      ->line('        case 204: return "No Content";')
      ->line('        case 206: return "Partial Content";')
      ->line('        case 301: return "Moved Permanently";')
      ->line('        case 302: return "Found";')
      ->line('        case 303: return "See Other";')
      ->line('        case 304: return "Not Modified";')
      ->line('        case 307: return "Temporary Redirect";')
      ->line('        case 308: return "Permanent Redirect";')
      ->line('        case 400: return "Bad Request";')
      ->line('        case 401: return "Unauthorized";')
      ->line('        case 403: return "Forbidden";')
      ->line('        case 404: return "Not Found";')
      ->line('        case 405: return "Method Not Allowed";')
      ->line('        case 408: return "Request Timeout";')
      ->line('        case 409: return "Conflict";')
      ->line('        case 410: return "Gone";')
      ->line('        case 413: return "Payload Too Large";')
      ->line('        case 415: return "Unsupported Media Type";')
      ->line('        case 422: return "Unprocessable Entity";')
      ->line('        case 429: return "Too Many Requests";')
      ->line('        case 500: return "Internal Server Error";')
      ->line('        case 501: return "Not Implemented";')
      ->line('        case 502: return "Bad Gateway";')
      ->line('        case 503: return "Service Unavailable";')
      ->line('        case 504: return "Gateway Timeout";')
      ->line('        default: return "Unknown";')
      ->line('    }')
      ->line('}')
      ->blank;
}

sub gen_xs_new {
    my ($class, $builder) = @_;

    $builder->comment('Create new response from parsed data')
      ->xs_function('xs_response_new')
      ->xs_preamble
      ->line('int status;')
      ->line('HV* opts;')
      ->line('AV* self;')
      ->line('SV** val;')
      ->line('SV* obj;')
      ->blank
      ->line('if (items < 2) croak("Usage: new(class, status, ...)");')
      ->blank
      ->line('status = (int)SvIV(ST(1));')
      ->line('opts = (items > 2 && SvROK(ST(2))) ? (HV*)SvRV(ST(2)) : NULL;')
      ->blank
      ->line('self = newAV();')
      ->line('av_extend(self, RESP_SLOT_COUNT - 1);')
      ->blank
      ->line('av_store(self, RESP_SLOT_STATUS, newSViv(status));')
      ->line('av_store(self, RESP_SLOT_STATUS_TEXT, newSVpv(resp_status_text(status), 0));')
      ->blank
      ->if('opts')
        ->line('val = hv_fetchs(opts, "headers", 0);')
        ->line('av_store(self, RESP_SLOT_HEADERS, val && *val ? newSVsv(*val) : newRV_noinc((SV*)newHV()));')
        ->line('val = hv_fetchs(opts, "body", 0);')
        ->line('av_store(self, RESP_SLOT_BODY, val && *val ? newSVsv(*val) : newSVpvn("", 0));')
        ->line('val = hv_fetchs(opts, "content_type", 0);')
        ->line('av_store(self, RESP_SLOT_CONTENT_TYPE, val && *val ? newSVsv(*val) : newSVpvn("", 0));')
        ->line('val = hv_fetchs(opts, "content_length", 0);')
        ->line('av_store(self, RESP_SLOT_CONTENT_LENGTH, val && *val ? newSVsv(*val) : newSViv(-1));')
        ->line('val = hv_fetchs(opts, "raw_headers", 0);')
        ->line('av_store(self, RESP_SLOT_RAW_HEADERS, val && *val ? newSVsv(*val) : newSVpvn("", 0));')
      ->else
        ->line('av_store(self, RESP_SLOT_HEADERS, newRV_noinc((SV*)newHV()));')
        ->line('av_store(self, RESP_SLOT_BODY, newSVpvn("", 0));')
        ->line('av_store(self, RESP_SLOT_CONTENT_TYPE, newSVpvn("", 0));')
        ->line('av_store(self, RESP_SLOT_CONTENT_LENGTH, newSViv(-1));')
        ->line('av_store(self, RESP_SLOT_RAW_HEADERS, newSVpvn("", 0));')
      ->endif
      ->blank
      ->line('av_store(self, RESP_SLOT_HTTP_VERSION, newSVpvn("1.1", 3));')
      ->line('av_store(self, RESP_SLOT_REQUEST, &PL_sv_undef);')
      ->line('av_store(self, RESP_SLOT_REDIRECTS, newRV_noinc((SV*)newAV()));')
      ->line('av_store(self, RESP_SLOT_TIMING, newRV_noinc((SV*)newHV()));')
      ->line('av_store(self, RESP_SLOT_JSON, &PL_sv_undef);')
      ->blank
      ->line('obj = sv_bless(newRV_noinc((SV*)self), gv_stashpv("Hypersonic::UA::Response", GV_ADD));')
      ->line('ST(0) = sv_2mortal(obj);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_from_raw {
    my ($class, $builder) = @_;

    $builder->comment('Create response from raw HTTP response')
      ->xs_function('xs_response_from_raw')
      ->xs_preamble
      ->line('STRLEN raw_len;')
      ->line('const char* raw;')
      ->line('int http_minor;')
      ->line('int status;')
      ->line('const char* body_start;')
      ->line('size_t headers_len;')
      ->line('size_t body_len;')
      ->line('HV* headers;')
      ->line('AV* self;')
      ->line('SV** ct;')
      ->line('SV** cl;')
      ->line('SV* obj;')
      ->comment('Parse using HTTP1 helpers (must be linked)')
      ->line('extern int http1_parse_status_line(const char*, size_t, int*);')
      ->line('extern const char* http1_find_body_start(const char*, size_t);')
      ->line('extern HV* http1_parse_headers_into_hv(const char*, size_t);')
      ->blank
      ->line('if (items != 2) croak("Usage: from_raw(class, raw)");')
      ->blank
      ->line('raw = SvPV(ST(1), raw_len);')
      ->blank
      ->line('status = http1_parse_status_line(raw, raw_len, &http_minor);')
      ->if('status < 0')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('body_start = http1_find_body_start(raw, raw_len);')
      ->if('!body_start')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('headers_len = body_start - raw;')
      ->line('body_len = raw_len - headers_len;')
      ->blank
      ->line('headers = http1_parse_headers_into_hv(raw, headers_len);')
      ->blank
      ->line('self = newAV();')
      ->line('av_extend(self, RESP_SLOT_COUNT - 1);')
      ->blank
      ->line('av_store(self, RESP_SLOT_STATUS, newSViv(status));')
      ->line('av_store(self, RESP_SLOT_STATUS_TEXT, newSVpv(resp_status_text(status), 0));')
      ->line('av_store(self, RESP_SLOT_HEADERS, newRV_noinc((SV*)headers));')
      ->line('av_store(self, RESP_SLOT_BODY, newSVpvn(body_start, body_len));')
      ->blank
      ->line('ct = hv_fetchs(headers, "content_type", 0);')
      ->line('av_store(self, RESP_SLOT_CONTENT_TYPE, ct && *ct ? newSVsv(*ct) : newSVpvn("", 0));')
      ->blank
      ->line('cl = hv_fetchs(headers, "content_length", 0);')
      ->line('av_store(self, RESP_SLOT_CONTENT_LENGTH, cl && *cl ? newSViv(atoi(SvPV_nolen(*cl))) : newSViv(-1));')
      ->blank
      ->line('av_store(self, RESP_SLOT_HTTP_VERSION, newSVpvn("1.1", 3));')
      ->line('av_store(self, RESP_SLOT_REQUEST, &PL_sv_undef);')
      ->line('av_store(self, RESP_SLOT_REDIRECTS, newRV_noinc((SV*)newAV()));')
      ->line('av_store(self, RESP_SLOT_TIMING, newRV_noinc((SV*)newHV()));')
      ->line('av_store(self, RESP_SLOT_JSON, &PL_sv_undef);')
      ->line('av_store(self, RESP_SLOT_RAW_HEADERS, newSVpvn(raw, headers_len));')
      ->blank
      ->line('obj = sv_bless(newRV_noinc((SV*)self), gv_stashpv("Hypersonic::UA::Response", GV_ADD));')
      ->line('ST(0) = sv_2mortal(obj);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_status {
    my ($class, $builder) = @_;
    $class->_gen_slot_accessor($builder, 'status', 'RESP_SLOT_STATUS');
}

sub gen_xs_status_text {
    my ($class, $builder) = @_;
    $class->_gen_slot_accessor($builder, 'status_text', 'RESP_SLOT_STATUS_TEXT');
}

sub gen_xs_body {
    my ($class, $builder) = @_;
    $class->_gen_slot_accessor($builder, 'body', 'RESP_SLOT_BODY');
}

sub gen_xs_content_type {
    my ($class, $builder) = @_;
    $class->_gen_slot_accessor($builder, 'content_type', 'RESP_SLOT_CONTENT_TYPE');
}

sub gen_xs_content_length {
    my ($class, $builder) = @_;
    $class->_gen_slot_accessor($builder, 'content_length', 'RESP_SLOT_CONTENT_LENGTH');
}

sub gen_xs_raw_headers {
    my ($class, $builder) = @_;
    $class->_gen_slot_accessor($builder, 'raw_headers', 'RESP_SLOT_RAW_HEADERS');
}

sub _gen_slot_accessor {
    my ($class, $builder, $name, $slot) = @_;

    $builder->comment("Get $name")
      ->xs_function("xs_response_$name")
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: ' . $name . '(self)");')
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line("ST(0) = ary[$slot];")
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_headers {
    my ($class, $builder) = @_;

    $builder->comment('Get headers hashref')
      ->xs_function('xs_response_headers')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: headers(self)");')
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('ST(0) = ary[RESP_SLOT_HEADERS];')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_header {
    my ($class, $builder) = @_;

    $builder->comment('Get single header (normalized)')
      ->xs_function('xs_response_header')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: header(self, name)");')
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[RESP_SLOT_HEADERS]);')
      ->blank
      ->line('STRLEN klen;')
      ->line('const char* key = SvPV(ST(1), klen);')
      ->blank
      ->line('char norm_key[256];')
      ->line('size_t i;')
      ->line('if (klen > 255) klen = 255;')
      ->line('for (i = 0; i < klen; i++) {')
      ->line('    char c = key[i];')
      ->line('    if (c >= \'A\' && c <= \'Z\') c += 32;')
      ->line('    else if (c == \'-\') c = \'_\';')
      ->line('    norm_key[i] = c;')
      ->line('}')
      ->blank
      ->line('SV** val = hv_fetch(headers, norm_key, klen, 0);')
      ->line('ST(0) = (val && *val) ? *val : &PL_sv_undef;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_is_success {
    my ($class, $builder) = @_;
    $class->_gen_status_check($builder, 'is_success', 'status >= 200 && status < 300');
}

sub gen_xs_is_redirect {
    my ($class, $builder) = @_;
    $class->_gen_status_check($builder, 'is_redirect', 'status >= 300 && status < 400');
}

sub gen_xs_is_error {
    my ($class, $builder) = @_;
    $class->_gen_status_check($builder, 'is_error', 'status >= 400');
}

sub gen_xs_is_client_error {
    my ($class, $builder) = @_;
    $class->_gen_status_check($builder, 'is_client_error', 'status >= 400 && status < 500');
}

sub gen_xs_is_server_error {
    my ($class, $builder) = @_;
    $class->_gen_status_check($builder, 'is_server_error', 'status >= 500');
}

sub _gen_status_check {
    my ($class, $builder, $name, $condition) = @_;

    $builder->comment("Check $name")
      ->xs_function("xs_response_$name")
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('IV status = SvIV(ary[RESP_SLOT_STATUS]);')
      ->line("ST(0) = ($condition) ? &PL_sv_yes : &PL_sv_no;")
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_is_json {
    my ($class, $builder) = @_;

    $builder->comment('Check if content type is JSON')
      ->xs_function('xs_response_is_json')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('SV* ct = ary[RESP_SLOT_CONTENT_TYPE];')
      ->if('!SvOK(ct)')
        ->line('ST(0) = &PL_sv_no;')
        ->line('XSRETURN(1);')
      ->endif
      ->line('STRLEN ct_len;')
      ->line('const char* ct_str = SvPV(ct, ct_len);')
      ->line('ST(0) = (strstr(ct_str, "application/json") || strstr(ct_str, "+json")) ? &PL_sv_yes : &PL_sv_no;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_json {
    my ($class, $builder) = @_;

    $builder->comment('Get parsed JSON (lazy, cached)')
      ->xs_function('xs_response_json')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->blank
      ->comment('Return cached if available')
      ->line('SV* cached = ary[RESP_SLOT_JSON];')
      ->if('SvOK(cached)')
        ->line('ST(0) = cached;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->comment('Parse JSON using Cpanel::JSON::XS')
      ->line('dSP;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(ary[RESP_SLOT_BODY]);')
      ->line('PUTBACK;')
      ->line('int count = call_pv("Cpanel::JSON::XS::decode_json", G_SCALAR | G_EVAL);')
      ->line('SPAGAIN;')
      ->blank
      ->if('SvTRUE(ERRSV)')
        ->line('POPs;')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('SV* result = POPs;')
      ->line('SvREFCNT_inc(result);')
      ->line('av_store((AV*)SvRV(ST(0)), RESP_SLOT_JSON, result);')
      ->line('ST(0) = result;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_location {
    my ($class, $builder) = @_;

    $builder->comment('Get Location header')
      ->xs_function('xs_response_location')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[RESP_SLOT_HEADERS]);')
      ->line('SV** val = hv_fetchs(headers, "location", 0);')
      ->line('ST(0) = (val && *val) ? *val : &PL_sv_undef;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

1;

__END__

=head1 NAME

Hypersonic::UA::Response - HTTP response object for Hypersonic::UA

=head1 SYNOPSIS

    # Response objects are returned by UA requests
    my $res = $ua->get('http://example.com/api');

    # Check status
    print $res->status;        # 200
    print $res->status_text;   # "OK"

    # Check response type
    if ($res->is_success) { ... }
    if ($res->is_redirect) { ... }
    if ($res->is_error) { ... }

    # Get body
    print $res->body;

    # Get headers
    my $headers = $res->headers;
    my $ct = $res->header('Content-Type');

    # Parse JSON
    if ($res->is_json) {
        my $data = $res->json;
    }

=head1 DESCRIPTION

C<Hypersonic::UA::Response> represents an HTTP response. It provides methods
for accessing status, headers, and body content.

=head1 METHODS

=head2 new

    my $res = Hypersonic::UA::Response->new($status, \%opts);

Create a new response object.

=head2 from_raw

    my $res = Hypersonic::UA::Response->from_raw($raw_http);

Parse a response from raw HTTP bytes.

=head2 status

    my $code = $res->status;

Get HTTP status code (e.g., 200, 404, 500).

=head2 status_text

    my $text = $res->status_text;

Get HTTP status text (e.g., "OK", "Not Found").

=head2 body

    my $body = $res->body;

Get response body as string.

=head2 headers

    my $headers = $res->headers;

Get all headers as hashref.

=head2 header

    my $value = $res->header('Content-Type');

Get a single header value (case-insensitive).

=head2 content_type

    my $ct = $res->content_type;

Get Content-Type header.

=head2 content_length

    my $len = $res->content_length;

Get Content-Length header.

=head2 raw_headers

    my $raw = $res->raw_headers;

Get raw header string.

=head2 is_success

    if ($res->is_success) { ... }

True if status is 2xx.

=head2 is_redirect

    if ($res->is_redirect) { ... }

True if status is 3xx.

=head2 is_error

    if ($res->is_error) { ... }

True if status is 4xx or 5xx.

=head2 is_client_error

    if ($res->is_client_error) { ... }

True if status is 4xx.

=head2 is_server_error

    if ($res->is_server_error) { ... }

True if status is 5xx.

=head2 is_json

    if ($res->is_json) { ... }

True if Content-Type indicates JSON.

=head2 json

    my $data = $res->json;

Parse body as JSON (requires Cpanel::JSON::XS). Result is cached.

=head2 location

    my $url = $res->location;

Get Location header (for redirects).

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
