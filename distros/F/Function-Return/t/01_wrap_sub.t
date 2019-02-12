use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Function::Return;
use Types::Standard -types;
use Sub::Util ();

sub w {
    my ($code , $types) = @_;
    Sub::Util::set_subname('hoge', $code);
    my $wrapped = Function::Return->wrap_sub($code, $types);
    $wrapped->();
}

subtest 'empty return' => sub {
    ok(!w(sub { }, []), 'empty list');
    like(exception { w(sub { }, [Undef]) }, qr!^Too few return values for fun hoge \(expected Undef, got \) at t/01_wrap_sub\.t line 14\.$!, 'too few');
    like(exception { w(sub { 1 }, []) }, qr!^Too many return values for fun hoge \(expected , got 1\) at t/01_wrap_sub\.t line 14\.$!, 'too many');
};

subtest 'single return' => sub {
    is(w(sub { 1 }, [Int]), 1, 'return value is Int');
    like(exception { w(sub { 1.2 }, [Int]) }, qr!^Invalid return in fun hoge: return 0: Value "1\.2" did not pass type constraint "Int" at t/01_wrap_sub\.t line 14\.$!, 'return value is NOT Int');
};

subtest 'multi return' => sub {
    my $required_list_context = qr!^Required list context in fun hoge because of multiple return values function at t/01_wrap_sub\.t line 14\.$!;

    is_deeply([w(sub { 1, undef }, [Int, Undef])], [1, undef], 'multi return values/list context');
    like(exception { my $s = w(sub { 1, undef }, [Int, Undef]) }, $required_list_context, 'multi return values/scalar context');
    like(exception {         w(sub { 1, undef }, [Int, Undef]) }, $required_list_context, 'multi return values/void context');

    like(exception { my @l = w(sub { 1 }, [Int, Undef]) }, qr!^Too few return values for fun hoge \(expected Int Undef, got 1\) at t/01_wrap_sub\.t line 14\.$!, 'too few/multi/list context');
    like(exception { my $s = w(sub { 1 }, [Int, Undef]) }, $required_list_context, 'too few/multi/scalar context');
    like(exception {         w(sub { 1 }, [Int, Undef]) }, $required_list_context, 'too few/multi/void context');

    like(exception { my @l = w(sub { 1, undef, 2 }, [Int, Undef]) }, qr!^Too many return values for fun hoge \(expected Int Undef, got 1 undef 2\) at t/01_wrap_sub\.t line 14\.$!, 'too many/multi/list context');
    like(exception { my $s = w(sub { 1, undef, 2 }, [Int, Undef]) }, $required_list_context,  'too many/multi/scalar context');
    like(exception {         w(sub { 1, undef, 2 }, [Int, Undef]) }, $required_list_context,  'too many/multi/void context');
};

subtest 'cannot wrap' => sub {
    like(exception { Function::Return->wrap_sub(sub {}, [bless {}, 'MyType']) }, qr!^Invalid type:!, 'invalid type');
};

done_testing;
