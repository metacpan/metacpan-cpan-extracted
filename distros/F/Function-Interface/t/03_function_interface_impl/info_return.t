use Test2::V0;

use Function::Interface::Impl;
use Function::Return;
sub hello :Return() {}

my $info = Function::Interface::Impl::info_return \&hello;

isa_ok $info, 'Function::Return::Info';
is $info->types, [];

done_testing;
