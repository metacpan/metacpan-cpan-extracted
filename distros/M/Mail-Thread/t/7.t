#!perl -w
BEGIN { require 't/common.pl' }

use Test::More tests => 2;
use_ok("Mail::Thread");

my $threader = new Mail::Thread(slurp_messages 't/testbox-7');
$threader->thread;

is($threader->rootset, 1, "We have one main thread");
