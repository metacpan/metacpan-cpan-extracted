#!perl

use 5.010;
use strict;
use warnings;

use Games::Word::Phraselist::Proverb::KBBI;
use Test::More 0.98;

my $wl = Games::Word::Phraselist::Proverb::KBBI->new;
ok( $wl->is_phrase("ada gula ada semut"));
ok(!$wl->is_phrase("foo"));
done_testing;
