use strict;
use warnings;

use Test::More;
use lib "./t";
use ModA  '$var1', '@var2', "%var3", "sub1", ":group1";

ok $var1 eq "var1", "Export scalar";

ok @var2 == 2, "Array export";
ok $var2[0] eq "var2" , "Array export";

ok $var3{var3} == 1, "Hash Export ok";

ok sub1 eq "sub1", "Sub export ok";

ok group1_sub eq "group1_sub", "group export sub ok";

ok $group1_scalar eq "group1_scalar", "group export scalar ok";

ok @group1_array == 2, "group export array ok";
ok $group1_array[0] eq "group1_array", "group export array ok";


ok group2_sub eq "group2_sub", "group reexport sub ok";

ok $group2_scalar eq "group2_scalar", "group reexport scalar ok";



# Test passthrough

use ModC  "sub4";
ok sub4 eq "sub4";

use ModD  qw<:group3 df>;
ok group3_sub eq "group3_sub";


done_testing;
