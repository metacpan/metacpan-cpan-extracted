use strict;
use warnings;

use Test::Simple tests => 11;

use Farly::IPv4::ICMPType;

my $all = Farly::IPv4::ICMPType->new( -1 );
my $t1 = Farly::IPv4::ICMPType->new("0");
my $t2 = Farly::IPv4::ICMPType->new("8");
my $t3 = Farly::IPv4::ICMPType->new("8");

ok ( $t2->compare( $t3 ) == 0, "compare equal");

ok ( $all->compare( $t1 ) == -1, "compare less than");

ok ( $t2->compare( $t1 ) == 1, "compare greater than");

ok( $all->contains($t2), "all contains" );

ok( !$t1->contains($t2), "!contains" );

ok( $t2->contains($t3), "contains" );

ok( !$t1->equals($t2), "!equals" );

ok( $t2->equals($t3), "equals" );

ok( $t2->intersects($all), "intersects" );

ok( $t2->intersects($t3), "intersects" );

ok( ! $t1->intersects($t2), "!intersects" );