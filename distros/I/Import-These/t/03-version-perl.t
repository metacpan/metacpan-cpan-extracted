use strict;
use warnings;


use lib "t/lib";
use Test::More;

use Import::These;
our $res;

BEGIN {
  $res=eval { Import::These->import("v1000", "Import::These::", "InternalTest", "v1.1", ["default_sub"]) ; 1};
}

ok !$res, "Perl version check";
done_testing;
