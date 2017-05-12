#!perl -w
BEGIN { require 't/common.pl' }

use Test::More tests => 3;
use_ok("Mail::Thread");

# this tests multi-level pruning

my $threader = new Mail::Thread(slurp_messages('t/testbox-8'));
$threader->thread;

is($threader->rootset, 1, "We have one thread");

my @stuff;
dump_into( $threader => \@stuff );

deeply(\@stuff, [
    [ 0, 'Re: spamassassin', 'Pine.GSO.4.50.0303010015230.21567-100000@theproject.fierypit.org' ],
    [ 1, 'Re: spamassassin', '200303010143.h211hvD16626@rszemeti.demon.co.uk' ],
    [ 1, 'Re: spamassassin', '20030301102748.GC67225@colon.colondot.net' ],
   ], "It all works");

