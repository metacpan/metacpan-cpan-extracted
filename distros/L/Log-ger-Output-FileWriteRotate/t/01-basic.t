#!perl

use strict;
use warnings;
use Test::More 0.98;

use File::Slurper qw(read_text);
use File::Temp qw(tempdir);
use Log::ger::Util;

package My::P1;
use Log::ger;

package main;

my $dir = tempdir(CLEANUP => 1);

subtest "basics" => sub {
    require Log::ger::Output;
    Log::ger::Output->set('FileWriteRotate', dir => $dir, prefix => "myapp");
    my $h = {}; Log::ger::init_target(hash => $h);

    $h->{warn}("line1");
    $h->{error}("line2");
    $h->{debug}("line3");
    is(read_text("$dir/myapp"), "line1\nline2\n");
};

done_testing;
