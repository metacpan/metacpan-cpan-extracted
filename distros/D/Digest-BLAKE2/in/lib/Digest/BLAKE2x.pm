# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
package Digest::BLAKE2x;
use strict;
use warnings;

our $VERSION = '0.02';  # FIXME

use parent qw/Exporter Digest::base/;
use XSLoader;

XSLoader::load __PACKAGE__, $VERSION;

our @EXPORT_OK = qw(
  blake2x blake2x_hex blake2x_base64 blake2x_base64url blake2x_ascii85
);

1;

=head1 NAME

Digest::BLAKE2x - Perl XS interface to the BLAKE2x algorithm

=head1 SYNOPSIS

    use Digest::BLAKE2x qw(blake2x blake2x_hex blake2x_base64 blake2x_base64url blake2x_ascii85);

    # blake2b
    print blake2x('Japan Break Industries');
    print blake2x_hex('Japan Break Industries');
    print blake2x_base64('Japan Break Industries');
    print blake2x_base64url('Japan Break Industries');
    print blake2x_ascii85('Japan Break Industries');

    # object interface provided by Digest::base
    my $b = Digest::BLAKE2x->new;
    $b->add('Japan Break Industries');
    print $b->digest;
    print $b->b64digest;

=head1 DESCRIPTION

The C<Digest::BLAKE2x> module provides an interface to the BLAKE2x message
digest algorithm.

The cryptographic hash function BLAKE2 is an improved version of the SHA-3 finalist BLAKE.
Like BLAKE or SHA-3, BLAKE2 offers the highest security, yet is fast as MD5 on 64-bit platforms and requires at least 33% less RAM than SHA-2 or SHA-3 on low-end systems.

BLAKE2 comes in two flavors.
BLAKE2b is optimized for 64-bit platforms—including NEON-enabled ARMs—and produces digests of any size between 1 and 64 bytes.
BLAKE2s is optimized for 8- to 32-bit platforms and produces digests of any size between 1 and 32 bytes.

This interface follows the conventions set forth by the C<Digest> module.

=head1 FUNCTIONS

None of these functions are exported by default.

=head2 blake2x($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE2x
digest encoded as a binary string.

=head2 blake2x_hex($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE2x
digest encoded as a hexadecimal string.

=head2 blake2x_base64($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE2x
digest encoded as a Base64 string, without any trailing padding.

=head2 blake2x_base64url($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE2x
digest encoded as a urlsafe Base64 string, without any trailing padding.

=head2 blake2x_ascii85($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE2x
digest encoded as a Ascii85 string, without any trailing padding.

=head1 SEE ALSO

C<Digest::BLAKE>

=head1 AUTHOR

Tasuku SUENAGA a.k.a. gunyarakun E<lt>tasuku-s-cpan ATAT titech.acE<gt>

=head1 LICENSE

Copyright (C) Tasuku SUENAGA a.k.a. gunyarakun

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
=cut
