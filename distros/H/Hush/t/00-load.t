#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    my @mods = qw/Hush Hush::List Hush::RPC Hush::Util Hush::Contact/;
    map { use_ok($_) } @mods;
}

done_testing;
