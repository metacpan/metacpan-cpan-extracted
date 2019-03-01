use Test2::V0;

use Function::Interface::Info;

my $info = Function::Interface::Info->new(
    package => 'IFoo',
    functions => []
);

isa_ok $info, 'Function::Interface::Info';
is $info->package, 'IFoo';
is $info->functions, [];

done_testing;
