use warnings;
use strict;

use FOO qw(:all);

use Test::More;

is(dubble(21), 42, 'dubble() ok');
is(dubb(21), 42, 'dubb() ok');
is(dv(21), 42, 'dv() ok');

eval {vv(21)};
is($@, '', 'vv() ok');

is(dub(21), 42, 'dub() ok');
is(call_dub(21), 42, 'call_dub() ok');
is(dubul(21), 42, 'dubul() ok');
is(call_dubd(21.0), 42.0, 'call_dubd() ok');

done_testing();
