# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
package Digest::BLAKE2;
use strict;
use warnings;

our $VERSION = '0.02';

use parent qw/Exporter Digest::base/;

use Digest::BLAKE2b
  qw/blake2b blake2b_hex blake2b_base64 blake2b_base64url blake2b_ascii85/;
use Digest::BLAKE2s
  qw/blake2s blake2s_hex blake2s_base64 blake2s_base64url blake2s_ascii85/;

#use Digest::BLAKE2bp
#    qw/blake2bp blake2bp_hex blake2bp_base64 blake2bp_base64url blake2bp_ascii85/;
#use Digest::BLAKE2sp
#    qw/blake2sp blake2sp_hex blake2sp_base64 blake2sp_base64url blake2sp_ascii85/;

our @EXPORT_OK = qw/
  blake2b blake2b_hex blake2b_base64 blake2b_base64url blake2b_ascii85
  blake2s blake2s_hex blake2s_base64 blake2s_base64url blake2s_ascii85
  /;

#    blake2bp blake2bp_hex blake2bp_base64 blake2bp_base64url blake2bp_ascii85
#    blake2sp blake2sp_hex blake2sp_base64 blake2sp_base64url blake2sp_ascii85

sub new {
    my ($class, $algorithm) = @_;
    $algorithm ||= 'b';
    unless ($algorithm =~ /^(blake2|BLAKE2)?((b|s)p?)$/) {
        die 'Invalid algorithm.';
    }
    bless +{
        instance => "Digest::BLAKE2$2"->new,
    }, $class;
}

sub clone {
    my $self = shift;
    $self->{instance}->clone(@_);
}

sub add {
    my $self = shift;
    $self->{instance}->add(@_);
}

sub digest {
    my $self = shift;
    $self->{instance}->digest(@_);
}

1;

=head1 NAME

Digest::BLAKE2 - Perl XS interface to the BLAKE2 algorithms

=head1 SYNOPSIS

    use Digest::BLAKE2 qw(blake2b blake2b_hex blake2b_base64 blake2b_base64url blake2b_ascii85);

    # blake2b
    print blake2b('Japan Break Industries');
    print blake2b_hex('Japan Break Industries');
    print blake2b_base64('Japan Break Industries');
    print blake2b_base64url('Japan Break Industries');
    print blake2b_ascii85('Japan Break Industries');

    # blake2s
    print Digest::BLAKE2::blake2s('Japan Break Industries');
    print Digest::BLAKE2::blake2s_hex('Japan Break Industries');
    print Digest::BLAKE2::blake2s_base64('Japan Break Industries');
    print Digest::BLAKE2::blake2s_base64url('Japan Break Industries');
    print Digest::BLAKE2::blake2s_ascii85('Japan Break Industries');

    # object interface provided by Digest::base
    my $b = Digest::BLAKE2->new('blake2s');
    $b->add('Japan Break Industries');
    print $b->digest;
    print $b->b64digest;

=head1 DESCRIPTION

The C<Digest::BLAKE2> module provides an interface to the BLAKE2 message
digest algorithm.

The cryptographic hash function BLAKE2 is an improved version of the SHA-3 finalist BLAKE.
Like BLAKE or SHA-3, BLAKE2 offers the highest security, yet is fast as MD5 on 64-bit platforms and requires at least 33% less RAM than SHA-2 or SHA-3 on low-end systems.

BLAKE2 comes in two flavors.
BLAKE2b is optimized for 64-bit platforms—including NEON-enabled ARMs—and produces digests of any size between 1 and 64 bytes.
BLAKE2s is optimized for 8- to 32-bit platforms and produces digests of any size between 1 and 32 bytes.

This interface follows the conventions set forth by the C<Digest> module.

=head1 FUNCTIONS

None of these functions are exported by default.

=head2 blake2b($data, ...)

=head2 blake2s($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE2
digest encoded as a binary string.

=head2 blake2b_hex($data, ...)

=head2 blake2s_hex($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE2
digest encoded as a hexadecimal string.

=head2 blake2b_base64($data, ...)

=head2 blake2s_base64($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE2
digest encoded as a Base64 string, without any trailing padding.

=head2 blake2b_base64url($data, ...)

=head2 blake2s_base64url($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE2
digest encoded as a urlsafe Base64 string, without any trailing padding.

=head2 blake2b_ascii85($data, ...)

=head2 blake2s_ascii85($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE2
digest encoded as a Ascii85 string, without any trailing padding.

=head1 SEE ALSO

C<Digest::BLAKE>

C<Digest::BLAKE2b>

C<Digest::BLAKE2s>

=head1 AUTHOR

Tasuku SUENAGA a.k.a. gunyarakun E<lt>tasuku-s-cpan ATAT titech.acE<gt>

=head1 LICENSE

Copyright (C) Tasuku SUENAGA a.k.a. gunyarakun

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
=cut
