package Digest::MurmurHash3::PurePerl;
use strict;
use warnings;
use 5.008008;
use base 'Exporter';

our $VERSION = '1.01';

our @EXPORT = qw(murmur32 murmur128);

sub murmur32 {
    my ( $key, $seed ) = @_;
    if ( !defined $seed ) {
        $seed = 0;
    }

    utf8::encode($key);
    my $len        = length($key);
    my $num_blocks = int( $len / 4 );
    my $tail_len   = $len % 4;
    my @vals       = unpack 'V*C*', $key;
    my @tail       = splice( @vals, scalar(@vals) - $tail_len, $tail_len );
    my $h1         = $seed;

    for my $block (@vals) {
        my $k1 = $block;
        $h1 ^= _mmix32($k1);
        $h1 = _rotl32( $h1, 13 );
        use integer;
        $h1 = _to_uint32( $h1 * 5 + 0xe6546b64 );
    }

    if ( $tail_len > 0 ) {
        my $k1 = 0;
        for my $c1 ( reverse @tail ) {
            $k1 = ( ( $k1 << 8 ) | $c1 );
        }
        $k1 = _mmix32($k1);
        $h1 = ( $h1 ^ $k1 );
    }
    $h1 = ( $h1 ^ $len );
    $h1 = _fmix32($h1);
    return $h1;
}

sub murmur128 {
    my ( $key, $seed ) = @_;
    if ( !defined $seed ) {
        $seed = 0;
    }
    my ( $h1, $h2, $h3, $h4 ) = ( $seed, $seed, $seed, $seed );

    my $c1 = 0x239b961b;
    my $c2 = 0xab0e9789;
    my $c3 = 0x38b34ae5;
    my $c4 = 0xa1e38b93;

    utf8::encode($key);
    my $len        = length($key);
    my $num_blocks = int( $len / 16 );
    my @vals       = unpack 'V*C*', $key;
    my ( $k1, $k2, $k3, $k4 );

    use integer;

    for ( my $i = 0; $i < $num_blocks; $i++ ) {
        $k1 = $vals[ $i * 4 + 0 ];
        $k2 = $vals[ $i * 4 + 1 ];
        $k3 = $vals[ $i * 4 + 2 ];
        $k4 = $vals[ $i * 4 + 3 ];

        $k1 = _to_uint32( $k1 * $c1 );
        $k1 = _rotl32( $k1, 15 );
        $k1 = _to_uint32( $k1 * $c2 );
        $h1 ^= $k1;
        $h1 = _rotl32( $h1, 19 );
        $h1 = _to_uint32( $h1 + $h2 );
        $h1 = _to_uint32( $h1 * 5 + 0x561ccd1b );

        $k2 = _to_uint32( $k2 * $c2 );
        $k2 = _rotl32( $k2, 16 );
        $k2 = _to_uint32( $k2 * $c3 );
        $h2 ^= $k2;
        $h2 = _rotl32( $h2, 17 );
        $h2 = _to_uint32( $h2 + $h3 );
        $h2 = _to_uint32( $h2 * 5 + 0x0bcaa747 );

        $k3 = _to_uint32( $k3 * $c3 );
        $k3 = _rotl32( $k3, 17 );
        $k3 = _to_uint32( $k3 * $c4 );
        $h3 ^= $k3;
        $h3 = _rotl32( $h3, 15 );
        $h3 = _to_uint32( $h3 + $h4 );
        $h3 = _to_uint32( $h3 * 5 + 0x96cd1c35 );

        $k4 = _to_uint32( $k4 * $c4 );
        $k4 = _rotl32( $k4, 18 );
        $k4 = _to_uint32( $k4 * $c1 );
        $h4 ^= $k4;
        $h4 = _rotl32( $h4, 13 );
        $h4 = _to_uint32( $h4 + $h1 );
        $h4 = _to_uint32( $h4 * 5 + 0x32ac3b17 );
    }

    my $tail_len = $len % 16;
    my @tail;
    my $sblock_num = int( $tail_len / 4 );
    for ( my $i = 0; $i < $sblock_num; $i++ ) {
        my @tmp = unpack 'C4', pack( 'V', $vals[ $num_blocks * 4 + $i ] );
        push @tail, @tmp;
    }
    for ( my $i = $num_blocks * 4 + $sblock_num; $i < scalar(@vals); $i++ ) {
        push @tail, $vals[$i];
    }

    $k1 = 0;
    $k2 = 0;
    $k3 = 0;
    $k4 = 0;

    {
        my $len_lo4 = $len & 0x0F;
        if ( $len_lo4 == 15 ) { $k4 ^= $tail[14] << 16; }
        if ( $len_lo4 >= 14 ) { $k4 ^= $tail[13] << 8; }
        if ( $len_lo4 >= 13 ) {
            
            $k4 ^= $tail[12] << 0;
            $k4 = _to_uint32( $k4 * $c4 );
            $k4 = _rotl32( $k4, 18 );
            $k4 = _to_uint32( $k4 * $c1 );
            $h4 ^= $k4;
        }
        if ( $len_lo4 >= 12 ) { $k3 ^= $tail[11] << 24; }
        if ( $len_lo4 >= 11 ) { $k3 ^= $tail[10] << 16; }
        if ( $len_lo4 >= 10 ) { $k3 ^= $tail[9] << 8; }
        if ( $len_lo4 >= 9 ) {
            $k3 ^= $tail[8] << 0;
            $k3 = _to_uint32( $k3 * $c3 );
            $k3 = _rotl32( $k3, 17 );
            $k3 = _to_uint32( $k3 * $c4 );
            $h3 ^= $k3;
        }

        if ( $len_lo4 >= 8 ) { $k2 ^= $tail[7] << 24; }
        if ( $len_lo4 >= 7 ) { $k2 ^= $tail[6] << 16; }
        if ( $len_lo4 >= 6 ) { $k2 ^= $tail[5] << 8; }
        if ( $len_lo4 >= 5 ) {
            $k2 ^= $tail[4] << 0;
            $k2 = _to_uint32( $k2 * $c2 );
            $k2 = _rotl32( $k2, 16 );
            $k2 = _to_uint32( $k2 * $c3 );
            $h2 ^= $k2;
        }
        if ( $len_lo4 >= 4 ) { $k1 ^= $tail[3] << 24; }
        if ( $len_lo4 >= 3 ) { $k1 ^= $tail[2] << 16; }
        if ( $len_lo4 >= 2 ) { $k1 ^= $tail[1] << 8; }
        if ( $len_lo4 >= 1 ) {
            $k1 ^= $tail[0] << 0;
            $k1 = _to_uint32( $k1 * $c1 );
            $k1 = _rotl32( $k1, 15 );
            $k1 = _to_uint32( $k1 * $c2 );
            $h1 ^= $k1;
        }

        $h1 ^= $len;
        $h2 ^= $len;
        $h3 ^= $len;
        $h4 ^= $len;

        $h1 = _to_uint32( $h1 + $h2 );
        $h1 = _to_uint32( $h1 + $h3 );
        $h1 = _to_uint32( $h1 + $h4 );
        $h2 = _to_uint32( $h2 + $h1 );
        $h3 = _to_uint32( $h3 + $h1 );
        $h4 = _to_uint32( $h4 + $h1 );

        $h1 = _fmix32($h1);
        $h2 = _fmix32($h2);
        $h3 = _fmix32($h3);
        $h4 = _fmix32($h4);

        $h1 = _to_uint32( $h1 + $h2 );
        $h1 = _to_uint32( $h1 + $h3 );
        $h1 = _to_uint32( $h1 + $h4 );
        $h2 = _to_uint32( $h2 + $h1 );
        $h3 = _to_uint32( $h3 + $h1 );
        $h4 = _to_uint32( $h4 + $h1 );
    }
    return ( $h1, $h2, $h3, $h4 );
}

sub _rotl32 {
    my ( $x, $r ) = @_;
    return ( ( $x << $r ) | ( $x >> ( 32 - $r ) ) );
}

sub _fmix32 {
    my $h = shift;
    $h = ( $h ^ ( $h >> 16 ) );
    {
        use integer;
        $h = _to_uint32( $h * 0x85ebca6b );
    }
    $h = ( $h ^ ( $h >> 13 ) );
    {
        use integer;
        $h = _to_uint32( $h * 0xc2b2ae35 );
    }
    $h = ( $h ^ ( $h >> 16 ) );
    return $h;
}

sub _mmix32 {
    my $k1 = shift;
    use integer;
    $k1 = _to_uint32( $k1 * 0xcc9e2d51 );
    $k1 = _rotl32( $k1, 15 );
    return _to_uint32( $k1 * 0x1b873593 );
}

sub _to_uint32 {
    no integer;
    return $_[0] & 0xFFFFFFFF;
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Digest::MurmurHash3::PurePerl - Pure perl implementation of MurmurHash3

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Digest::MurmurHash3::PurePerl;

  # Calculate hash value without seed
  my $hash = murmur32($data);
  my @hashes = murmur128($data);
  
  # Calculate hash value with seed
  $hash = murmur32($data, $seed);
  @hashes = murmur128($data, $seed);
  

=head1 DESCRIPTION

Digest::MurmurHash3::PurePerl is pure perl implementation of MurmurHash3.

=head1 METHODS

=head2 $h = murmur32($data [, $seed])

Calculates 32-bit hash value.

=head2 ($v1,$v2,$v3,v4) = murmur128($data [, $seed])

Calculates 128-bit hash value.

It returns four element list of 32-bit integers.

=head1 SEE ALSO

L<Digest::MurmurHash3>

=head1 AUTHOR

Hideaki Ohno  E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
