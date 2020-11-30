use strict;
use warnings;
use Test::More;
use Test::Warnings;
use lib 't';
use Config;
use Exception::Backtrace;
use MyTest;

my $default_depth = MyTest::default_trace_depth();
plan skip_all => 'does not work reliable for your platform' unless $default_depth;

Exception::Backtrace::install();

subtest "backtraceable exception is thrown" => sub {
    my $ok = eval { MyTest::throw_backtrace(); };
    ok !$ok;
    note $@;
    like "$@", qr/\Q[panda::exception] my-error at \E/;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    note $bt;
    my $found = (($bt =~ /panda::exception::exception/) && ($bt =~ /MyTest_xsgen.cc/))
             || (($bt =~ /libpanda\./) && ($bt =~ /MyTest((\.)|(_xsgen))/))
             || ($bt =~ /panda::Backtrace::Backtrace/);
    ok $found, "seems valid backtrace found";
};

subtest "std::logic_error is thrown" => sub {
    my $ok = eval { MyTest::throw_logic_error(); };
    ok !$ok;
    note $@;
    like "$@", qr/\Q[std::logic_error] my-logic-error at \E/;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    note $bt;
    my $found = (($bt =~ /panda::Backtrace::Backtrace/) && ($bt !~ /panda::exception/))
             || ($bt =~ /MyTest((\.)|(_xsgen))/)
             || ($bt =~ /panda::Backtrace::zzz/);
    ok $found, "seems valid backtrace found";
};

subtest "perl exception is thrown from C code" => sub {
    my $ok = eval { MyTest::call( sub { die "zzz" }) };
    ok !$ok;
    note $@;
    like "$@", qr/^zzz at /;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    note $bt;
    my $re = qr/(panda::Backtrace::Backtrace)|(libpanda\.)|(MyTest((\.)|(_xsgen)))/;
    like $bt, $re, "seems valid backtrace found";
};

subtest "exception with newline is thrown" => sub {
    my $ok = eval { MyTest::throw_with_newline(); };
    ok !$ok;
    note $@;
    like "$@", qr/^\Q[std::logic_error] my-error\E$/;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    note $bt;
    my $found = (($bt =~ /panda::Backtrace::Backtrace/))
             || ($bt =~ /MyTest((\.)|(_xsgen))/);
    ok $found, "seems valid backtrace found";
};

done_testing;
