use strict;
use warnings;

use lib "t/lib";
use Test::More;

use Import::These "Import::These::", "InternalTest", "v1";

my $res=eval {unimported( "a") };

ok $@,  "Unlisted import";

$res=eval {default_sub};

ok !$@,  "Listed import";
ok $res==1, "Listed import";
done_testing;
