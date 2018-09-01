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

fun with_fp() :Return(Num) { }

subtest 'single' => sub {
    my $single_return_info = Function::Return::info \&single;
    isa_ok $single_return_info, 'Function::Return::Info';
    is_deeply $single_return_info->types, [Str];
};

subtest 'multi' => sub {
    my $multi_return_info = Function::Return::info \&multi;
    isa_ok $multi_return_info, 'Function::Return::Info';
    is_deeply $multi_return_info->types, [Str, Int];
};

subtest 'empty' => sub {
    my $empty_return_info = Function::Return::info \&empty;
    isa_ok $empty_return_info, 'Function::Return::Info';
    is_deeply $empty_return_info->types, [];
};

subtest 'with_fp' => sub {
    my $with_fp_return_info = Function::Return::info \&with_fp;
    isa_ok $with_fp_return_info, 'Function::Return::Info';
    is_deeply $with_fp_return_info->types, [Num];

    my $with_fp_parameters_info = Function::Parameters::info \&with_fp;
    isa_ok $with_fp_parameters_info, 'Function::Parameters::Info';
};

done_testing;
