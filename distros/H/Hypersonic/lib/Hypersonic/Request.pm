package Hypersonic::Request;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

# JIT-compiled Request object using array-based slots for maximum speed
# Generates XS accessors at compile time via XS::JIT::Builder

use XS::JIT;
use XS::JIT::Builder;

# Request slots (array indices) - these map to the array-based request object
# The order MUST match what C code generates in call_dynamic_handler
use constant {
    SLOT_METHOD           => 0,
    SLOT_PATH             => 1,
    SLOT_BODY             => 2,
    SLOT_PARAMS           => 3,   # HV* of named path params
    SLOT_QUERY            => 4,   # HV* of query string params
    SLOT_QUERY_STRING     => 5,   # Raw query string
    SLOT_HEADERS          => 6,   # HV* of headers
    SLOT_COOKIES          => 7,   # HV* of cookies
    SLOT_JSON             => 8,   # Parsed JSON body
    SLOT_FORM             => 9,   # HV* of form data
    SLOT_SEGMENTS         => 10,  # AV* of path segments
    SLOT_ID               => 11,  # Last path segment (legacy)
    SLOT_SESSION          => 12,  # Session data hashref
    SLOT_SESSION_ID       => 13,  # Session ID string
    SLOT_SESSION_MODIFIED => 14,  # Session modified flag
    SLOT_COUNT            => 15,  # Total number of slots
};

# Export slot constants for direct access
use Exporter 'import';
our @EXPORT_OK = qw(
    SLOT_METHOD SLOT_PATH SLOT_BODY SLOT_PARAMS SLOT_QUERY
    SLOT_QUERY_STRING SLOT_HEADERS SLOT_COOKIES SLOT_JSON
    SLOT_FORM SLOT_SEGMENTS SLOT_ID 
    SLOT_SESSION SLOT_SESSION_ID SLOT_SESSION_MODIFIED
    SLOT_COUNT
);

my $COMPILED = 0;
my $MODULE_ID = 0;

# Unified compile interface
sub compile {
    my ($class, %opts) = @_;
    return $class->compile_accessors(%opts);
}

# Generate and compile XS accessors
sub compile_accessors {
    my ($class, %opts) = @_;

    return 1 if $COMPILED;

    my $cache_dir = $opts{cache_dir} // '_hypersonic_cache/request';
    my $module_name = 'Hypersonic::Request::Accessors_' . $MODULE_ID++;

    my $builder = XS::JIT::Builder->new;

    # Generate read-only accessors for simple scalar slots
    $builder->op_ro_accessor('jit_method', SLOT_METHOD);
    $builder->op_ro_accessor('jit_path', SLOT_PATH);
    $builder->op_ro_accessor('jit_body', SLOT_BODY);
    $builder->op_ro_accessor('jit_query_string', SLOT_QUERY_STRING);
    $builder->op_ro_accessor('jit_id', SLOT_ID);

    # Generate accessors for hashref slots (params, query, headers, cookies, form)
    # These return the hashref directly for fast access
    $builder->op_ro_accessor('jit_params', SLOT_PARAMS);
    $builder->op_ro_accessor('jit_query', SLOT_QUERY);
    $builder->op_ro_accessor('jit_headers', SLOT_HEADERS);
    $builder->op_ro_accessor('jit_cookies', SLOT_COOKIES);
    $builder->op_ro_accessor('jit_form', SLOT_FORM);
    $builder->op_ro_accessor('jit_json', SLOT_JSON);
    $builder->op_ro_accessor('jit_segments', SLOT_SEGMENTS);

    # Generate param($name) accessor - fetches from params hashref
    $builder->xs_function('jit_param')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* params = (HV*)SvRV(ary[' . SLOT_PARAMS . ']);')
      ->if('items > 1')
        ->line('STRLEN klen;')
        ->line('const char* key = SvPV(ST(1), klen);')
        ->line('SV** val = hv_fetch(params, key, klen, 0);')
        ->line('ST(0) = val && *val ? *val : &PL_sv_undef;')
      ->else
        ->line('ST(0) = newRV_inc((SV*)params);')
      ->endif
      ->xs_return('1')
      ->xs_end;

    # Generate query_param($name) accessor
    $builder->xs_function('jit_query_param')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* query = (HV*)SvRV(ary[' . SLOT_QUERY . ']);')
      ->if('items > 1')
        ->line('STRLEN klen;')
        ->line('const char* key = SvPV(ST(1), klen);')
        ->line('SV** val = hv_fetch(query, key, klen, 0);')
        ->line('ST(0) = val && *val ? *val : &PL_sv_undef;')
      ->else
        ->line('ST(0) = newRV_inc((SV*)query);')
      ->endif
      ->xs_return('1')
      ->xs_end;

    # Generate header($name) accessor - normalizes header name
    $builder->xs_function('jit_header')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->if('items > 1')
        ->line('STRLEN klen;')
        ->line('const char* key = SvPV(ST(1), klen);')
        ->comment('Normalize: lowercase, hyphens to underscores')
        ->line('char norm_key[256];')
        ->line('int i;')
        ->line('for (i = 0; i < klen && i < 255; i++) {')
        ->line('    char c = key[i];')
        ->line('    norm_key[i] = (c >= \'A\' && c <= \'Z\') ? c + 32 : (c == \'-\') ? \'_\' : c;')
        ->line('}')
        ->line('norm_key[i] = 0;')
        ->line('SV** val = hv_fetch(headers, norm_key, i, 0);')
        ->line('ST(0) = val && *val ? *val : &PL_sv_undef;')
      ->else
        ->line('ST(0) = newRV_inc((SV*)headers);')
      ->endif
      ->xs_return('1')
      ->xs_end;

    # Generate cookie($name) accessor
    $builder->xs_function('jit_cookie')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* cookies = (HV*)SvRV(ary[' . SLOT_COOKIES . ']);')
      ->if('items > 1')
        ->line('STRLEN klen;')
        ->line('const char* key = SvPV(ST(1), klen);')
        ->line('SV** val = hv_fetch(cookies, key, klen, 0);')
        ->line('ST(0) = val && *val ? *val : &PL_sv_undef;')
      ->else
        ->line('ST(0) = newRV_inc((SV*)cookies);')
      ->endif
      ->xs_return('1')
      ->xs_end;

    # Generate form($name) accessor
    $builder->xs_function('jit_form_field')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* form = (HV*)SvRV(ary[' . SLOT_FORM . ']);')
      ->if('items > 1')
        ->line('STRLEN klen;')
        ->line('const char* key = SvPV(ST(1), klen);')
        ->line('SV** val = hv_fetch(form, key, klen, 0);')
        ->line('ST(0) = val && *val ? *val : &PL_sv_undef;')
      ->else
        ->line('ST(0) = newRV_inc((SV*)form);')
      ->endif
      ->xs_return('1')
      ->xs_end;

    # Generate is_json() - check Content-Type header
    $builder->xs_function('jit_is_json')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->line('SV** ct = hv_fetch(headers, "content_type", 12, 0);')
      ->if('ct && *ct && SvOK(*ct)')
        ->line('STRLEN len;')
        ->line('const char* str = SvPV(*ct, len);')
        ->if('len >= 16 && memcmp(str, "application/json", 16) == 0')
          ->line('ST(0) = &PL_sv_yes;')
        ->else
          ->line('ST(0) = &PL_sv_no;')
        ->endif
      ->else
        ->line('ST(0) = &PL_sv_no;')
      ->endif
      ->xs_return('1')
      ->xs_end;

    # Generate is_form() - check Content-Type header
    $builder->xs_function('jit_is_form')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->line('SV** ct = hv_fetch(headers, "content_type", 12, 0);')
      ->if('ct && *ct && SvOK(*ct)')
        ->line('STRLEN len;')
        ->line('const char* str = SvPV(*ct, len);')
        ->if('len >= 33 && memcmp(str, "application/x-www-form-urlencoded", 33) == 0')
          ->line('ST(0) = &PL_sv_yes;')
        ->else
          ->line('ST(0) = &PL_sv_no;')
        ->endif
      ->else
        ->line('ST(0) = &PL_sv_no;')
      ->endif
      ->xs_return('1')
      ->xs_end;

    # Build functions hash
    my %functions = (
        # Simple slot accessors
        'Hypersonic::Request::method'       => { source => 'jit_method', is_xs_native => 1 },
        'Hypersonic::Request::path'         => { source => 'jit_path', is_xs_native => 1 },
        'Hypersonic::Request::body'         => { source => 'jit_body', is_xs_native => 1 },
        'Hypersonic::Request::query_string' => { source => 'jit_query_string', is_xs_native => 1 },
        'Hypersonic::Request::id'           => { source => 'jit_id', is_xs_native => 1 },

        # Hashref slot accessors
        'Hypersonic::Request::params'   => { source => 'jit_params', is_xs_native => 1 },
        'Hypersonic::Request::query'    => { source => 'jit_query', is_xs_native => 1 },
        'Hypersonic::Request::headers'  => { source => 'jit_headers', is_xs_native => 1 },
        'Hypersonic::Request::cookies'  => { source => 'jit_cookies', is_xs_native => 1 },
        'Hypersonic::Request::form'     => { source => 'jit_form_field', is_xs_native => 1 },
        'Hypersonic::Request::json'     => { source => 'jit_json', is_xs_native => 1 },
        'Hypersonic::Request::segments' => { source => 'jit_segments', is_xs_native => 1 },

        # Keyed accessors
        'Hypersonic::Request::param'       => { source => 'jit_param', is_xs_native => 1 },
        'Hypersonic::Request::query_param' => { source => 'jit_query_param', is_xs_native => 1 },
        'Hypersonic::Request::header'      => { source => 'jit_header', is_xs_native => 1 },
        'Hypersonic::Request::cookie'      => { source => 'jit_cookie', is_xs_native => 1 },

        # Type checks
        'Hypersonic::Request::is_json' => { source => 'jit_is_json', is_xs_native => 1 },
        'Hypersonic::Request::is_form' => { source => 'jit_is_form', is_xs_native => 1 },
    );

    # JIT: Only generate response helpers if requested
    if ($opts{response_helpers}) {
        # text_response($text, $status) - returns {status, headers, body}
        $builder->xs_function('jit_text_response')
          ->xs_preamble
          ->line('SV* text = items > 1 ? ST(1) : newSVpvs("");')
          ->line('IV status = items > 2 && SvOK(ST(2)) ? SvIV(ST(2)) : 200;')
          ->line('HV* resp = newHV();')
          ->line('HV* hdrs = newHV();')
          ->line('hv_store(hdrs, "Content-Type", 12, newSVpvs("text/plain"), 0);')
          ->line('hv_store(resp, "status", 6, newSViv(status), 0);')
          ->line('hv_store(resp, "headers", 7, newRV_noinc((SV*)hdrs), 0);')
          ->line('hv_store(resp, "body", 4, newSVsv(text), 0);')
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)resp));')
          ->xs_return('1')
          ->xs_end;

        # html_response($html, $status) - returns {status, headers, body}
        $builder->xs_function('jit_html_response')
          ->xs_preamble
          ->line('SV* html = items > 1 ? ST(1) : newSVpvs("");')
          ->line('IV status = items > 2 && SvOK(ST(2)) ? SvIV(ST(2)) : 200;')
          ->line('HV* resp = newHV();')
          ->line('HV* hdrs = newHV();')
          ->line('hv_store(hdrs, "Content-Type", 12, newSVpvs("text/html"), 0);')
          ->line('hv_store(resp, "status", 6, newSViv(status), 0);')
          ->line('hv_store(resp, "headers", 7, newRV_noinc((SV*)hdrs), 0);')
          ->line('hv_store(resp, "body", 4, newSVsv(html), 0);')
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)resp));')
          ->xs_return('1')
          ->xs_end;

        # redirect($url, $status) - returns {status, headers, body}
        $builder->xs_function('jit_redirect')
          ->xs_preamble
          ->line('SV* url = items > 1 ? ST(1) : newSVpvs("/");')
          ->line('IV status = items > 2 && SvOK(ST(2)) ? SvIV(ST(2)) : 302;')
          ->line('HV* resp = newHV();')
          ->line('HV* hdrs = newHV();')
          ->line('hv_store(hdrs, "Location", 8, newSVsv(url), 0);')
          ->line('hv_store(resp, "status", 6, newSViv(status), 0);')
          ->line('hv_store(resp, "headers", 7, newRV_noinc((SV*)hdrs), 0);')
          ->line('hv_store(resp, "body", 4, newSVpvs(""), 0);')
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)resp));')
          ->xs_return('1')
          ->xs_end;

        # error($message, $status) - returns {status, headers, body} as JSON
        $builder->xs_function('jit_error')
          ->xs_preamble
          ->line('const char* msg = "Internal Server Error";')
          ->line('STRLEN msg_len = 21;')
          ->line('if (items > 1 && SvOK(ST(1))) { msg = SvPV(ST(1), msg_len); }')
          ->line('IV status = items > 2 && SvOK(ST(2)) ? SvIV(ST(2)) : 500;')
          ->line('HV* resp = newHV();')
          ->line('HV* hdrs = newHV();')
          ->line('hv_store(hdrs, "Content-Type", 12, newSVpvs("application/json"), 0);')
          ->line('hv_store(resp, "status", 6, newSViv(status), 0);')
          ->line('hv_store(resp, "headers", 7, newRV_noinc((SV*)hdrs), 0);')
          ->comment('Build JSON: {"error":"message"}')
          ->line('SV* body = newSV(msg_len + 12);')
          ->line('sv_setpvs(body, "{\"error\":\"");')
          ->line('sv_catpvn(body, msg, msg_len);')
          ->line('sv_catpvs(body, "\"}");')
          ->line('hv_store(resp, "body", 4, body, 0);')
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)resp));')
          ->xs_return('1')
          ->xs_end;

        # not_found($message) - calls error with 404
        $builder->xs_function('jit_not_found')
          ->xs_preamble
          ->line('const char* msg = "Not Found";')
          ->line('STRLEN msg_len = 9;')
          ->line('if (items > 1 && SvOK(ST(1))) { msg = SvPV(ST(1), msg_len); }')
          ->line('HV* resp = newHV();')
          ->line('HV* hdrs = newHV();')
          ->line('hv_store(hdrs, "Content-Type", 12, newSVpvs("application/json"), 0);')
          ->line('hv_store(resp, "status", 6, newSViv(404), 0);')
          ->line('hv_store(resp, "headers", 7, newRV_noinc((SV*)hdrs), 0);')
          ->line('SV* body = newSV(msg_len + 12);')
          ->line('sv_setpvs(body, "{\"error\":\"");')
          ->line('sv_catpvn(body, msg, msg_len);')
          ->line('sv_catpvs(body, "\"}");')
          ->line('hv_store(resp, "body", 4, body, 0);')
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)resp));')
          ->xs_return('1')
          ->xs_end;

        # bad_request($message) - calls error with 400
        $builder->xs_function('jit_bad_request')
          ->xs_preamble
          ->line('const char* msg = "Bad Request";')
          ->line('STRLEN msg_len = 11;')
          ->line('if (items > 1 && SvOK(ST(1))) { msg = SvPV(ST(1), msg_len); }')
          ->line('HV* resp = newHV();')
          ->line('HV* hdrs = newHV();')
          ->line('hv_store(hdrs, "Content-Type", 12, newSVpvs("application/json"), 0);')
          ->line('hv_store(resp, "status", 6, newSViv(400), 0);')
          ->line('hv_store(resp, "headers", 7, newRV_noinc((SV*)hdrs), 0);')
          ->line('SV* body = newSV(msg_len + 12);')
          ->line('sv_setpvs(body, "{\"error\":\"");')
          ->line('sv_catpvn(body, msg, msg_len);')
          ->line('sv_catpvs(body, "\"}");')
          ->line('hv_store(resp, "body", 4, body, 0);')
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)resp));')
          ->xs_return('1')
          ->xs_end;

        # unauthorized($message) - calls error with 401
        $builder->xs_function('jit_unauthorized')
          ->xs_preamble
          ->line('const char* msg = "Unauthorized";')
          ->line('STRLEN msg_len = 12;')
          ->line('if (items > 1 && SvOK(ST(1))) { msg = SvPV(ST(1), msg_len); }')
          ->line('HV* resp = newHV();')
          ->line('HV* hdrs = newHV();')
          ->line('hv_store(hdrs, "Content-Type", 12, newSVpvs("application/json"), 0);')
          ->line('hv_store(resp, "status", 6, newSViv(401), 0);')
          ->line('hv_store(resp, "headers", 7, newRV_noinc((SV*)hdrs), 0);')
          ->line('SV* body = newSV(msg_len + 12);')
          ->line('sv_setpvs(body, "{\"error\":\"");')
          ->line('sv_catpvn(body, msg, msg_len);')
          ->line('sv_catpvs(body, "\"}");')
          ->line('hv_store(resp, "body", 4, body, 0);')
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)resp));')
          ->xs_return('1')
          ->xs_end;

        # forbidden($message) - calls error with 403
        $builder->xs_function('jit_forbidden')
          ->xs_preamble
          ->line('const char* msg = "Forbidden";')
          ->line('STRLEN msg_len = 9;')
          ->line('if (items > 1 && SvOK(ST(1))) { msg = SvPV(ST(1), msg_len); }')
          ->line('HV* resp = newHV();')
          ->line('HV* hdrs = newHV();')
          ->line('hv_store(hdrs, "Content-Type", 12, newSVpvs("application/json"), 0);')
          ->line('hv_store(resp, "status", 6, newSViv(403), 0);')
          ->line('hv_store(resp, "headers", 7, newRV_noinc((SV*)hdrs), 0);')
          ->line('SV* body = newSV(msg_len + 12);')
          ->line('sv_setpvs(body, "{\"error\":\"");')
          ->line('sv_catpvn(body, msg, msg_len);')
          ->line('sv_catpvs(body, "\"}");')
          ->line('hv_store(resp, "body", 4, body, 0);')
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)resp));')
          ->xs_return('1')
          ->xs_end;

        # json_response($data, $status) - needs to call Perl JSON encoder
        # This one calls back to Perl for Cpanel::JSON::XS::encode_json
        $builder->xs_function('jit_json_response')
          ->xs_preamble
          ->line('SV* data = items > 1 ? ST(1) : newRV_noinc((SV*)newHV());')
          ->line('IV status = items > 2 && SvOK(ST(2)) ? SvIV(ST(2)) : 200;')
          ->line('ENTER; SAVETMPS;')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(data);')
          ->line('PUTBACK;')
          ->line('int count = call_pv("Cpanel::JSON::XS::encode_json", G_SCALAR);')
          ->line('SPAGAIN;')
          ->line('SV* json_body = count > 0 ? POPs : newSVpvs("{}");')
          ->line('SvREFCNT_inc(json_body);')
          ->line('PUTBACK; FREETMPS; LEAVE;')
          ->line('HV* resp = newHV();')
          ->line('HV* hdrs = newHV();')
          ->line('hv_store(hdrs, "Content-Type", 12, newSVpvs("application/json"), 0);')
          ->line('hv_store(resp, "status", 6, newSViv(status), 0);')
          ->line('hv_store(resp, "headers", 7, newRV_noinc((SV*)hdrs), 0);')
          ->line('hv_store(resp, "body", 4, json_body, 0);')
          ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)resp));')
          ->xs_return('1')
          ->xs_end;

        # Add response helpers to functions hash
        $functions{'Hypersonic::Request::text_response'} = { source => 'jit_text_response', is_xs_native => 1 };
        $functions{'Hypersonic::Request::html_response'} = { source => 'jit_html_response', is_xs_native => 1 };
        $functions{'Hypersonic::Request::redirect'}      = { source => 'jit_redirect', is_xs_native => 1 };
        $functions{'Hypersonic::Request::error'}         = { source => 'jit_error', is_xs_native => 1 };
        $functions{'Hypersonic::Request::not_found'}     = { source => 'jit_not_found', is_xs_native => 1 };
        $functions{'Hypersonic::Request::bad_request'}   = { source => 'jit_bad_request', is_xs_native => 1 };
        $functions{'Hypersonic::Request::unauthorized'}  = { source => 'jit_unauthorized', is_xs_native => 1 };
        $functions{'Hypersonic::Request::forbidden'}     = { source => 'jit_forbidden', is_xs_native => 1 };
        $functions{'Hypersonic::Request::json_response'} = { source => 'jit_json_response', is_xs_native => 1 };
    }

    # Compile via XS::JIT
    XS::JIT->compile(
        code      => $builder->code,
        name      => $module_name,
        cache_dir => $cache_dir,
        functions => \%functions,
    );

    $COMPILED = 1;
    return 1;
}

# Session methods - implemented in Perl because they need to interact
# with the session store. JIT: require cached after first load.

my $SESSION_LOADED;

sub session {
    my $self = shift;
    require Hypersonic::Session unless $SESSION_LOADED++;
    return Hypersonic::Session::get_set($self, @_);
}

sub session_data {
    my $self = shift;
    require Hypersonic::Session unless $SESSION_LOADED++;
    return Hypersonic::Session::get_all($self);
}

sub session_clear {
    my $self = shift;
    require Hypersonic::Session unless $SESSION_LOADED++;
    return Hypersonic::Session::clear($self);
}

sub session_regenerate {
    my $self = shift;
    require Hypersonic::Session unless $SESSION_LOADED++;
    return Hypersonic::Session::regenerate($self);
}

1;

__END__

=head1 NAME

Hypersonic::Request - JIT-compiled request object for Hypersonic

=head1 SYNOPSIS

    use Hypersonic;

    my $server = Hypersonic->new();

    # Dynamic route handler receives a Request object
    $server->get('/users/:id' => sub {
        my ($req) = @_;

        # Basic request info
        my $method = $req->method;           # 'GET'
        my $path   = $req->path;             # '/users/42'
        my $body   = $req->body;             # Request body string

        # Path parameters (from :param in route)
        my $id = $req->param('id');          # '42'

        # Query string parameters (?key=value)
        my $page = $req->query_param('page');     # '1'
        my $all  = $req->query;                   # { page => '1', ... }

        # HTTP headers (normalized to lowercase_underscore)
        my $auth = $req->header('Authorization'); # 'Bearer xxx'
        my $ct   = $req->header('Content-Type');  # 'application/json'

        # Cookies
        my $sid = $req->cookie('session_id');     # 'abc123'

        # JSON body (auto-parsed)
        my $data = $req->json;                    # { name => 'foo' }

        # Form data (application/x-www-form-urlencoded)
        my $email = $req->form_param('email');    # 'user@example.com'

        # Path segments
        my $segments = $req->segments;            # ['users', '42']

        return '{"id":"' . $id . '"}';
    });

    # Enable specific parsing features for performance
    $server->post('/api/data' => sub {
        my ($req) = @_;
        my $data = $req->json;
        return '{"received":true}';
    }, {
        dynamic     => 1,
        parse_json  => 1,    # Enable JSON body parsing
    });

=head1 DESCRIPTION

C<Hypersonic::Request> provides a JIT-compiled request object passed to
dynamic route handlers. All accessor methods are compiled to native XS
code at startup for maximum performance.

The request object is array-based (not hash-based) with slot accessors.
This allows direct array indexing for the fastest possible access when
needed.

=head1 INTERNAL STRUCTURE

The request is an array-based object with the following slots:

    Slot 0:  method            - HTTP method (GET, POST, etc.)
    Slot 1:  path              - Request path
    Slot 2:  body              - Request body string
    Slot 3:  params            - HV* of named path parameters
    Slot 4:  query             - HV* of query string parameters
    Slot 5:  query_string      - Raw query string
    Slot 6:  headers           - HV* of HTTP headers
    Slot 7:  cookies           - HV* of cookies
    Slot 8:  json              - Parsed JSON body (if requested)
    Slot 9:  form              - HV* of form data
    Slot 10: segments          - AV* of path segments
    Slot 11: id                - Last path segment (legacy)
    Slot 12: session           - Session data hashref (if enabled)
    Slot 13: session_id        - Session ID string (if enabled)
    Slot 14: session_modified  - Session modified flag (if enabled)

=head1 METHODS

All methods are JIT-compiled to XS for maximum speed.

=head2 method

    my $method = $req->method;

Returns the HTTP method (GET, POST, PUT, DELETE, etc.).

=head2 path

    my $path = $req->path;

Returns the request path (e.g., C</users/42>).

=head2 body

    my $body = $req->body;

Returns the raw request body as a string.

=head2 query_string

    my $qs = $req->query_string;

Returns the raw query string (without the leading C<?>).

=head2 param

    my $value = $req->param('name');
    my $all   = $req->param;

Get a named path parameter (from C<:name> in route definition).
Without arguments, returns the entire params hashref.

=head2 query_param

    my $value = $req->query_param('key');
    my $all   = $req->query_param;

Get a query string parameter. Without arguments, returns the entire
query params hashref.

=head2 header

    my $value = $req->header('Content-Type');
    my $value = $req->header('content_type');  # Normalized
    my $all   = $req->header;

Get an HTTP header value. Header names are normalized to
C<lowercase_underscore> format internally. Without arguments,
returns the entire headers hashref.

=head2 cookie

    my $value = $req->cookie('session_id');
    my $all   = $req->cookie;

Get a cookie value by name. Without arguments, returns the entire
cookies hashref.

=head2 json

    my $data = $req->json;

Returns the parsed JSON body as a Perl data structure.
Requires C<< parse_json => 1 >> route option for JIT optimization.

=head2 form_param

    my $value = $req->form_param('field');
    my $all   = $req->form_param;

Get a form field value (from C<application/x-www-form-urlencoded> body).
Without arguments, returns the entire form data hashref.
Requires C<< parse_form => 1 >> route option.

=head2 segments

    my $segs = $req->segments;  # ['users', '42']

Returns an arrayref of path segments.

=head2 id

    my $id = $req->id;

Returns the last path segment. Legacy method for simple C</resource/:id>
patterns.

=head2 is_json

    if ($req->is_json) { ... }

Returns true if the Content-Type header indicates JSON.

=head2 is_form

    if ($req->is_form) { ... }

Returns true if the Content-Type header indicates form-urlencoded data.

=head1 SESSION METHODS

These methods provide session access when sessions are enabled via
C<< $server->session_config() >>. See L<Hypersonic::Session> for details.

=head2 session

    # Get a session value
    my $user = $req->session('user');

    # Set a session value
    $req->session('user', 'alice');
    $req->session('logged_in', 1);

Get or set a session value. When called with one argument, returns the
value. When called with two arguments, sets the value and marks the
session as modified.

=head2 session_data

    my $data = $req->session_data;
    # { user => 'alice', logged_in => 1, _created => 1234567890 }

Returns the entire session data hashref.

=head2 session_clear

    $req->session_clear;

Clears all session data. The session cookie will still be sent, but
the data will be empty.

=head2 session_regenerate

    my $new_id = $req->session_regenerate;

Regenerates the session ID. This is a security best practice after
authentication (login) to prevent session fixation attacks. The
session data is preserved.

=head1 RESPONSE HELPERS

These methods create response hashrefs for convenience:

=head2 json_response

    return $req->json_response({ data => 'value' });
    return $req->json_response({ data => 'value' }, 201);

Create a JSON response with optional status code.

=head2 text_response

    return $req->text_response("Hello World");
    return $req->text_response("Created", 201);

Create a plain text response.

=head2 html_response

    return $req->html_response("<h1>Hello</h1>");

Create an HTML response.

=head2 redirect

    return $req->redirect('/new-location');
    return $req->redirect('/new-location', 301);

Create a redirect response (default 302).

=head2 error

    return $req->error("Something went wrong", 500);

Create an error response.

=head2 not_found

    return $req->not_found("User not found");

Create a 404 response.

=head2 bad_request

    return $req->bad_request("Invalid input");

Create a 400 response.

=head2 unauthorized

    return $req->unauthorized("Invalid token");

Create a 401 response.

=head2 forbidden

    return $req->forbidden("Access denied");

Create a 403 response.

=head1 SLOT CONSTANTS

For maximum performance, you can access slots directly:

    use Hypersonic::Request qw(
        SLOT_METHOD SLOT_PATH SLOT_BODY SLOT_PARAMS
        SLOT_QUERY SLOT_QUERY_STRING SLOT_HEADERS
        SLOT_COOKIES SLOT_JSON SLOT_FORM SLOT_SEGMENTS
    );

    # Direct array access (fastest)
    my $method = $req->[SLOT_METHOD];
    my $params = $req->[SLOT_PARAMS];

=head1 JIT OPTIMIZATION

Hypersonic analyzes your handlers and only generates parsing code for
features actually used. Explicitly enable features for clarity:

    $server->get('/search' => sub {
        my ($req) = @_;
        my $q = $req->query_param('q');
        return $req->json_response({ query => $q });
    }, {
        dynamic       => 1,
        parse_query   => 1,    # Generate query parsing code
    });

    $server->post('/api/users' => sub {
        my ($req) = @_;
        my $data = $req->json;
        my $auth = $req->header('Authorization');
        return $req->json_response({ ok => 1 });
    }, {
        dynamic       => 1,
        parse_json    => 1,    # Generate JSON parsing code
        parse_headers => 1,    # Generate header parsing code
    });

=head1 SEE ALSO

L<Hypersonic> - Main HTTP server module

L<Hypersonic::Response> - Fluent response builder

L<XS::JIT> - The JIT compiler

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
