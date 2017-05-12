package Digest::SipHash::PP;
use strict;
use warnings;
use Math::BigInt;

our $VERSION = sprintf "%d.%02d", q$Revision: 0.12 $ =~ /(\d+)/g;
use base 'Exporter';
our @EXPORT_OK = qw/siphash siphash32/;

use constant USE64BITINT => eval { pack 'Q', 1 };
use constant MASK64 => Math::BigInt->new('0xffff_ffff_ffff_ffff');

push @EXPORT_OK, 'siphash64' if USE64BITINT;
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );
our $DEFAULT_SEED = pack 'C16', map { int( rand(256) ) } ( 0 .. 0xF );

sub _new { Math::BigInt->new(shift) }
sub _u64 { _new($_[1])->blsft(32)->bior($_[0]) }
sub _add { $_[0]->badd($_[1])->band(MASK64) }
sub _xor { $_[0]->bxor($_[1]) }
sub _rot {
    my $lo = $_[0]->copy->brsft(64 - $_[1]);
    $_[0]->blsft($_[1])->bior($lo)->band(MASK64);
}

sub _compress {
    _add( $_[0], $_[1] );
    _add( $_[2], $_[3] );
    _rot( $_[1], 13 );
    _rot( $_[3], 16 );
    _xor( $_[1], $_[0] );
    _xor( $_[3], $_[2] );
    _rot( $_[0], 32 );
    _add( $_[2], $_[1] );
    _add( $_[0], $_[3] );
    _rot( $_[1], 17 );
    _rot( $_[3], 21 );
    _xor( $_[1], $_[2] );
    _xor( $_[3], $_[0] );
    _rot( $_[2], 32 );
}

sub _digest {
    use bytes;
    my $str  = shift || '';
    my $seed = shift || "\0" x 16;
    my @k = unpack 'V4', $seed;
    my $k0 = _u64( @k[ 0, 1 ] );
    my $k1 = _u64( @k[ 2, 3 ] );
    my $v0 = _new('0x736f6d6570736575');
    my $v1 = _new('0x646f72616e646f6d');
    my $v2 = _new('0x6c7967656e657261');
    my $v3 = _new('0x7465646279746573');
    _xor( $v0, $k0 );
    _xor( $v1, $k1 );
    _xor( $v2, $k0 );
    _xor( $v3, $k1 );
    my $slen = length($str);
    $str .= "\0" x ( 7 - $slen % 8 ) . chr( $slen % 256 );
    my @u32 = unpack 'V*', $str;

    while ( my ( $lo, $hi ) = splice @u32, 0, 2 ) {
        my $u64 = _u64( $lo, $hi );
        _xor( $v3, $u64 );
        _compress( $v0, $v1, $v2, $v3 ) for 0 .. 1;
        _xor( $v0, $u64 );
    }
    _xor( $v2, 0xff );
    _compress( $v0, $v1, $v2, $v3 ) for 0 .. 3;
    _xor( _xor( $v0, $v1 ), _xor( $v2, $v3 ) );
}

sub siphash {
    my $u64 = _digest(@_);
    my $lo  = 0 + $u64->copy->band(0xffff_ffff);
    return $lo unless wantarray;
    my $hi  = 0 + $u64->brsft(32);
    return ( $lo, $hi );
}

*siphash32 = \&siphash;

if (USE64BITINT) {
    *siphash64 = sub {
        use integer;
        0+_digest(@_);
    };
}

1;

__END__

=head1 NAME

Digest::SipHash::PP - Pure-Perl implementation of the SipHash algorithm

=head1 VERSION

$Id: PP.pm,v 0.12 2013/02/28 03:18:03 dankogai Exp $

=head1 SYNOPSIS

  use Digest::SipHash::PP qw/siphash/;
  my $seed = pack 'C16', 0 .. 0xF;    # 16 chars long
  my $str = "hello world!";
  my ( $lo, $hi ) = siphash( $str, $seed );
  #  $lo = 0x10cf32e0, $hi == 0x7da9cd17
  my $u32 = siphash( $str, $seed )
  #  $u32 = 0x10cf32e0

  use Config;
  if ( $Config{use64bitint} ) {
    use Digest::SipHash qw/siphash64/;
    my $uint64 = siphash64( $str, $seed );    # scalar context;
    # $uint64 == 0x7da9cd1710cf32e0
  }

=head1 DESCRIPTION

This module is identical to L<Digest::SipHash> except implementation.
This module is not meant to be practical; written just for the sake of
curiosity.

=head2 IMPLEMENTATION

For the sake of 32-bit compatibility, this module uses L<Math::BigInt>
for 64-bit operations on which SipHash heavily relies.

=head1 EXPORT

C<siphash()>, C<siphash32()> and C<siphash64()> on demand.

C<:all> to all of above

=head1 SUBROUTINES/METHODS

=head2 siphash

=head2 siphash32

=head2 siphash64

See L<Digest::SipHash> for details.

=head1 AUTHOR

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dan Kogai.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut
