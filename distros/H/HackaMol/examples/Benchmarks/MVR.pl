#!/usr/bin/env perl
use Modern::Perl;
use Math::Vector::Real;
use Math::VectorReal;
use Time::HiRes qw(time);
use Benchmark qw(cmpthese);

my $v1aa = V( 1.1, 2.0, 3.1 );
my $v2aa = V( 2.1, 3.0, 1.1 );
my $dvaa = $v2aa - $v1aa;
my $distaa = sqrt( $dvaa * $dvaa );

my $v1bb = V( 1.1, 2.0, 3.1 );
my $v2bb = V( 2.1, 3.0, 1.1 );
my $distbb = $v1bb->dist($v2bb);

say "$distaa $distbb";

# NO XS
#         Rate  MVR  DEF
#MVR 1811594/s   -- -39%
#DEF 2958580/s  63%   --
# WITH XS
#         Rate  MVR  DEF
#MVR 2415459/s   -- -16%
#DEF 2890173/s  20%   --
#

cmpthese(
    2500000,
    {
        'VectorReal' => sub { my $v = vector( 1.1, 2.0, 3.1 ) },
        'MVR' => sub { my $v = V( 1.1, 2.0, 3.1 ) },
        'DEF' => sub { my $v = [ 1.1, 2.0, 3.1 ] },
    }
);

cmpthese(
    500000,
    {
        'MVR' => sub {
            my $v1 = V( 1.1, 2.0, 3.1 );
            my $v2 = V( 2.1, 3.0, 1.1 );
            my $dot = $v1 * $v2;
        },
        'DEF' => sub {
            my $v1 = [ 1.1, 2.0, 3.1 ];
            my $v2 = [ 2.1, 3.0, 1.1 ];
            my $dot = 0;
            $dot += $v1->[$_] * $v2->[$_] foreach 0 .. $#{$v1};
        },
    }
);

cmpthese(
    500000,
    {
        'MVR dot dist' => sub {
            my $v1 = V( 1.1, 2.0, 3.1 );
            my $v2 = V( 2.1, 3.0, 1.1 );
            my $dv = $v2 - $v1;
            my $dist = sqrt( $dv * $dv );
        },
        'MVR dist' => sub {
            my $v1 = V( 1.1, 2.0, 3.1 );
            my $v2 = V( 2.1, 3.0, 1.1 );
            my $dist = $v1->dist($v2);
        },
    }
);

my $v1a = V( 1.1, 2.0, 3.1 );
my $v2a = V( 2.1, 3.0, 1.1 );
my $dota = $v1a * $v2a;

my $v1b = [ 1.1, 2.0, 3.1 ];
my $v2b = [ 2.1, 3.0, 1.1 ];
my $dotb = 0;
$dotb += $v1b->[$_] * $v2b->[$_] foreach 0 .. $#{$v1b};

print "$dota $dotb\n";

print $_ . "\n" foreach @{$v1a};
print abs($v1a) . "\n";
