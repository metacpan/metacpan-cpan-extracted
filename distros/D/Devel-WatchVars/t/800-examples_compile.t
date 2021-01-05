#!/usr/bin/env perl

use Cwd qw(abs_path);
use FindBin;
use lib map { abs_path("$FindBin::Bin/../$_") } qw(t/lib lib);
use test_setup;

use Test::Script;

run_eponymous_test;

#################################################

sub test_examples_compile {

    my $APP_ROOT = abs_path "$FindBin::Bin/..";
    ok chdir($APP_ROOT), "chdir worked";

    for my $example (glob "examples/*.plx") {
        script_compiles $example;
        script_runs     $example;
    }

}

