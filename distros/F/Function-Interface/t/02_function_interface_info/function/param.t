use Test2::V0;

use Function::Interface::Info::Function::Param;
use Types::Standard qw(Str);

my $param = Function::Interface::Info::Function::Param->new(
    type     => Str,
    name     => '$foo',
    optional => 0,
    named    => 0,
);

isa_ok $param, 'Function::Interface::Info::Function::Param';
ok $param->type eq Str;
is $param->type_display_name, Str->display_name;
is $param->name, '$foo';
ok !$param->optional;
ok !$param->named;

done_testing;
