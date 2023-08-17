use strict;
use warnings;
use lib "t/lib";

use Test::More;

use Import::These "File::Spec::Functions"=>[];
my $res=eval { default_sub()};

ok $@,  "No imports";

done_testing;
