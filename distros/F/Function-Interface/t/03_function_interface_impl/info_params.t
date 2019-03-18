use Test2::V0;

use Function::Interface::Impl;
use Function::Parameters;
fun hello() {}

my $info = Function::Interface::Impl::info_params \&hello;

isa_ok $info, 'Function::Parameters::Info';
is $info->keyword, 'fun';
is [$info->positional_required], [];
is [$info->positional_optional], [];
is [$info->named_required], [];
is [$info->named_optional], [];

done_testing;
