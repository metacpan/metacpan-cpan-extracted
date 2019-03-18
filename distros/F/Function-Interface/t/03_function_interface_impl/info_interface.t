use Test2::V0;

package ITest;

use Function::Interface;
fun hello() :Return();


package main;

use Function::Interface::Impl;

my $info = Function::Interface::Impl::info_interface 'ITest';
isa_ok $info, 'Function::Interface::Info';
is $info->package, 'ITest';
is $info->functions, [
    Function::Interface::Info::Function->new(
        subname => 'hello',
        keyword => 'fun',
        params  => [],
        return  => [],
    )
];

done_testing;
