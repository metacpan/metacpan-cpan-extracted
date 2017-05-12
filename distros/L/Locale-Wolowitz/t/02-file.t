#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 4;
use Locale::Wolowitz;

my $w = Locale::Wolowitz->new('t/i18n/rev_en.json');
ok($w, 'Got a proper Wolowitz object');

is($w->loc('hey man', 'rev_en'), 'nam yeh', 'en -> rev_en [1]');

is($w->loc('what\'s up %1?', 'rev_en', 'XO'), '?XO pu s\'tahw', 'en -> rev_en [2]');

is($w->loc('generic', 'rev_en'), 'eyb eyb', 'en -> rev_en [3]');

done_testing();
