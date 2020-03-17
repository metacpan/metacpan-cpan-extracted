use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Exception::Backtrace;

use lib 't';
use MyTest;

Exception::Backtrace::install();

sub check_c_trace {
    my $bt = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    like $bt, qr/(panda::Backtrace::Backtrace)|(from.*Backtrace\.)/;
}

subtest "primitive is thrown" => sub {
    my $ok = eval { 
        die("abc"); 1;
    };
    ok !$ok;
    note $@;
    like "$@", qr/^abc/;

    my $ex = $@;
    my $bt = Exception::Backtrace::get_backtrace_string($ex);
    ok $bt;
    note "bt = ", $bt;
    check_c_trace($bt);
    like $bt, qr/main/;

    subtest "pure perl exception" => sub {
        my $bt2 = Exception::Backtrace::get_backtrace_string_pp($ex);
        isnt index($bt, $bt2), -1, "pure perl trace is contained in full trace already";
    };
};

subtest "just die is thrown" => sub {
    my $ok = eval { die(); 1; };
    ok !$ok;
    like "$@", qr/^Died/;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    ok $bt;
    note $bt;
    check_c_trace($bt);
    like $bt, qr/main/;
};

subtest "list of args is thrown" => sub {
    my $ok = eval { die(qw/a b c d/); 1; };
    ok !$ok;
    like "$@", qr/^abcd/;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    ok $bt;
    note $bt;
    check_c_trace($bt);
    like $bt, qr/main/;
};

subtest "ref-to-const is thrown" => sub {
    my $ref = \"constant";
    my $ok = eval { die($ref); 1; };
    ok !$ok;
    is $@, $ref;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    ok $bt;
    note $bt;
    like $bt, qr|C backtrace is n/a|;
    like $bt, qr|Perl backtrace is n/a|;
};

subtest "ref-to-noconst is thrown" => sub {
    my $ref = [];
    my $ok = eval { die($ref); 1; };
    ok !$ok;
    is $@, $ref;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    ok $bt;
    note $bt;
    check_c_trace($bt);
    like $bt, qr/main/;
};

subtest "ref-to-ref is thrown" => sub {
    my $ref = \\\\\\\\\\"abc";
    my $ok = eval { die($ref); 1; };
    ok !$ok;
    is $@, $ref;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    ok $bt;
    note $bt;
    check_c_trace($bt);
    like $bt, qr/main/;
};


subtest "object is thrown" => sub {
    my $ref = bless {} => "ABC";
    my $ok = eval { die($ref); 1; };
    ok !$ok;
    is $@, $ref;
    is ref($@), 'ABC';

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    ok $bt;
    note $bt;
    check_c_trace($bt);
    like $bt, qr/main/;
};

subtest "rethrow (string)" => sub {
    my $ok = eval { my $l = __LINE__; die("died at $l"); 1; };
    ok !$ok;
    like "$@", qr/died at/;
    my $e1 = $@;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    ok $bt;
    note $bt;
    check_c_trace($bt);
    like $bt, qr/main/;
};

subtest "rethrow (ref)" => sub {
    my $it = {};
    my $ok = eval { die($it); 1; };
    ok !$ok;
    like "$@", qr/HASH/;
    my $e1 = $@;

    $ok = eval { die($e1); 1; };
    ok !$ok;
    my $e2 = $@;
    ok $e1 == $e2;
    is "$e1", "$e2";
};

done_testing;
