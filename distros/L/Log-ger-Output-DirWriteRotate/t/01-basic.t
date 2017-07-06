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
    Log::ger::Output->set('DirWriteRotate', path => $dir);
    my $h = {}; Log::ger::init_target(hash => $h);

    $h->{warn}("msg");
    $h->{error}("msg");
    $h->{debug}("x");
    my @f = glob "$dir/*";
    is(scalar @f, 2);
    is(read_text($f[0]), "msg");
    is(read_text($f[1]), "msg");
};

done_testing;
