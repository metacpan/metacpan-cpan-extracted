use Test2::V0;

use Function::Interface pkg => 'MyTest';
fun foo() :Return();

my $info = Function::Interface::info 'MyTest';
is $info->package, 'MyTest';

done_testing;
