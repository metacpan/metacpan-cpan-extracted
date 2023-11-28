# NAME

HTTP::CSPHeader - manage dynamic content security policy headers

# VERSION

version v0.3.4

# SYNOPSIS

```perl
use HTTP::CSPheader;

my $csp = HTTP::CSPheader->new(
  policy => {
     "default-src" => q['self'],
     "script-src"  => q['self' cdn.example.com],
  },
  nonces_for => [qw/ script-src /],
);

...

use HTTP::Headers;

my $h = HTTP::Headers->new;

$csp->reset;

$csp->amend(
  "+script-src" => "https://captcha.example.com",
  "+style-src"  => "https://captcha.example.com",
);

my $nonce = $csp->nonce;
$h->header( 'Content-Security-Policy' => $csp->header );

my $body = ...

$body .= "<script nonce="${nonce}"> ... </script>";
```

# DESCRIPTION

This module allows you to manage Content-Security-Policy (CSP) headers.

It supports dynamic changes to headers, for example, adding a source
for a specific page, or managing a random nonce for inline scripts or
styles.

It also supports caching, so that the header will only be regenerated
if there is a change.

# ATTRIBUTES

## policy

This is a hash reference of policies.  The keys a directives, and the
values are sources.

There is no validation of these values.

## nonces\_for

This is an array reference of the directives to add a random ["nonce"](#nonce)
to when the ["policy"](#policy) is regenerated.

Note that the same nonce will be added to all of the directives, since
using separate nonces does not improve security.

It is emply by default.

A single value will be coerced to an array.

This does not validate the values.

Note that if a directive allows `'unsafe-inline'` then a nonce may
cancel out that value.

## nonce\_seed\_size

This is the size of the random seed data for the ["nonce"](#nonce). It can be an integer between 16 and 256.

## nonce

This is the random nonce that is added to directives in ["nonces\_for"](#nonces_for).

The nonce is a hex string based on a random 32-bit number, which is generated
from [Math::Random::ISAAC](https://metacpan.org/pod/Math%3A%3ARandom%3A%3AISAAC).  The RNG is seeded by [Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom).

If you want to change how it is generated, you can override the `_build_nonce`
method in a subclass.

Note that you should never make an assumption about the format of the
nonce, as the source may change in future versions.

## header

This is the value of the header, generated from the ["policy"](#policy).

This is a read-only accessor.

# METHODS

## reset

This resets any changes to the ["policy"](#policy) and clears the ["nonce"](#nonce).
It should be run at the start of each HTTP request.

If you never make use of the nonce, and never ["amend"](#amend) the headers,
then you do not need to run this method.

## amend

```perl
$csp->amend( $directive1 => $value1, $directive2 => $value2, ... );
```

This amends the ["policy"](#policy).

If the `$directive` starts with a `+` then the value will be
appended to it.  Otherwise the change will overwrite the value.

If the value is `undef`, then the directive will be deleted.

# EXAMPLES

## Mojolicious

You can use this with [Mojolicious](https://metacpan.org/pod/Mojolicious):

```perl
use HTTP::CSPHeader;

use feature 'state';

$self->hook(
  before_dispatch => sub ($c) {

    state $csp = HTTP::CSPHeader->new(
        policy => {
            'default-src' => q['self'],
            'script-src'  => q['self'],
        },
        nonces_for => 'script-src',
    );

    $csp->reset;

    $c->stash( csp_nonce => $csp->nonce );

    $c->res->headers->content_security_policy( $csp->header );
  }
);
```

and in your templates, you can use the following for inline scripts:

```
<script nonce="<%= $csp_nonce %>"> ... </script>
```

If you do not need the nonce, then you might consider using [Mojolicious::Plugin::CSPHeader](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ACSPHeader).

# SUPPORT FOR OLDER PERL VERSIONS

Since v0.2.0, the this module requires Perl v5.14 or later.

If you need this module on Perl v5.10, please use one of the v0.1.x
versions of this module.  Significant bug or security fixes may be
backported to those versions.

# SEE ALSO

[https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy)

[HTTP::SecureHeaders](https://metacpan.org/pod/HTTP%3A%3ASecureHeaders)

[Plack::Middleware::CSP](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3ACSP)

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-HTTP-CSPHeader](https://github.com/robrwo/perl-HTTP-CSPHeader)
and may be cloned from [git://github.com/robrwo/perl-HTTP-CSPHeader.git](git://github.com/robrwo/perl-HTTP-CSPHeader.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-HTTP-CSPHeader/issues](https://github.com/robrwo/perl-HTTP-CSPHeader/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
