use Test2::V0;

use Function::Interface::Info::Function::ReturnParam;
use Types::Standard qw(Str);

my $rparam = Function::Interface::Info::Function::ReturnParam->new(
    type => Str,
);

isa_ok $rparam, 'Function::Interface::Info::Function::ReturnParam';
ok $rparam->type eq Str;
is $rparam->type_display_name, Str->display_name;

done_testing;
