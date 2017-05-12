# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 001-Types.t'

#########################

use strict;
use warnings;

use Test::More tests => 39;

use_ok('Games::Go::AGA::DataObjects::Types', qw(
                      is_ID
                      is_Rank
                      is_Rating
                      is_Handicap
                      is_Komi
                      is_Winner ) );

ok(is_ID('test_id'    ), ' test_id is a good ID');
ok(is_ID('id_5658'    ), ' id_5658 is a good ID');
ok(is_Rank('9d'       ), ' 9d      is a good Rank');
ok(is_Rank('1D'       ), ' 1D      is a good Rank');
ok(is_Rank('3d'       ), ' 3d      is a good Rank');
ok(is_Rank('44K'      ), ' 44K     is a good Rank');
ok(is_Rating('9.999'  ), ' 9.999  is a good Rating');
ok(is_Rating('3'      ), ' 3      is a good Rating');
ok(is_Rating('1.0'    ), '1.0     is a good Rating');
ok(is_Rating('-1.0'   ), '-1.0    is a good Rating');
ok(is_Rating('-33.456'), '-33.456 is a good Rating');
ok(is_Rating('-99.999'), '-99.999 is a good Rating');
ok(is_Handicap(0),       '0       is a good Handicap');
ok(is_Handicap(9),       '9       is a good Handicap');
ok(is_Komi(-5),          '-5      is a good Komi');
ok(is_Komi(0.5),         '0.5     is a good Komi');
ok(is_Komi(5.5),         '5.5     is a good Komi');
ok(is_Winner('w'),       'w       is a good Winner');
ok(is_Winner('B'),       'B       is a good Winner');
ok(is_Winner('?'),       '?       is a good Winner');

ok(is_ID('test id' ) ? 0 : 1, 'test id is a bad ID'); # why do we need the ?: operator?  'not' doesn't seem to work (shrug)
ok(is_ID('test%id' ) ? 0 : 1, 'test%id is a bad ID');
ok(is_ID('test!id' ) ? 0 : 1, 'test!id is a bad ID');
ok(is_ID('0123_id' ) ? 0 : 1, '0123_id is a bad ID');
ok(is_ID('0123456' ) ? 0 : 1, '0123456 is a bad ID');
ok(is_Rank('3A'    ) ? 0 : 1, '3A      is a bad Rank');
ok(is_Rank('21D'   ) ? 0 : 1, '21D     is a bad Rank');
ok(is_Rank('-3k'   ) ? 0 : 1, '-3k     is a bad Rank');
ok(is_Rating('20.0') ? 0 : 1, '20.0    is a bad Rating');
ok(is_Rating('0.8' ) ? 0 : 1, '0.8     is a bad Rating');
ok(is_Rating('-0.4') ? 0 : 1, '-0.4    is a bad Rating');
ok(is_Rating('-100') ? 0 : 1, '-100    is a bad Rating');
ok(is_Handicap(-1) ? 0 : 1, '-1        is a bad Handicap');
ok(is_Handicap(101) ? 0 : 1, '101      is a bad Handicap');
ok(is_Handicap('x') ? 0 : 1, 'x        is a bad Handicap');
ok(is_Komi('abc') ? 0 : 1, 'abc        is a bad Komi');
ok(is_Winner('x') ? 0 : 1, 'x          is a bad Winner');
ok(is_Winner(1)   ? 0 : 1, '1          is a bad Winner');
