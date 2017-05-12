#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Mail::DSPAM::Learning;

*STDOUT = *STDERR;

my $dspam_learner = Mail::DSPAM::Learning->new();

my $fakeMyConfigFile = 't/MyConfig.pm';

$dspam_learner->defineMyConfig($fakeMyConfigFile);

ok(require t::MyConfig, "Loading MyConfig Module works");

ok($dspam_learner->setMyConfig, "Setting MyConfig in the DSPAM Learner works");

ok($dspam_learner->printMyConfig, "Printing MyConfig information works");

