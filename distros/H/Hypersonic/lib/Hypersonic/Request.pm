package Hypersonic::Request;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.03';

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

# Generate and compile XS accessors
sub compile_accessors {
    my ($class, %opts) = @_;

    return if $COMPILED;

    my $cache_dir = $opts{cache_dir} // '_hypersonic_request_cache';
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

    # Compile via XS::JIT
    XS::JIT->compile(
        code      => $builder->code,
        name      => $module_name,
        cache_dir => $cache_dir,
        functions => {
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
        },
    );

    $COMPILED = 1;
    return 1;
}

# Session methods - implemented in Perl because they need to interact
# with the session store. JIT overhead isn't worth it for session access.

# Get or set a session value
# $req->session('key')          - get value
# $req->session('key', $value)  - set value
sub session {
    my $self = shift;
    require Hypersonic::Session;
    return Hypersonic::Session::get_set($self, @_);
}

# Get all session data
sub session_data {
    my $self = shift;
    require Hypersonic::Session;
    return Hypersonic::Session::get_all($self);
}

# Clear the session
sub session_clear {
    my $self = shift;
    require Hypersonic::Session;
    return Hypersonic::Session::clear($self);
}

# Regenerate session ID (for security after login)
sub session_regenerate {
    my $self = shift;
    require Hypersonic::Session;
    return Hypersonic::Session::regenerate($self);
}

# Response helper methods (still pure Perl - they just return hashrefs)
# These are lightweight enough that JIT overhead isn't worth it

sub json_response {
    my ($self, $data, $status) = @_;
    require JSON::XS;
    return {
        status  => $status // 200,
        headers => { 'Content-Type' => 'application/json' },
        body    => JSON::XS::encode_json($data),
    };
}

sub text_response {
    my ($self, $text, $status) = @_;
    return {
        status  => $status // 200,
        headers => { 'Content-Type' => 'text/plain' },
        body    => $text,
    };
}

sub html_response {
    my ($self, $html, $status) = @_;
    return {
        status  => $status // 200,
        headers => { 'Content-Type' => 'text/html' },
        body    => $html,
    };
}

sub redirect {
    my ($self, $url, $status) = @_;
    return {
        status  => $status // 302,
        headers => { 'Location' => $url },
        body    => '',
    };
}

sub error {
    my ($self, $message, $status) = @_;
    $message //= 'Internal Server Error';
    $status //= 500;
    return {
        status  => $status,
        headers => { 'Content-Type' => 'application/json' },
        body    => qq({"error":"$message"}),
    };
}

sub not_found {
    my ($self, $message) = @_;
    return $self->error($message // 'Not Found', 404);
}

sub bad_request {
    my ($self, $message) = @_;
    return $self->error($message // 'Bad Request', 400);
}

sub unauthorized {
    my ($self, $message) = @_;
    return $self->error($message // 'Unauthorized', 401);
}

sub forbidden {
    my ($self, $message) = @_;
    return $self->error($message // 'Forbidden', 403);
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
