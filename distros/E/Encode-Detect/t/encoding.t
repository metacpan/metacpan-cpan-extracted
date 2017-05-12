use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN { use_ok('Encode') }

our $d;

ok(require Encode::Detect);

ok($d = Encode::find_encoding('Detect'), 'new');

can_ok($d, qw(decode));

is($d->decode("\x82\xb7\x82\xb2\x82\xa2\x82\xcc\x82\xdd\x82\xc2"),
	"\x{3059}\x{3054}\x{3044}\x{306e}\x{307f}\x{3064}", "shift_jis");

is(Encode::decode("Detect", "j\xc2\x92aimerais"), "j\x92aimerais", 'utf-8');

