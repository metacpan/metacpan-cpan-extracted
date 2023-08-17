use strict;
use warnings;

use Test::More;
use lib "t/lib";

use Import::These "Import::These::InternalTest";
my $res=eval {default_sub()};

ok !$@,  "Default import";
ok $res==1, "Default import";

done_testing;
