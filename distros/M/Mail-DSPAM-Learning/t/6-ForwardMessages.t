#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Mail::DSPAM::Learning;

*STDOUT = *STDERR;

my $dspam_learner = Mail::DSPAM::Learning->new();

$dspam_learner->setDelay(1);

my $fakeMyConfigFile = 't/MyConfig.pm';

ok($dspam_learner->defineMyConfig($fakeMyConfigFile), "Creating MyConfig works");

require t::MyConfig;

my $spam_mailbox = "examples/mbox";
warn "\tParsing Mailbox\n";

$dspam_learner->setMailbox($spam_mailbox);

ok($dspam_learner->parseMailbox() , 'parse Mailbox work');

ok($dspam_learner->setMyConfig, "Setting MyConfig in the DSPAM Learner works");

my $c = $dspam_learner->forwardMessages(0);

warn "\n\t $c messages have been sent\n\n";

ok($c == 3, "Forward Messages works");

