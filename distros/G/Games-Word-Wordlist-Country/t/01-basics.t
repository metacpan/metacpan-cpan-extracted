#!perl

use 5.010;
use strict;
use warnings;

use Games::Word::Wordlist::Country;
use Test::More 0.98;

my $wl = Games::Word::Wordlist::Country->new;
ok( $wl->is_word("indonesia"));
ok(!$wl->is_word("foo"));
done_testing;
