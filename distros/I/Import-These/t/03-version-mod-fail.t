use strict;
use warnings;

use lib "t/lib";
use Test::More;
use Import::These;

our $res;

BEGIN {
  $res=eval { Import::These->import("Import::These::", "InternalTest", "v1000.3"); 1;};
}


ok !$res,  "Mod version negative";
done_testing;
