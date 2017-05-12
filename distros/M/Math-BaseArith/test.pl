# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 27 };
use Math::BaseArith;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$, = ' ';

    "0 0 1 0"	eq join(' ',encode( 2, 	[2, 2, 2, 2] )) 	? ok(1) : ok(0);
    "0 1 0 1"	eq join(' ',encode( 5,	[2, 2, 2, 2] )) 	? ok(1) : ok(0);
    "1 1 0 1"	eq join(' ',encode( 13,	[2, 2, 2, 2] )) 	? ok(1) : ok(0);
    "0 3 14"	eq join(' ',encode( 62,	[16, 16, 16] )) 	? ok(1) : ok(0);
    "1 0 2 3"	eq join(' ',encode( 75,	[4, 4, 4, 4] )) 	? ok(1) : ok(0);
    "0 2 3"	eq join(' ',encode( 75,	[4, 4, 4] )) 		? ok(1) : ok(0);
    "2 3"	eq join(' ',encode( 75,	[4, 4] )) 		? ok(1) : ok(0);
    "3"		eq join(' ',encode( 75,	[4] )) 			? ok(1) : ok(0);
    "0"		eq join(' ',encode( 76,	[4] )) 			? ok(1) : ok(0);
    "75"	eq join(' ',encode( 75,	[0] )) 			? ok(1) : ok(0);
    "18 3"	eq join(' ',encode( 75,	[0, 4] )) 		? ok(1) : ok(0);
    "4 2 3"	eq join(' ',encode( 75,	[0, 4, 4] )) 		? ok(1) : ok(0);
    "1 0 2 3"	eq join(' ',encode( 75,	[0, 4, 4, 4] )) 	? ok(1) : ok(0);
    "14 7"	eq join(' ',encode( 175,[0, 12] )) 		? ok(1) : ok(0);
    "4 2"	eq join(' ',encode( 14,	[0, 3] )) 		? ok(1) : ok(0);
    "4 2 7"	eq join(' ',encode( 175,[0, 3, 12] )) 		? ok(1) : ok(0);

    "2"		eq join(' ',decode( [0, 0, 1, 0],	[2, 2, 2, 2] )) ? ok(1) : ok(0);
    "5"		eq join(' ',decode( [0, 1, 0, 1],	[2, 2, 2, 2] )) ? ok(1) : ok(0);
    "62"	eq join(' ',decode( [0, 3, 14],	 	[16, 16, 16] )) ? ok(1) : ok(0);
    "15"	eq join(' ',decode( [1, 1, 1, 1],	[2, 2, 2, 2] )) ? ok(1) : ok(0);
    "15"	eq join(' ',decode( [1, 1, 1, 1],	[2] )) 		? ok(1) : ok(0);
# In APL, the following test yield 15 if the [1] is passed as a scalar (but not if a vector)
    "1"		eq join(' ',decode( [1], 		[2, 2, 2, 2] )) ? ok(1) : ok(0);
    "175"	eq join(' ',decode( [4, 2, 7],		[0, 3, 12] )) 	? ok(1) : ok(0);
    "183927"	eq join(' ',decode( [2, 3, 5, 27],	[0, 24, 60, 60] )) ? ok(1) : ok(0);
    "3065.45"	eq join(' ',decode( [2, 3, 5, 27],	[0, 24, 60, 60] )) / 60 ? ok(1) : ok(0);

warn "The next test should cause a length error\n";
    decode( [1, 1, 1, 1], [2, 2, 2] ) ? ok(0) : ok(1);

