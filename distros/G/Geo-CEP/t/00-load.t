#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Geo::CEP));
};

diag(qq(Geo::CEP v$Geo::CEP::VERSION, Perl $], $^X));
