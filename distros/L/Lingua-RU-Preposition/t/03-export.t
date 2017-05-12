#!perl -T

use utf8;
use Test::More 'no_plan';

use Lingua::RU::Preposition qw/:all/;

ok( choose_preposition_by_next_word('о', 'ухе') eq 'об', 'sub with long name' );
ok( ko('всем') eq 'ко', 'alias' );

