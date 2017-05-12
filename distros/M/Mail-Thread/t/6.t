#!perl -w
BEGIN { require 't/common.pl' }

use Test::More tests => 2;
use_ok("Mail::Thread");

my $threader = new Mail::Thread(slurp_messages('t/testbox-6'));
$threader->thread;

ok(2, "Avoid loops at all cost");
