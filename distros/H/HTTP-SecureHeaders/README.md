[![Actions Status](https://github.com/kfly8/p5-HTTP-SecureHeaders/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/p5-HTTP-SecureHeaders/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-HTTP-SecureHeaders/main.svg?style=flat)](https://coveralls.io/r/kfly8/p5-HTTP-SecureHeaders?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/HTTP-SecureHeaders.svg)](https://metacpan.org/release/HTTP-SecureHeaders)
# NAME

HTTP::SecureHeaders - manage security headers with many safe defaults

# SYNOPSIS

```perl
use HTTP::SecureHeaders;
use Plack::Util;

my $secure_headers = HTTP::SecureHeaders->new(
    'content_security_policy' => "default-src 'self' https:",
);

my $data = [];
my $headers = Plack::Util::headers($data);

$secure_headers->apply($headers);

$data
# =>
#    'Content-Security-Policy'           => "default-src 'self' https:",
#    'Strict-Transport-Security'         => 'max-age=631138519',
#    'X-Content-Type-Options'            => 'nosniff',
#    'X-Download-Options'                => 'noopen',
#    'X-Frame-Options'                   => 'SAMEORIGIN',
#    'X-Permitted-Cross-Domain-Policies' => 'none',
#    'X-XSS-Protection'                  => '1; mode=block',
#    'Referrer-Policy'                   => 'strict-origin-when-cross-origin',
```

# DESCRIPTION

HTTP::SecureHeaders manages HTTP headers to protect against XSS attacks, insecure connections, content type sniffing, etc.

**NOTE**: To protect against these attacks, sanitization of user input values and other protections are also required.

# METHODS

## HTTP::SecureHeaders->new(%args)

Create an object that is a collection of secure headers that you wish to apply to the HTTP Header. Following headers are available and these values are the default values, refer to the following sites [https://github.com/github/secure\_headers#default-values](https://github.com/github/secure_headers#default-values).

```perl
my $secure_headers = HTTP::SecureHeaders->new(
    content_security_policy           => default-src 'self' https:; font-src 'self' https: data:; img-src 'self' https: data:; object-src 'none'; script-src https:; style-src 'self' https: 'unsafe-inline',
    strict_transport_security         => 'max-age=631138519',
    x_content_type_options            => 'nosniff',
    x_download_options                => 'noopen',
    x_frame_options                   => 'SAMEORIGIN',
    x_permitted_cross_domain_policies => 'none',
    x_xss_protection                  => '1; mode=block',
    referrer_policy                   => 'strict-origin-when-cross-origin',
);
```

## $self->apply($headers)

Apply the HTTP headers set in HTTP::SecureHeaders to $headers.
$headers must be HTTP::Headers or Plack::Util::headers ( HasMethods\['exists', 'get', 'set'\] ).

**NOTE**: HTTP header already set in $headers are not applied:

```perl
my $secure_headers = HTTP::SecureHeaders->new(
    'x_frame_options' => 'SAMEORIGIN',
);

my $res = Plack::Response->new;
$res->header('X-Frame-Options', 'DENY');

$secure_headers->apply($res->headers);
$res->header('X-Frame-Options') # => DENY / NOT SAMEORIGIN!
```

## NOTE

### Remove unnecessary HTTP header

For unnecessary HTTP header, use undef in the constructor.

```perl
my $secure_headers = HTTP::SecureHeaders->new(
    content_security_policy => undef,
)

my $res = Plack::Response->new;
$secure_headers->apply($res->headers);
$res->header('Content-Security-Policy'); # => undef
```

For temporarily unnecessary HTTP header, use OPT\_OUT:

```perl
my $secure_headers = HTTP::SecureHeaders->new();

my $res = Plack::Response->new;
$res->header('Content-Security-Policy', HTTP::SecureHeaders::OPT_OUT);

$secure_headers->apply($res->headers);
$res->header('Content-Security-Policy'); # => undef
```

**NOTE**: If you use undef instead of OPT\_OUT, HTTP::Headers cannot remove them.

```perl
my $secure_headers = HTTP::SecureHeaders->new();

my $res = Plack::Response->new;
$res->header('Content-Security-Policy', undef); # use undef instead of OPT_OUT

$secure_headers->apply($res->headers);
$res->header('Content-Security-Policy'); # => SAMEORIGIN / NO!!!
```

# SEE ALSO

- [Plack::Middleware::SecureHeaders](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3ASecureHeaders)
- [https://github.com/github/secure\_headers](https://github.com/github/secure_headers)
- [https://cheatsheetseries.owasp.org/cheatsheets/HTTP\_Headers\_Cheat\_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html)

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
