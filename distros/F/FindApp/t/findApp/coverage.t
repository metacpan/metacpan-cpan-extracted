#!/usr/bin/env perl

use t::setup;
use FindApp::Utils qw(
    :package
    :paths
);

sub minimal_coverage_tests {

    for my $module (grep /^FindApp\b/, modules_in_libdirs()) {
        my $modpath =        module2path($module);
        my $modtest = "t/" . module2test($module);
        ok(-e $modtest, "$modtest exists parallel to lib/$modpath");
    }
}

run_tests();
