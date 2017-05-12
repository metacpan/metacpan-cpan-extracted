use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

my $class = 'Getopt::Compact::WithCmd';

sub test_type {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($input, $expects, $has_cb) = @_;
    my ($type, $cb) = $class->_compile_spec($input);
    is $type, $expects;
    ok $has_cb ? $cb : !$cb;
}

subtest 'primitive types' => sub {
    is $class->_compile_spec('!'), '!';
    is $class->_compile_spec('+'), '+';
    is $class->_compile_spec('=s'), '=s';
    is $class->_compile_spec('=i'), '=i';
    is $class->_compile_spec('=f'), '=f';
    is $class->_compile_spec('=o'), '=o';
};

subtest 'default types' => sub {
    test_type(Bool  => '!');
    test_type(Incr  => '+');
    test_type(Str   => '=s');
    test_type(Int   => '=i');
    test_type(Num   => '=f');
    test_type(ExNum => '=o');
};

$class->add_type(Eval => Str => sub {
    my $res = eval "$_[0]";
    die "$@\n" if $@;
    return $res;
});

subtest 'ext types' => sub {
    test_type(Eval => '=s', 1);
};

done_testing;
