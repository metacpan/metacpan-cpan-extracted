use strict;
use warnings;
use Test::Simple tests => 22;

use Farly::IPv4::Range;
use Farly::IPv4::Address;

my $range0 = Farly::IPv4::Range->new("10.0.1.1 10.0.1.16");
my $range1 = Farly::IPv4::Range->new("10.0.1.1 10.0.1.16");
my $range2 = Farly::IPv4::Range->new("10.0.1.8 10.0.1.12");
my $range3 = Farly::IPv4::Range->new("10.0.1.15 10.0.1.31");
my $range4 = Farly::IPv4::Range->new("10.0.1.32 10.0.1.47");
my $range5 = Farly::IPv4::Range->new("10.0.1.36 10.0.1.39");
my $range6 = Farly::IPv4::Range->new("10.0.1.32 10.0.1.39");

my $start = Farly::IPv4::Address->new("10.0.1.1");
my $end = Farly::IPv4::Address->new("10.0.1.16");

ok( $range0->compare($range1) == 0, "compare equal");
ok( $range1->compare($range3) == -1, "compare lt");
ok( $range4->compare($range3) == 1, "compare gt");
ok( $range6->compare($range4) == 1, "compare larger first 1");
ok( $range4->compare($range6) == -1, "compare larger first -1");

my @networks = $range1->as_network();
my $string;
foreach my $net ( sort { $a->compare($b) } @networks ) {
	$string .= $net->as_string()." ";
}

ok ( $string eq "10.0.1.1 10.0.1.2 255.255.255.254 10.0.1.4 255.255.255.252 10.0.1.8 255.255.255.248 10.0.1.16 ", "as_network");
ok ( $range1->first() == 167772417, "rangefirst");
ok ( $range1->last() == 167772432, "range last");
ok ( $range1->start()->equals( $start ), "range start");
ok ( $range1->end()->equals( $end ), "range end");
ok ( $range1->as_string() eq "10.0.1.1 10.0.1.16", "range as_string");
ok ( $range3->adjacent($range4), "range adjacent");
ok ( $range1->contains($range2), "range contains");
ok ( !$range2->contains($range1), "range !contains");
ok ( $range0->equals($range1), "range equals");  
ok ( !$range1->equals($range4), "range !equals");
ok ( $range3->gt($range2), "range gt");
ok ( $range2->lt($range3), "range lt");
ok ( $range1->size() == 16, "range size");
ok ( $range1->intersects( $range2 ), "range intersects 1");
ok ( $range4->intersects( $range5 ), "range intersects 2");
ok ( $range5->intersects( $range4 ), "range intersects 3");
