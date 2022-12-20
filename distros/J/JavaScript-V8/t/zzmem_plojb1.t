#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Test::More;
plan skip_all => 'apparent memory-leak, fixes welcome';

use FindBin;
my $context = require "$FindBin::Bin/mem.pl";
plan skip_all => "no ps" unless check_ps();

package Test;

sub new {
    my ($class, $val) = @_;
    bless { val => $val }, $class
}

package main;

for (1..100000) {
    $context->eval('(function(data) { var x = data; })')->(Test->new($_));
}

1 while !$context->idle_notification;

cmp_ok get_rss(), '<', 50_000, 'objects are released';

done_testing;
