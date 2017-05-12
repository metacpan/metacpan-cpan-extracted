#!/usr/bin/perl 

use strict;
use warnings;
use Test::More qw(no_plan);
use Log::Parallel::Sql::Trim;

my $finished = 0;

END { ok($finished, 'finished') }

my $s = q{I've been awake for a while now you've got me feelin like a child now cause every time I see your bubbly face I get the tinglies in a silly place It starts in my toes and I crinkle my nose where ever it goes I always know that you make me smile please stay fora while now just take your time where ever you go};

ok(length(encode_and_trim($s, 299)) < 300);

$finished = 1;
