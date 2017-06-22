use warnings;
use strict;

use Test::More;

use Keyword::Declare;

keyword pref (Int, Int)            { fail  "Int/Int";    }
keyword pref (Int, Num)    :prefer { ok 1, "Preferred";  }
keyword pref (Num, PosInt)         { fail  "Num/PosInt"; }

pref 1 2;
pref 1 2.0;

done_testing();

