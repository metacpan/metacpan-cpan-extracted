use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Function::Return;
use Types::Standard -types;

sub case_empty_list :Return() { }
sub case_empty_list_few :Return(Undef) { }
sub case_empty_type :Return() { 1 }

sub case_int :Return(Int) { 1 }
sub case_invalid_int :Return(Int) { 1.2 }

sub case_multi_int_undef :Return(Int, Undef) { 1, undef }
sub case_multi_int_undef_few :Return(Int, Undef) { 1 }
sub case_multi_int_undef_many :Return(Int, Undef) { 1, undef, 2 }

subtest 'type checks' => sub {

    ok(!exception { case_empty_list }, 'emptly list');
    like(exception { case_empty_list_few }, qr!^Too few return values for fun case_empty_list_few!, 'too few');
    like(exception { case_empty_type }, qr!Too many return values for fun case_empty_type!, 'too many');

    ok(!exception  { case_int }, 'return value is Int');
    like(exception { case_invalid_int }, qr!^Invalid return in fun case_invalid_int:!, 'return value is NOT Int');

    subtest 'multi return' => sub {
        my $required_list_context = qr!^Required list context in fun !;

        ok(!exception  { my @l = case_multi_int_undef }, 'multi return values/list context');
        like(exception { my $s = case_multi_int_undef }, $required_list_context, 'multi return values/scalar context');
        like(exception {         case_multi_int_undef }, $required_list_context, 'multi return values/void context');

        like(exception { my @l = case_multi_int_undef_few }, qr!^Too few return values for fun case_multi_int_undef_few!, 'too few/multi/list context');
        like(exception { my $s = case_multi_int_undef_few }, $required_list_context, 'too few/multi/scalar context');
        like(exception {         case_multi_int_undef_few }, $required_list_context, 'too few/multi/void context');

        like(exception { my @l = case_multi_int_undef_many }, qr!^Too many return values for fun case_multi_int_undef_many!, 'too many/multi/list context');
        like(exception { my $s = case_multi_int_undef_many }, $required_list_context,  'too many/multi/scalar context');
        like(exception {         case_multi_int_undef_many }, $required_list_context,  'too many/multi/void context');
    };
};

done_testing;
