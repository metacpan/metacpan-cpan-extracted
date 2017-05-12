#!perl

use 5.010;
use strict;
use warnings;

use Games::Word::Phraselist;
use Test::More 0.98;

my $pl = Games::Word::Phraselist->new(["foo bar", "foo baz"]);

is($pl->phrases, 2);

ok($pl->can("random_phrase"));

ok( $pl->is_phrase("foo baz"));
ok(!$pl->is_phrase("foo qux"));

ok($pl->can("each_phrase"));

is_deeply([$pl->phrases_like(qr/z/)], ["foo baz"]);

done_testing;
