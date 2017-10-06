#!perl -T

use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
    use_ok('Locale::Utils::PluralForms');
}
