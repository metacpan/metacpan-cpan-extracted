#!/usr/bin/env perl
# t/00-load.t
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('LightTCP::Server') or BAIL_OUT("Can't load LightTCP::Server");
}

done_testing;
