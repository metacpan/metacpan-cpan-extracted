use Test2::V0;

use Function::Interface;
use Types::Standard -types;

fun foo() :Return();
fun bar(Str $msg) :Return(Int);
method baz() :Return();

subtest 'basic' => sub {
    my $info = Function::Interface::info __PACKAGE__;

    is $info->package, 'main';
    is @{$info->functions}, 3;

    subtest 'foo' => sub {
        my $i = $info->functions->[0];
        is $i->subname, 'foo';
        is $i->keyword, 'fun';
        is $i->params, [];
        is $i->return, [];
    };

    subtest 'bar' => sub {
        my $i = $info->functions->[1];
        is $i->subname, 'bar';
        is $i->keyword, 'fun';

        is @{$i->params}, 1;
        isa_ok $i->params->[0], 'Function::Interface::Info::Function::Param';
        ok $i->params->[0]->type eq Str;
        is $i->params->[0]->name, '$msg';

        is @{$i->return}, 1;
        isa_ok $i->return->[0], 'Function::Interface::Info::Function::ReturnParam';
        ok $i->return->[0]->type eq Int;
    };

    subtest 'baz' => sub {
        my $i = $info->functions->[2];
        is $i->subname, 'baz';
        is $i->keyword, 'method';
        is $i->params, [];
        is $i->return, [];
    };
};

subtest 'empty' => sub {
    my $info = Function::Interface::info 'Hoge';
    is $info, undef;
};

done_testing;

