#!perl

use 5.010;
use strict;
use warnings;

use Games::Word::Wordlist::KBBI;
use Test::More 0.98;

my $wl = Games::Word::Wordlist::KBBI->new;
ok( $wl->is_word("mawar"));
ok(!$wl->is_word("foo"));
done_testing;
