use strict;
use warnings;
use Test::More tests => 8;
use lib "../lib/";

use_ok('Math::Polynom');

my $p;
my $s;
my $w;

$p = Math::Polynom->new(1 => 2, 3 => 4);
$s = "4*x^3 + 2*x^1";
is($p->stringify, $s, "test stringifying [$s]");

$p = Math::Polynom->new(1 => 2, 3 => 4, 8 => 9);
$s = "9*x^8 + 4*x^3 + 2*x^1";
is($p->stringify, $s, "test stringifying [$s]");

$p = Math::Polynom->new(1 => 2, 3 => -4, 8 => 9);
$s = "9*x^8 + -4*x^3 + 2*x^1";
is($p->stringify, $s, "test stringifying [$s]");

$p = Math::Polynom->new(1 => 2, 3 => 0, 8 => 9);
$s = "9*x^8 + 2*x^1";
is($p->stringify, $s, "test stringifying [$s]");

$p = Math::Polynom->new(1 => 2, 0 => 4, 8 => 9);
$s = "9*x^8 + 2*x^1 + 4*x^0";
is($p->stringify, $s, "test stringifying [$s]");

$p = Math::Polynom->new(1 => 2, 5.657 => 4.3874, 8.4 => 9);
$s = "9*x^8.4 + 4.3874*x^5.657 + 2*x^1";
is($p->stringify, $s, "test stringifying [$s]");

$p = Math::Polynom->new();
$s = "";
is($p->stringify, $s, "test stringifying empty polynom");





