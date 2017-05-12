#! perl -slw
use strict;
use Benchmark qw[ cmpthese ];
use Math::Int128 qw[ uint128 uint128_to_hex :op ];
use Math::GMPz qw[ Rmpz_init_set_str ];


sub FNV_1_128 {
    my $s = shift;
    my $h = uint128( '144066263297769815596495629667062367629' );
    my $p = uint128( '309485009821345068724781371' );
    $h *= $p, $h ^= $_ for unpack 'C*', $s;
    return $h;
}

sub FNV_1a_128 {
    my $s = shift;
    my $h = uint128( '144066263297769815596495629667062367629' );
    my $p = uint128( '309485009821345068724781371' );
    $h ^= $_, $h *= $p for unpack 'C*', $s;
    return $h;
}

our $h = uint128();
our $p = uint128();

sub FNV_1_128_pa {
    my $s = shift;
    uint128_set($h, '144066263297769815596495629667062367629' );
    uint128_set($p, '309485009821345068724781371' );
    $h *= $p, $h ^= $_ for unpack 'C*', $s;
    return $h;
}

sub FNV_1a_128_pa {
    my $s = shift;
    uint128_set($h, '144066263297769815596495629667062367629' );
    uint128_set($p, '309485009821345068724781371' );
    $h ^= $_, $h *= $p for unpack 'C*', $s;
    return $h;
}

sub FNV_1_128_gmpz {
    my $s = shift;
    my $h = Math::GMPz->new( '144066263297769815596495629667062367629' );
    my $p = Math::GMPz->new( '309485009821345068724781371' );
    my $m = Math::GMPz->new( 1 ) << 128;
    $h *= $p, $h ^= $_ for unpack 'C*', $s;
    return $h % $m;
}

sub FNV_1a_128_gmpz {
    my $s = shift;
    my $h = Math::GMPz->new( '144066263297769815596495629667062367629' );
    my $p = Math::GMPz->new( '309485009821345068724781371' );
    my $m = Math::GMPz->new( 1 ) << 128;
    $h ^= $_, $h *= $p for unpack 'C*', $s;
    return $h % $m;
}

sub FNV_1_128_gmpz2 {
    my $s = shift;
    my $h = Math::GMPz->new( '144066263297769815596495629667062367629' );
    my $p = Math::GMPz->new( '309485009821345068724781371' );
    my $m = Math::GMPz->new( 1 ) << 128;
    $h *= $p, $h ^= $_, $h %= $m for unpack 'C*', $s;
    return $h;
}

sub FNV_1a_128_gmpz2 {
    my $s = shift;
    my $h = Math::GMPz->new( '144066263297769815596495629667062367629' );
    my $p = Math::GMPz->new( '309485009821345068724781371' );
    my $m = Math::GMPz->new( 1 ) << 128;
    $h ^= $_, $h *= $p, $h %= $m for unpack 'C*', $s;
    return $h;
}

my $mod128_mask = (Math::GMPz->new( 1 ) << 128) - 1;

sub FNV_1_128_gmpz3 {
    my $s = shift;
    my $h = Math::GMPz->new( '144066263297769815596495629667062367629' );
    my $p = Math::GMPz->new( '309485009821345068724781371' );
    $h *= $p, $h &= $mod128_mask, $h ^= $_ for unpack 'C*', $s;
    return $h;
}

sub FNV_1a_128_gmpz3 {
    my $s = shift;
    my $h = Rmpz_init_set_str('144066263297769815596495629667062367629', 10);
    my $p = Rmpz_init_set_str('309485009821345068724781371', 10);
    $h ^= $_, $h *= $p, $h &= $mod128_mask for unpack 'C*', $s;
    return $h;
}

sub FNV_1_128_gmpz4 {
    my $s = shift;
    my $h = Math::GMPz->new( '144066263297769815596495629667062367629' );
    my $p = Math::GMPz->new( '309485009821345068724781371' );
    $h *= $p, $h ^= $_ for unpack 'C*', $s;
    return $h;
}

sub FNV_1a_128_gmpz4 {
    my $s = shift;
    my $h = Math::GMPz->new( '144066263297769815596495629667062367629' );
    my $p = Math::GMPz->new( '309485009821345068724781371' );
    $h ^= $_, $h *= $p for unpack 'C*', $s;
    return $h;
}


our $text = do{ local( @ARGV, $/ ) = $0; <> };
print length $text;

cmpthese -1, {
    int128 => q[
        my $fnv1  = uint128_to_hex( FNV_1_128( $text ) );
        my $fnv1a = uint128_to_hex( FNV_1a_128( $text ) );
    ],
    int128_pa => q[
        my $fnv1  = uint128_to_hex( FNV_1_128_pa( $text ) );
        my $fnv1a = uint128_to_hex( FNV_1a_128_pa( $text ) );
    ],
    GMPz => q[
        my $fnv1  = Math::GMPz::Rmpz_get_str( FNV_1_128_gmpz( $text ), 16 );
        my $fnv1a = Math::GMPz::Rmpz_get_str( FNV_1a_128_gmpz( $text ), 16 );
    ],
    GMPz2 => q[
        my $fnv1  = Math::GMPz::Rmpz_get_str( FNV_1_128_gmpz2( $text ), 16 );
        my $fnv1a = Math::GMPz::Rmpz_get_str( FNV_1a_128_gmpz2( $text ), 16 );
    ],
    GMPz3 => q[
        my $fnv1  = Math::GMPz::Rmpz_get_str( FNV_1_128_gmpz3( $text ), 16 );
        my $fnv1a = Math::GMPz::Rmpz_get_str( FNV_1a_128_gmpz3( $text ), 16 );
    ],
    GMPz4 => q[
        my $fnv1  = Math::GMPz::Rmpz_get_str( FNV_1_128_gmpz3( $text ), 16 );
        my $fnv1a = Math::GMPz::Rmpz_get_str( FNV_1a_128_gmpz3( $text ), 16 );
    ],
};

__END__
C:\test>FNV128.pl
2455
         Rate   GMPz  GMPz2 int128
GMPz   14.1/s     --   -77%   -95%
GMPz2  61.4/s   334%     --   -78%
int128  274/s  1840%   347%     --

