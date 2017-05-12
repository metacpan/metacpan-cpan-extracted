#!perl

use 5.010;
use strict;
use warnings;

use Games::Word::Phraselist::Proverb::TWW;
use Test::More 0.98;

my $wl = Games::Word::Phraselist::Proverb::TWW->new;
ok( $wl->is_phrase("Actions speak louder than words."));
ok(!$wl->is_phrase("foo"));
done_testing;
