use strict;
use warnings;

use Test::More;
use lib "./t";

use ModASub;#  '$var1', '@var2', "%var3", "sub1", ":group1";


ok sub1, "Reexport from parent";
done_testing;
