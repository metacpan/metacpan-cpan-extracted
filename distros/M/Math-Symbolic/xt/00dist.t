#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Test::Distribution; };
    if ($@) {
        plan skip_all => 'Test::Distribution not installed';
    }
    else {
        Test::Distribution->import( not => [qw(sig prereq podcover)] );
    }
}

