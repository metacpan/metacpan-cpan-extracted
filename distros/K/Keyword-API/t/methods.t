use strict;
use warnings;
use lib "t/lib";
use Test::More;
use_ok "Example";

my $obj = Example->new;
isa_ok $obj, 'Example';

is $obj->foo(1, 2), 3, "method called ok";

done_testing();
