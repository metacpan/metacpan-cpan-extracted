#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Devel::XRay');
}

use Devel::XRay 'only' => qw(test);

