#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 5;
use Locale::Wolowitz;

my $w = Locale::Wolowitz->new();
ok($w, 'Got a proper Wolowitz object');

$w->load_structure({
	'OMG' => {
		en => 'Oh My God',
		rev_en => 'doG yM hO'
	},
	'FTW' => {
		en => 'For The Win',
		rev_en => 'niW ehT roF'
	},
    doc => {
        xo => 'bub',
    },
});

is($w->loc('OMG', 'en'), 'Oh My God', 'en -> en [1]');

is($w->loc('FTW', 'rev_en'), 'niW ehT roF', 'en -> rev_en [1]');

$w->load_path('t/i18n/i18n.coll.json');

is($w->loc("what's up %1?", 'xo', 'zyzyx'), "how's it hangin' zyzyx?", 'en -> xo [1]');

subtest 'translate arguments' => sub {
    is $w->loc("what's up %1?", 'xo', $w->loc('doc','xo') ), "how's it hangin' bub?", 'classic';
    is $w->loc("what's up %1?", 'xo', [ 'doc' ] ), "how's it hangin' bub?", 'w/ array ref';
};

done_testing();
