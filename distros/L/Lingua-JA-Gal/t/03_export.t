use strict;
use warnings;
use utf8;
use Test::More tests => 1;

use Lingua::JA::Gal qw/gal/;

ok(gal(1), "gal() exported");
