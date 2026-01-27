package Hypersonic::Response;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.03';

# JIT-compiled Response object using array-based slots for maximum speed
# Generates XS accessors at compile time via XS::JIT::Builder

use XS::JIT;
use XS::JIT::Builder;

# Response slots (array indices)
use constant {
    SLOT_STATUS   => 0,
    SLOT_HEADERS  => 1,   # HV* of headers
    SLOT_BODY     => 2,
    SLOT_COOKIES  => 3,   # AV* of cookie strings
    SLOT_COUNT    => 4,
};

# Export slot constants for direct access
use Exporter 'import';
our @EXPORT_OK = qw(
    SLOT_STATUS SLOT_HEADERS SLOT_BODY SLOT_COOKIES SLOT_COUNT
    res
);

# Shortcut constructor for use in handlers
sub res { __PACKAGE__->new(@_) }

my $COMPILED = 0;
my $MODULE_ID = 0;

# Generate and compile XS accessors
sub compile_accessors {
    my ($class, %opts) = @_;

    return if $COMPILED;

    my $cache_dir = $opts{cache_dir} // '_hypersonic_response_cache';
    my $module_name = 'Hypersonic::Response::Accessors_' . $MODULE_ID++;

    my $builder = XS::JIT::Builder->new;

    # Generate read-only accessors for simple slots
    $builder->op_ro_accessor('jit_get_status', SLOT_STATUS);
    $builder->op_ro_accessor('jit_get_body', SLOT_BODY);
    $builder->op_ro_accessor('jit_get_headers_hv', SLOT_HEADERS);
    $builder->op_ro_accessor('jit_get_cookies_av', SLOT_COOKIES);

    # Generate status setter (returns $self for chaining)
    $builder->xs_function('jit_set_status')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->if('items > 1')
        ->line('SvREFCNT_dec(ary[' . SLOT_STATUS . ']);')
        ->line('ary[' . SLOT_STATUS . '] = newSVsv(ST(1));')
      ->endif
      ->line('ST(0) = ST(0);')
      ->xs_return('1')
      ->xs_end;

    # Generate body setter (returns $self for chaining)
    $builder->xs_function('jit_set_body')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->if('items > 1')
        ->line('SvREFCNT_dec(ary[' . SLOT_BODY . ']);')
        ->line('ary[' . SLOT_BODY . '] = newSVsv(ST(1));')
      ->endif
      ->line('ST(0) = ST(0);')
      ->xs_return('1')
      ->xs_end;

    # Generate single header setter (returns $self for chaining)
    $builder->xs_function('jit_set_header')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->if('items > 2')
        ->line('STRLEN klen;')
        ->line('const char* key = SvPV(ST(1), klen);')
        ->line('SV* val = newSVsv(ST(2));')
        ->line('hv_store(headers, key, klen, val, 0);')
      ->endif
      ->line('ST(0) = ST(0);')
      ->xs_return('1')
      ->xs_end;

    # Generate header getter
    $builder->xs_function('jit_get_header')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->if('items > 1')
        ->line('STRLEN klen;')
        ->line('const char* key = SvPV(ST(1), klen);')
        ->line('SV** val = hv_fetch(headers, key, klen, 0);')
        ->line('ST(0) = val && *val ? *val : &PL_sv_undef;')
      ->else
        ->line('ST(0) = newRV_inc((SV*)headers);')
      ->endif
      ->xs_return('1')
      ->xs_end;

    # Generate add cookie (pushes to cookies array, returns $self)
    $builder->xs_function('jit_add_cookie')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('AV* cookies = (AV*)SvRV(ary[' . SLOT_COOKIES . ']);')
      ->if('items > 1')
        ->line('av_push(cookies, newSVsv(ST(1)));')
      ->endif
      ->line('ST(0) = ST(0);')
      ->xs_return('1')
      ->xs_end;

    # Generate cookies count
    $builder->xs_function('jit_cookies_count')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('AV* cookies = (AV*)SvRV(ary[' . SLOT_COOKIES . ']);')
      ->line('ST(0) = sv_2mortal(newSViv(av_len(cookies) + 1));')
      ->xs_return('1')
      ->xs_end;

    # Generate cookie at index
    $builder->xs_function('jit_cookie_at')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('AV* cookies = (AV*)SvRV(ary[' . SLOT_COOKIES . ']);')
      ->if('items > 1')
        ->line('IV idx = SvIV(ST(1));')
        ->line('SV** val = av_fetch(cookies, idx, 0);')
        ->line('ST(0) = val && *val ? *val : &PL_sv_undef;')
      ->else
        ->line('ST(0) = &PL_sv_undef;')
      ->endif
      ->xs_return('1')
      ->xs_end;

    # ============================================================
    # JIT-compiled fluent API methods (return $self for chaining)
    # ============================================================

    # JIT text() - sets Content-Type: text/plain + body
    $builder->xs_function('jit_text')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->if('items > 1')
        ->line('hv_store(headers, "Content-Type", 12, newSVpv("text/plain", 10), 0);')
        ->line('SvREFCNT_dec(ary[' . SLOT_BODY . ']);')
        ->line('ary[' . SLOT_BODY . '] = newSVsv(ST(1));')
      ->endif
      ->line('ST(0) = ST(0);')
      ->xs_return('1')
      ->xs_end;

    # JIT html() - sets Content-Type: text/html + body
    $builder->xs_function('jit_html')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->if('items > 1')
        ->line('hv_store(headers, "Content-Type", 12, newSVpv("text/html", 9), 0);')
        ->line('SvREFCNT_dec(ary[' . SLOT_BODY . ']);')
        ->line('ary[' . SLOT_BODY . '] = newSVsv(ST(1));')
      ->endif
      ->line('ST(0) = ST(0);')
      ->xs_return('1')
      ->xs_end;

    # JIT xml() - sets Content-Type: application/xml + body
    $builder->xs_function('jit_xml')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->if('items > 1')
        ->line('hv_store(headers, "Content-Type", 12, newSVpv("application/xml", 15), 0);')
        ->line('SvREFCNT_dec(ary[' . SLOT_BODY . ']);')
        ->line('ary[' . SLOT_BODY . '] = newSVsv(ST(1));')
      ->endif
      ->line('ST(0) = ST(0);')
      ->xs_return('1')
      ->xs_end;

    # JIT content_type() - sets Content-Type header
    $builder->xs_function('jit_content_type')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->if('items > 1')
        ->line('hv_store(headers, "Content-Type", 12, newSVsv(ST(1)), 0);')
      ->endif
      ->line('ST(0) = ST(0);')
      ->xs_return('1')
      ->xs_end;

    # JIT redirect() - sets status + Location header
    $builder->xs_function('jit_redirect')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->if('items > 1')
        ->line('hv_store(headers, "Location", 8, newSVsv(ST(1)), 0);')
        ->line('SvREFCNT_dec(ary[' . SLOT_STATUS . ']);')
        # Check items > 2 AND ST(2) is defined (not undef)
        ->if('items > 2 && SvOK(ST(2))')
          ->line('ary[' . SLOT_STATUS . '] = newSVsv(ST(2));')
        ->else
          ->line('ary[' . SLOT_STATUS . '] = newSViv(302);')
        ->endif
      ->endif
      ->line('ST(0) = ST(0);')
      ->xs_return('1')
      ->xs_end;

    # ============================================================
    # JIT-compiled to_http() - direct HTTP response string in C
    # This is the highest-impact optimization for dynamic routes
    # ============================================================
    $builder->xs_function('jit_to_http')
      ->xs_preamble
      ->line('SV** ary = AvARRAY((AV*)SvRV(ST(0)));')
      ->line('IV status = SvIV(ary[' . SLOT_STATUS . ']);')
      ->line('HV* headers = (HV*)SvRV(ary[' . SLOT_HEADERS . ']);')
      ->line('AV* cookies = (AV*)SvRV(ary[' . SLOT_COOKIES . ']);')
      ->line('STRLEN body_len;')
      ->line('const char* body = SvPV(ary[' . SLOT_BODY . '], body_len);')
      ->line('')
      ->line('/* Status line lookup table */')
      ->line('const char* status_text;')
      ->line('switch(status) {')
      ->line('  case 200: status_text = "OK"; break;')
      ->line('  case 201: status_text = "Created"; break;')
      ->line('  case 204: status_text = "No Content"; break;')
      ->line('  case 301: status_text = "Moved Permanently"; break;')
      ->line('  case 302: status_text = "Found"; break;')
      ->line('  case 304: status_text = "Not Modified"; break;')
      ->line('  case 307: status_text = "Temporary Redirect"; break;')
      ->line('  case 308: status_text = "Permanent Redirect"; break;')
      ->line('  case 400: status_text = "Bad Request"; break;')
      ->line('  case 401: status_text = "Unauthorized"; break;')
      ->line('  case 403: status_text = "Forbidden"; break;')
      ->line('  case 404: status_text = "Not Found"; break;')
      ->line('  case 409: status_text = "Conflict"; break;')
      ->line('  case 422: status_text = "Unprocessable Entity"; break;')
      ->line('  case 429: status_text = "Too Many Requests"; break;')
      ->line('  case 500: status_text = "Internal Server Error"; break;')
      ->line('  case 502: status_text = "Bad Gateway"; break;')
      ->line('  case 503: status_text = "Service Unavailable"; break;')
      ->line('  case 504: status_text = "Gateway Timeout"; break;')
      ->line('  default: status_text = "Unknown"; break;')
      ->line('}')
      ->line('')
      ->line('/* Calculate total size needed */')
      ->line('SSize_t total_size = 64; /* Status line overhead */')
      ->line('total_size += body_len;')
      ->line('total_size += 32; /* Content-Length header */')
      ->line('')
      ->line('/* Iterate headers to calculate size */')
      ->line('HE* entry;')
      ->line('hv_iterinit(headers);')
      ->line('while ((entry = hv_iternext(headers))) {')
      ->line('  I32 klen;')
      ->line('  const char* key = hv_iterkey(entry, &klen);')
      ->line('  SV* val = hv_iterval(headers, entry);')
      ->line('  STRLEN vlen;')
      ->line('  SvPV(val, vlen);')
      ->line('  total_size += klen + vlen + 4; /* key: value\\r\\n */')
      ->line('}')
      ->line('')
      ->line('/* Add cookies size */')
      ->line('SSize_t ncookies = av_len(cookies) + 1;')
      ->line('for (SSize_t i = 0; i < ncookies; i++) {')
      ->line('  SV** cv = av_fetch(cookies, i, 0);')
      ->line('  if (cv && *cv) {')
      ->line('    STRLEN clen;')
      ->line('    SvPV(*cv, clen);')
      ->line('    total_size += 14 + clen + 2; /* Set-Cookie: ... \\r\\n */')
      ->line('  }')
      ->line('}')
      ->line('')
      ->line('/* Build response string */')
      ->line('SV* result = newSV(total_size + 4);')
      ->line('SvPOK_on(result);')
      ->line('char* p = SvPVX(result);')
      ->line('')
      ->line('/* Status line */')
      ->line('p += sprintf(p, "HTTP/1.1 %d %s\\r\\n", (int)status, status_text);')
      ->line('')
      ->line('/* Headers */')
      ->line('hv_iterinit(headers);')
      ->line('while ((entry = hv_iternext(headers))) {')
      ->line('  I32 klen;')
      ->line('  const char* key = hv_iterkey(entry, &klen);')
      ->line('  SV* val = hv_iterval(headers, entry);')
      ->line('  STRLEN vlen;')
      ->line('  const char* vp = SvPV(val, vlen);')
      ->line('  memcpy(p, key, klen); p += klen;')
      ->line('  *p++ = \':\'; *p++ = \' \';')
      ->line('  memcpy(p, vp, vlen); p += vlen;')
      ->line('  *p++ = \'\\r\'; *p++ = \'\\n\';')
      ->line('}')
      ->line('')
      ->line('/* Cookies */')
      ->line('for (SSize_t i = 0; i < ncookies; i++) {')
      ->line('  SV** cv = av_fetch(cookies, i, 0);')
      ->line('  if (cv && *cv) {')
      ->line('    STRLEN clen;')
      ->line('    const char* cookie = SvPV(*cv, clen);')
      ->line('    memcpy(p, "Set-Cookie: ", 12); p += 12;')
      ->line('    memcpy(p, cookie, clen); p += clen;')
      ->line('    *p++ = \'\\r\'; *p++ = \'\\n\';')
      ->line('  }')
      ->line('}')
      ->line('')
      ->line('/* Content-Length and blank line */')
      ->line('p += sprintf(p, "Content-Length: %lu\\r\\n\\r\\n", (unsigned long)body_len);')
      ->line('')
      ->line('/* Body */')
      ->line('memcpy(p, body, body_len);')
      ->line('p += body_len;')
      ->line('')
      ->line('SvCUR_set(result, p - SvPVX(result));')
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return('1')
      ->xs_end;

    # Compile via XS::JIT
    XS::JIT->compile(
        code      => $builder->code,
        name      => $module_name,
        cache_dir => $cache_dir,
        functions => {
            # Status
            'Hypersonic::Response::_jit_get_status' => { source => 'jit_get_status', is_xs_native => 1 },
            'Hypersonic::Response::_jit_set_status' => { source => 'jit_set_status', is_xs_native => 1 },

            # Body
            'Hypersonic::Response::_jit_get_body' => { source => 'jit_get_body', is_xs_native => 1 },
            'Hypersonic::Response::_jit_set_body' => { source => 'jit_set_body', is_xs_native => 1 },

            # Headers
            'Hypersonic::Response::_jit_get_headers_hv' => { source => 'jit_get_headers_hv', is_xs_native => 1 },
            'Hypersonic::Response::_jit_set_header'     => { source => 'jit_set_header', is_xs_native => 1 },
            'Hypersonic::Response::_jit_get_header'     => { source => 'jit_get_header', is_xs_native => 1 },

            # Cookies
            'Hypersonic::Response::_jit_get_cookies_av' => { source => 'jit_get_cookies_av', is_xs_native => 1 },
            'Hypersonic::Response::_jit_add_cookie'     => { source => 'jit_add_cookie', is_xs_native => 1 },
            'Hypersonic::Response::_jit_cookies_count'  => { source => 'jit_cookies_count', is_xs_native => 1 },
            'Hypersonic::Response::_jit_cookie_at'      => { source => 'jit_cookie_at', is_xs_native => 1 },

            # Fluent API methods (JIT-compiled)
            'Hypersonic::Response::_jit_text'         => { source => 'jit_text', is_xs_native => 1 },
            'Hypersonic::Response::_jit_html'         => { source => 'jit_html', is_xs_native => 1 },
            'Hypersonic::Response::_jit_xml'          => { source => 'jit_xml', is_xs_native => 1 },
            'Hypersonic::Response::_jit_content_type' => { source => 'jit_content_type', is_xs_native => 1 },
            'Hypersonic::Response::_jit_redirect'     => { source => 'jit_redirect', is_xs_native => 1 },

            # Direct HTTP response generation
            'Hypersonic::Response::_jit_to_http'      => { source => 'jit_to_http', is_xs_native => 1 },
        },
    );

    $COMPILED = 1;
    return 1;
}

# Constructor - creates array-based response object
sub new {
    my ($class, %opts) = @_;

    # Compile accessors if not already done
    $class->compile_accessors(cache_dir => $opts{cache_dir}) unless $COMPILED;

    my $self = bless [], $class;

    # Initialize slots
    $self->[SLOT_STATUS]  = $opts{status} // 200;
    $self->[SLOT_HEADERS] = $opts{headers} // {};
    $self->[SLOT_BODY]    = $opts{body} // '';
    $self->[SLOT_COOKIES] = [];

    return $self;
}

# Fluent API methods - all return $self for chaining
# Core methods use JIT-compiled XS for maximum speed when available

# Set HTTP status code (JIT-compiled when available)
sub status {
    my ($self, $code) = @_;
    if ($COMPILED && defined $code) {
        return $self->_jit_set_status($code);
    }
    $self->[SLOT_STATUS] = $code if defined $code;
    return $self;
}

# Set a response header (JIT-compiled when available)
sub header {
    my ($self, $name, $value) = @_;
    if ($COMPILED) {
        return $self->_jit_set_header($name, $value);
    }
    $self->[SLOT_HEADERS]{$name} = $value;
    return $self;
}

# Set multiple headers at once
sub headers {
    my ($self, %headers) = @_;
    if ($COMPILED) {
        $self->_jit_set_header($_, $headers{$_}) for keys %headers;
    } else {
        $self->[SLOT_HEADERS]{$_} = $headers{$_} for keys %headers;
    }
    return $self;
}

# Set response body (JIT-compiled when available)
sub body {
    my ($self, $content) = @_;
    if ($COMPILED) {
        return $self->_jit_set_body($content);
    }
    $self->[SLOT_BODY] = $content;
    return $self;
}

# Set JSON response (auto-sets Content-Type and encodes data)
sub json {
    my ($self, $data) = @_;
    require JSON::XS;
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/json';
    $self->[SLOT_BODY] = JSON::XS::encode_json($data);
    return $self;
}

# Set plain text response (JIT-compiled when available)
sub text {
    my ($self, $content) = @_;
    if ($COMPILED) {
        return $self->_jit_text($content);
    }
    $self->[SLOT_HEADERS]{'Content-Type'} = 'text/plain';
    $self->[SLOT_BODY] = $content;
    return $self;
}

# Set HTML response (JIT-compiled when available)
sub html {
    my ($self, $content) = @_;
    if ($COMPILED) {
        return $self->_jit_html($content);
    }
    $self->[SLOT_HEADERS]{'Content-Type'} = 'text/html';
    $self->[SLOT_BODY] = $content;
    return $self;
}

# Set XML response (JIT-compiled when available)
sub xml {
    my ($self, $content) = @_;
    if ($COMPILED) {
        return $self->_jit_xml($content);
    }
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/xml';
    $self->[SLOT_BODY] = $content;
    return $self;
}

# Set redirect response (JIT-compiled when available)
sub redirect {
    my ($self, $url, $code) = @_;
    if ($COMPILED) {
        return $self->_jit_redirect($url, $code);
    }
    $self->[SLOT_STATUS] = $code // 302;
    $self->[SLOT_HEADERS]{'Location'} = $url;
    return $self;
}

# Set a cookie
sub cookie {
    my ($self, $name, $value, %opts) = @_;

    my $cookie = "$name=$value";
    $cookie .= "; Path=$opts{path}"         if defined $opts{path};
    $cookie .= "; Domain=$opts{domain}"     if defined $opts{domain};
    $cookie .= "; Max-Age=$opts{max_age}"   if defined $opts{max_age};
    $cookie .= "; Expires=$opts{expires}"   if defined $opts{expires};
    $cookie .= "; HttpOnly"                 if $opts{httponly};
    $cookie .= "; Secure"                   if $opts{secure};
    $cookie .= "; SameSite=$opts{samesite}" if defined $opts{samesite};

    push @{$self->[SLOT_COOKIES]}, $cookie;
    return $self;
}

# Clear a cookie (set to expire immediately)
sub clear_cookie {
    my ($self, $name, %opts) = @_;
    return $self->cookie($name, '', max_age => 0, %opts);
}

# Set Content-Type header directly (JIT-compiled when available)
sub content_type {
    my ($self, $type) = @_;
    if ($COMPILED) {
        return $self->_jit_content_type($type);
    }
    $self->[SLOT_HEADERS]{'Content-Type'} = $type;
    return $self;
}

# Set Cache-Control header
sub cache {
    my ($self, $directive) = @_;
    $self->[SLOT_HEADERS]{'Cache-Control'} = $directive;
    return $self;
}

# Disable caching
sub no_cache {
    my ($self) = @_;
    $self->[SLOT_HEADERS]{'Cache-Control'} = 'no-store, no-cache, must-revalidate';
    $self->[SLOT_HEADERS]{'Pragma'} = 'no-cache';
    return $self;
}

# Set ETag header
sub etag {
    my ($self, $value) = @_;
    $self->[SLOT_HEADERS]{'ETag'} = qq("$value");
    return $self;
}

# Set Last-Modified header
sub last_modified {
    my ($self, $time) = @_;
    $self->[SLOT_HEADERS]{'Last-Modified'} = _http_date($time);
    return $self;
}

# Set Content-Disposition for file downloads
sub attachment {
    my ($self, $filename) = @_;
    if (defined $filename) {
        $self->[SLOT_HEADERS]{'Content-Disposition'} = qq(attachment; filename="$filename");
    } else {
        $self->[SLOT_HEADERS]{'Content-Disposition'} = 'attachment';
    }
    return $self;
}

# Convenience: 201 Created with optional Location header
sub created {
    my ($self, $location) = @_;
    $self->[SLOT_STATUS] = 201;
    $self->[SLOT_HEADERS]{'Location'} = $location if defined $location;
    return $self;
}

# Convenience: 204 No Content
sub no_content {
    my ($self) = @_;
    $self->[SLOT_STATUS] = 204;
    $self->[SLOT_BODY] = '';
    return $self;
}

# Convenience: 400 Bad Request
sub bad_request {
    my ($self, $message) = @_;
    $self->[SLOT_STATUS] = 400;
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/json';
    $self->[SLOT_BODY] = _json_error($message // 'Bad Request');
    return $self;
}

# Convenience: 401 Unauthorized
sub unauthorized {
    my ($self, $message) = @_;
    $self->[SLOT_STATUS] = 401;
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/json';
    $self->[SLOT_BODY] = _json_error($message // 'Unauthorized');
    return $self;
}

# Convenience: 403 Forbidden
sub forbidden {
    my ($self, $message) = @_;
    $self->[SLOT_STATUS] = 403;
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/json';
    $self->[SLOT_BODY] = _json_error($message // 'Forbidden');
    return $self;
}

# Convenience: 404 Not Found
sub not_found {
    my ($self, $message) = @_;
    $self->[SLOT_STATUS] = 404;
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/json';
    $self->[SLOT_BODY] = _json_error($message // 'Not Found');
    return $self;
}

# Convenience: 409 Conflict
sub conflict {
    my ($self, $message) = @_;
    $self->[SLOT_STATUS] = 409;
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/json';
    $self->[SLOT_BODY] = _json_error($message // 'Conflict');
    return $self;
}

# Convenience: 422 Unprocessable Entity
sub unprocessable {
    my ($self, $message) = @_;
    $self->[SLOT_STATUS] = 422;
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/json';
    $self->[SLOT_BODY] = _json_error($message // 'Unprocessable Entity');
    return $self;
}

# Convenience: 429 Too Many Requests
sub too_many_requests {
    my ($self, $retry_after) = @_;
    $self->[SLOT_STATUS] = 429;
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/json';
    $self->[SLOT_HEADERS]{'Retry-After'} = $retry_after if defined $retry_after;
    $self->[SLOT_BODY] = _json_error('Too Many Requests');
    return $self;
}

# Convenience: 500 Internal Server Error
sub server_error {
    my ($self, $message) = @_;
    $self->[SLOT_STATUS] = 500;
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/json';
    $self->[SLOT_BODY] = _json_error($message // 'Internal Server Error');
    return $self;
}

# Convenience: 503 Service Unavailable
sub unavailable {
    my ($self, $retry_after) = @_;
    $self->[SLOT_STATUS] = 503;
    $self->[SLOT_HEADERS]{'Content-Type'} = 'application/json';
    $self->[SLOT_HEADERS]{'Retry-After'} = $retry_after if defined $retry_after;
    $self->[SLOT_BODY] = _json_error('Service Unavailable');
    return $self;
}

# Convert to hashref for Hypersonic handler return
sub finalize {
    my ($self) = @_;

    my $headers = { %{$self->[SLOT_HEADERS]} };

    # Add Set-Cookie headers
    if (@{$self->[SLOT_COOKIES]}) {
        # Store cookies as arrayref for multiple Set-Cookie headers
        $headers->{'Set-Cookie'} = $self->[SLOT_COOKIES];
    }

    return {
        status  => $self->[SLOT_STATUS],
        headers => $headers,
        body    => $self->[SLOT_BODY],
    };
}

# Direct HTTP response string generation (JIT-compiled when available)
# This bypasses the intermediate hashref for maximum performance
# Returns a complete HTTP response string ready to send
sub to_http {
    my ($self) = @_;
    if ($COMPILED) {
        return $self->_jit_to_http();
    }
    # Fallback to Perl implementation
    return $self->_perl_to_http();
}

# Pure Perl fallback for to_http
sub _perl_to_http {
    my ($self) = @_;

    my $status = $self->[SLOT_STATUS];
    my %status_text = (
        200 => 'OK', 201 => 'Created', 204 => 'No Content',
        301 => 'Moved Permanently', 302 => 'Found', 304 => 'Not Modified',
        307 => 'Temporary Redirect', 308 => 'Permanent Redirect',
        400 => 'Bad Request', 401 => 'Unauthorized', 403 => 'Forbidden',
        404 => 'Not Found', 409 => 'Conflict', 422 => 'Unprocessable Entity',
        429 => 'Too Many Requests', 500 => 'Internal Server Error',
        502 => 'Bad Gateway', 503 => 'Service Unavailable', 504 => 'Gateway Timeout',
    );

    my $resp = "HTTP/1.1 $status " . ($status_text{$status} // 'Unknown') . "\r\n";

    # Headers
    my $headers = $self->[SLOT_HEADERS];
    for my $key (keys %$headers) {
        $resp .= "$key: $headers->{$key}\r\n";
    }

    # Cookies
    for my $cookie (@{$self->[SLOT_COOKIES]}) {
        $resp .= "Set-Cookie: $cookie\r\n";
    }

    # Content-Length and body
    my $body = $self->[SLOT_BODY];
    $resp .= "Content-Length: " . length($body) . "\r\n\r\n";
    $resp .= $body;

    return $resp;
}

# Allow using Response object directly as return value (auto-finalize)
sub TO_JSON {
    my ($self) = @_;
    return $self->finalize;
}

# Helper: format HTTP date
sub _http_date {
    my ($time) = @_;
    $time //= time();
    my @t = gmtime($time);
    my @days = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    return sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
        $days[$t[6]], $t[3], $months[$t[4]], $t[5]+1900, $t[2], $t[1], $t[0]);
}

# Helper: format JSON error
sub _json_error {
    my ($message) = @_;
    $message =~ s/"/\\"/g;  # Escape quotes
    return qq({"error":"$message"});
}

1;

__END__

=head1 NAME

Hypersonic::Response - Fluent response builder for Hypersonic

=head1 SYNOPSIS

    use Hypersonic;
    use Hypersonic::Response 'res';

    my $server = Hypersonic->new();

    # Using the res() shortcut
    $server->get('/users/:id' => sub {
        my ($req) = @_;
        my $id = $req->param('id');
        
        return res->json({ id => $id, name => "User $id" });
    });

    # Full fluent API
    $server->post('/users' => sub {
        my ($req) = @_;
        my $data = $req->json;
        
        return res
            ->status(201)
            ->header('X-Request-Id', 'abc123')
            ->json({ created => $data->{name} })
            ->cookie('session', 'token123', httponly => 1, secure => 1);
    }, { parse_json => 1 });

    # Error responses
    $server->get('/admin/:id' => sub {
        my ($req) = @_;
        my $token = $req->header('Authorization');
        
        return res->unauthorized('Invalid token') unless $token;
        return res->not_found('User not found')   unless $user;
        return res->json($user);
    });

    # Redirect
    $server->get('/old-path' => sub {
        return res->redirect('/new-path', 301);
    }, { dynamic => 1 });

    # Explicit finalize() (usually not needed)
    $server->get('/explicit' => sub {
        my ($req) = @_;
        return res->json({ ok => 1 })->finalize;
    }, { dynamic => 1 });

=head1 DESCRIPTION

C<Hypersonic::Response> provides a fluent (chainable) API for building HTTP
responses. All methods return C<$self> to enable chaining.

The response object uses JIT-compiled array-based storage for maximum
performance, similar to L<Hypersonic::Request>.

=head1 EXPORTS

=head2 res

    use Hypersonic::Response 'res';
    
    return res->json({ data => 'value' });

Shortcut constructor for cleaner handler code. Equivalent to
C<< Hypersonic::Response->new() >>.

=head1 CONSTRUCTOR

=head2 new

    my $res = Hypersonic::Response->new();
    my $res = Hypersonic::Response->new(
        status  => 201,
        headers => { 'X-Custom' => 'value' },
        body    => 'Hello',
    );

Create a new Response object. All options are optional:

=over 4

=item status

Initial HTTP status code (default: 200)

=item headers

Initial headers hashref

=item body

Initial response body

=item cache_dir

Directory for JIT compilation cache

=back

=head1 METHODS

All setter methods return C<$self> for chaining.

=head2 status

    $res->status(201);
    $res->status(404);

Set the HTTP status code.

=head2 header

    $res->header('Content-Type', 'application/json');
    $res->header('X-Request-Id', $id);

Set a single response header.

=head2 headers

    $res->headers(
        'X-Request-Id' => $id,
        'X-Custom'     => 'value',
    );

Set multiple headers at once.

=head2 body

    $res->body('Hello, World!');
    $res->body($html_content);

Set the response body.

=head2 json

    $res->json({ status => 'ok', data => $data });
    $res->json([ 1, 2, 3 ]);

Set JSON response. Automatically:

=over 4

=item * Sets Content-Type to C<application/json>

=item * Encodes the data structure to JSON

=back

Requires L<JSON::XS>.

=head2 text

    $res->text('Plain text content');

Set plain text response (Content-Type: text/plain).

=head2 html

    $res->html('<h1>Hello</h1>');

Set HTML response (Content-Type: text/html).

=head2 xml

    $res->xml('<root><item/></root>');

Set XML response (Content-Type: application/xml).

=head2 content_type

    $res->content_type('image/png');

Set the Content-Type header directly.

=head2 redirect

    $res->redirect('/new-location');          # 302 Found
    $res->redirect('/new-location', 301);     # 301 Moved Permanently
    $res->redirect('/new-location', 307);     # 307 Temporary Redirect

Set redirect response with Location header.

=head2 cookie

    $res->cookie('session', $token);
    $res->cookie('session', $token,
        path     => '/',
        domain   => '.example.com',
        max_age  => 3600,           # Seconds
        expires  => $http_date,     # HTTP date string
        httponly => 1,              # Not accessible via JavaScript
        secure   => 1,              # HTTPS only
        samesite => 'Strict',       # Strict, Lax, or None
    );

Set a cookie with optional attributes.

=head2 clear_cookie

    $res->clear_cookie('session');
    $res->clear_cookie('session', path => '/');

Clear a cookie by setting it to expire immediately.

=head2 cache

    $res->cache('public, max-age=3600');

Set the Cache-Control header.

=head2 no_cache

    $res->no_cache;

Disable caching with appropriate headers.

=head2 etag

    $res->etag($checksum);

Set the ETag header.

=head2 last_modified

    $res->last_modified($timestamp);   # Unix timestamp
    $res->last_modified(time());

Set the Last-Modified header (auto-formats to HTTP date).

=head2 attachment

    $res->attachment('report.pdf');

Set Content-Disposition for file download.

=head1 CONVENIENCE METHODS

These set both status code and body for common responses:

=head2 created

    $res->created('/users/42');   # 201 with Location header

=head2 no_content

    $res->no_content;             # 204 No Content

=head2 bad_request

    $res->bad_request;                     # 400
    $res->bad_request('Invalid input');    # 400 with message

=head2 unauthorized

    $res->unauthorized;                    # 401
    $res->unauthorized('Invalid token');   # 401 with message

=head2 forbidden

    $res->forbidden;                       # 403
    $res->forbidden('Access denied');      # 403 with message

=head2 not_found

    $res->not_found;                       # 404
    $res->not_found('User not found');     # 404 with message

=head2 conflict

    $res->conflict;                        # 409
    $res->conflict('Already exists');      # 409 with message

=head2 unprocessable

    $res->unprocessable;                   # 422
    $res->unprocessable('Validation failed');

=head2 too_many_requests

    $res->too_many_requests;               # 429
    $res->too_many_requests(60);           # With Retry-After header

=head2 server_error

    $res->server_error;                    # 500
    $res->server_error('Database error');  # 500 with message

=head2 unavailable

    $res->unavailable;                     # 503
    $res->unavailable(300);                # With Retry-After header

=head1 FINALIZATION

=head2 finalize

    my $hashref = $res->finalize;

Convert the Response object to a hashref for returning from handlers.
Returns:

    {
        status  => 200,
        headers => { 'Content-Type' => 'application/json', ... },
        body    => '{"data":"value"}',
    }

B<Note:> Hypersonic automatically calls C<finalize()> when a Response
object is returned, so explicit finalization is usually not needed.

=head1 INTERNAL STRUCTURE

The response uses array-based storage:

    use Hypersonic::Response qw(SLOT_STATUS SLOT_HEADERS SLOT_BODY SLOT_COOKIES);

    # Direct slot access (advanced)
    $res->[SLOT_STATUS] = 200;
    $res->[SLOT_BODY]   = 'content';

=head1 EXAMPLES

=head2 REST API Response

    $server->post('/api/users' => sub {
        my ($req) = @_;
        my $data = $req->json;
        
        # Validation
        return res->bad_request('Name required')
            unless $data->{name};
        
        # Create user
        my $user = create_user($data);
        
        return res
            ->status(201)
            ->header('Location', "/api/users/$user->{id}")
            ->json($user);
    }, { parse_json => 1 });

=head2 Conditional Response

    $server->get('/api/resource/:id' => sub {
        my ($req) = @_;
        my $resource = get_resource($req->param('id'));
        
        return res->not_found unless $resource;
        
        return res
            ->etag($resource->{version})
            ->cache('private, max-age=60')
            ->json($resource);
    });

=head2 File Download

    $server->get('/download/:file' => sub {
        my ($req) = @_;
        my $file = $req->param('file');
        my $content = read_file($file);
        
        return res
            ->content_type('application/octet-stream')
            ->attachment($file)
            ->body($content);
    });

=head1 SEE ALSO

L<Hypersonic> - Main HTTP server module

L<Hypersonic::Request> - JIT-compiled request object

L<JSON::XS> - Required for JSON responses

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
