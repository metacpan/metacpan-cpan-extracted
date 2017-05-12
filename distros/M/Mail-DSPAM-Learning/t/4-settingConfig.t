#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Mail::DSPAM::Learning;

use Data::Dumper;
use Module::TestConfig;

*STDOUT = *STDERR;

my $dspam_learner = Mail::DSPAM::Learning->new();

my $fakeMyConfigFile = 't/MyConfig.pm';

if ( -f $fakeMyConfigFile) {
    warn "\n\t$fakeMyConfigFile exists. Deleting for testing\n";
    unlink $fakeMyConfigFile;
} else {
    warn "\n\n$fakeMyConfigFile doesn't exists\n\n";
}

ok($dspam_learner->defineMyConfig($fakeMyConfigFile), "Creating MyConfig works");


