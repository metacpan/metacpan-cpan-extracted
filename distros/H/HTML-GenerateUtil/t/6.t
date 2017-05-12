
#########################

use Test::More tests => 2;
BEGIN { use_ok('HTML::GenerateUtil') };
use HTML::GenerateUtil qw(:consts escape_uri);
use Encode;
use strict;

# $\d variables start off magic until first used
#  or SvGETMAGIC called, but Test::More uses at
#  least 1. It's all messy in XS land

$_ = "test";
s/()()()()()(.*)/escape_uri($6)/e;
is($_, "test");
