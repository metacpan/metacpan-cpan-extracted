#!perl -T

use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::MO::File');
}
