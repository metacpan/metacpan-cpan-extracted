#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 17;
use Locale::Wolowitz;

my $w = Locale::Wolowitz->new('t/i18n');
ok($w, 'Got a proper Wolowitz object');

is($w->loc('hey man', 'en'), 'hey man', 'en -> en [1]');

is($w->loc('what\'s up %1?', 'en', 'XO'), 'what\'s up XO?', 'en -> en [2]');

is($w->loc('generic', 'en'), 'bye bye', 'en -> en [3]');

is($w->loc('hey man', 'he'), 'היי בן-אדם', 'en -> he [1]');

is($w->loc('what\'s up %1?', 'he', 'XO'), 'מה נשמע XO?', 'en -> he [2]');

is($w->loc('generic', 'he'), 'ביי ביי', 'en -> he [3]');

is($w->loc('hey man', 'xo'), 'yo bro', 'en -> xo [1]');

is($w->loc('what\'s up %1?', 'xo', 'XO'), 'how\'s it hangin\' XO?', 'en -> xo [2]');

is($w->loc('generic', 'xo'), 'see ya', 'en -> xo [3]');

is($w->loc('hey man', 'rev_en'), 'nam yeh', 'en -> rev_en [1]');

is($w->loc('what\'s up %1?', 'rev_en', 'XO'), '?XO pu s\'tahw', 'en -> rev_en [2]');

is($w->loc('generic', 'rev_en'), 'eyb eyb', 'en -> rev_en [3]');

is($w->loc('just english %1 and %2', 'en', 'me', 'you'), 'just english me and you', 'en -> en [4]');

is($w->loc('just english %1 and %2', 'he', 'me', 'you'), 'just english me and you', 'en -> he [4]');

is($w->loc('', 'en', 'asdf'), '', 'empty string returns empty string');

is($w->loc(undef, 'en'), undef, 'undef string returns undef');

done_testing();
