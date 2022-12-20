#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Test::More;

use FindBin;
my $context = require "$FindBin::Bin/mem.pl";
plan skip_all => "no ps" unless check_ps();

for (1..200000) {
    $context->eval('(function(data) { var x = data; })')->(sub { 1 });
}

1 while !$context->idle_notification;

cmp_ok get_rss(), '<', 50_000, 'functions are released';

done_testing;
