use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Function::Parameters;
use Function::Return;
use Types::Standard -types;

sub single :Return(Str) { }
sub multi :Return(Str, Int) { }
sub empty :Return() { }

fun with_fp_fun(Str $a) :Return(Num) { }
method with_fp_method(Str $b) :Return(Num) { }

subtest 'single' => sub {
    my $info = Function::Return::info \&single;
    isa_ok $info, 'Function::Return::Info';
    is_deeply $info->types, [Str];
};

subtest 'multi' => sub {
    my $info = Function::Return::info \&multi;
    isa_ok $info, 'Function::Return::Info';
    is_deeply $info->types, [Str, Int];
};

subtest 'empty' => sub {
    my $info = Function::Return::info \&empty;
    isa_ok $info, 'Function::Return::Info';
    is_deeply $info->types, [];
};

subtest 'with_fp_fun' => sub {
    my $info = Function::Return::info \&with_fp_fun;
    isa_ok $info, 'Function::Return::Info';
    is_deeply $info->types, [Num];

    my $pinfo = Function::Parameters::info \&with_fp_fun;
    isa_ok $pinfo, 'Function::Parameters::Info';
    is $pinfo->keyword, 'fun';
    my ($p) = $pinfo->positional_required;
    is $p->type, Str;
    is $p->name, '$a';
};

subtest 'with_fp_method' => sub {
    my $info = Function::Return::info \&with_fp_method;
    isa_ok $info, 'Function::Return::Info';
    is_deeply $info->types, [Num];

    my $pinfo = Function::Parameters::info \&with_fp_method;
    isa_ok $pinfo, 'Function::Parameters::Info';
    is $pinfo->keyword, 'method';
    my ($p) = $pinfo->positional_required;
    is $p->type, Str;
    is $p->name, '$b';
};

done_testing;
