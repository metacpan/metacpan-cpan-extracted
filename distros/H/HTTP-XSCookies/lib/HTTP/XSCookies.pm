package HTTP::XSCookies;

use strict;
use warnings;

use XSLoader;
use parent 'Exporter';

our $VERSION = '0.000014';
XSLoader::load( 'HTTP::XSCookies', $VERSION );

our @EXPORT_OK = qw[bake_cookie crush_cookie];

1;

__END__

=pod

=encoding utf8

=head1 NAME

HTTP::XSCookies - Fast XS cookie mangling for Perl

=head1 VERSION

Version 0.000014

=head1 SYNOPSIS

    use HTTP::XSCookies qw/bake_cookie crush_cookie/;

    my $cookie = bake_cookie('Perl&C' => 'They rulez!');
    my $values = crush_cookie($cookie);

=head1 DESCRIPTION

This module implements cookie creation (baking) and parsing (crushing)
using XS, therefore improving the speed of a pure Perl implementation.

=head1 METHODS/ATTRIBUTES

=head2 bake_cookie

    my $cookie = bake_cookie('foo' => 'bar');

    my $cookie = bake_cookie('baz', {
        value   => 'Frodo',
        path    => 'myPath',
        domain  => '.test.com',
        expires => '+11h'
    });

Generate a cookie string with proper encoding. The first argument is
the cookie name; the second argument can be a string (the cookie value)
or a hashref with a set of key-value pairs.  These are the keys that
are recognized:

=over 4

=item * value: the cookie's value (a string).

=item * Domain: the cookie's domain (a string).

=item * Path: the cookie's path (a string).

=item * Max-Age: the cookie's maximum age (a string).

=item * Expires: the cookie's expiration date/time, in any of the
following formats:

    Expires => time + 3 * 60 * 60 # 3 hours from now
    Expires => 'Wed, 18-Sep-2016 22:33:44 GMT'  # fixed time
    Expires => '+20s' # 20 seconds from now
    Expires => '+40m' # 40 minutes from now
    Expires => '+2h'  # 2 hours from now
    Expires => '-3d'  # 3 days ago (i.e. "expired")
    Expires => '+4M'  # in 4 months
    Expires => '+8y'  # in 8 years
    Expires => 'now'  # right now

=item * Secure: whether the cookie is secure (a boolean, default is false).

=item * HttpOnly: whether the cookie is HTTP only (a boolean, default is false).

=item * SameSite: whether the cookie ought not to be sent along with cross-site requests (a string, either strict or lax, default is unset). See: L<https://tools.ietf.org/html/draft-west-first-party-cookies-07>.

=back

=head2 crush_cookie

    my $values = crush_cookie($cookie);

Parse a (properly encoded) cookie string into a hashref with the
individual values.

=head1 SEE ALSO

L<Cookie::Baker>.

=head1 LICENSE

Copyright (C) Gonzalo Diethelm.

This library is free software; you can redistribute it
and/or modify it under the terms of the MIT license.

=head1 AUTHOR

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=back

=head1 THANKS

=over 4

=item * Sawyer X C<< xsawyerx AT cpan DOT org >>.

=item * p5pclub, for the inspiration.

=back
