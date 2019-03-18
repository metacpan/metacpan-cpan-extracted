use Test2::V0;

use Function::Return;
use Types::Standard -types;

use Function::Interface::Impl;
use Function::Interface::Info::Function;
use Function::Interface::Info::Function::ReturnParam;

subtest 'empty return' => sub {
    sub foo :Return() { }
    ok check_return(\&foo, []);
    ok not check_return(\&foo, [Str]);
};

subtest 'single return' => sub {
    sub foo2 :Return(Str) { }
    ok check_return(\&foo2, [Str]);
    ok not check_return(\&foo2, []);
    ok not check_return(\&foo2, [Int]);
};

subtest 'two return' => sub {
    sub foo3 :Return(Str, Int) { }
    ok check_return(\&foo3, [Str, Int]);
    ok not check_return(\&foo3, []);
    ok not check_return(\&foo3, [Str]);
    ok not check_return(\&foo3, [Str, Int, Num]);
    ok not check_return(\&foo3, [Str, Str]);
    ok not check_return(\&foo3, [Int, Int]);
    ok not check_return(\&foo3, [Int, Str]);
};

sub check_return {
    my ($code, $types) = @_;

    my $rinfo = Function::Return::info($code);
    my $iinfo = iinfo($types);

    Function::Interface::Impl::check_return($rinfo, $iinfo);
}

sub iinfo {
    my ($types) = @_;
    Function::Interface::Info::Function->new(
        return => [
            map { Function::Interface::Info::Function::ReturnParam->new( type => $_ ) } @$types
        ]
    );
}

done_testing;
