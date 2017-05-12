use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN { use_ok('Encode::Detect::Detector') }

our $d;

ok($d = new Encode::Detect::Detector, 'new');

can_ok('Encode::Detect::Detector', 'detect');

can_ok($d, qw(handle getresult DESTROY));

is($d->handle("\x82\xb7\x82\xb2\x82\xa2\x82\xcc\x82\xdd\x82\xc2"), 0, 'handle');

$d->eof;

is($d->getresult, "Shift_JIS", 'getresult');

is(detect("j\xc2\x92aimerais"), "UTF-8", 'detect');

