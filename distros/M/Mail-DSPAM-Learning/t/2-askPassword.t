#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Mail::DSPAM::Learning;

warn "\n\n\tRunning dspam-lean version " . $Mail::DSPAM::Learning::VERSION . "\n";

my $dspam_learner = Mail::DSPAM::Learning->new();

my $spam_mailbox = "examples/mbox";
warn "\tAsking and setting password\n";

close STDIN;
close STDOUT;
pipe STDIN, STDOUT;
print "test\n";

ok($dspam_learner->askPassword(),  'ask and set password  work');

