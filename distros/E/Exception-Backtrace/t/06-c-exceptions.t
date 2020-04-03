use strict;
use warnings;
use Test::More;
use Test::Warnings;
use lib 't';
use Config;

plan skip_all => 'does not work reliable for your platform' if $^O eq 'netbsd';
plan skip_all => 'does not work reliable for your platform' if $^O eq 'freebsd' && $Config{ptrsize} == 4; # i386-freebsd-thread-multi-64int

use Exception::Backtrace;
use MyTest;

Exception::Backtrace::install();

subtest "backtraceable exception is thrown" => sub {
    my $ok = eval { MyTest::throw_backtrace(); };
    ok !$ok;
    note $@;
    like "$@", qr/\Q[panda::exception] my-error at \E/;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    note $bt;
    if ($bt =~ /panda::exception::exception/) {
        like $bt, qr/MyTest_xsgen.cc/;
    }
    else {
        like $bt, qr/libpanda\./;
        like $bt, qr/MyTest((\.)|(_xsgen))/;
    }
};

subtest "std::logic_error is thrown" => sub {
    my $ok = eval { MyTest::throw_logic_error(); };
    ok !$ok;
    note $@;
    like "$@", qr/\Q[std::logic_error] my-logic-error at \E/;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    note $bt;
    if ($bt =~ /panda::Backtrace::Backtrace/) {
        unlike $bt, qr/panda::exception/;
    }
    else {
        like $bt, qr/libpanda\./;
        like $bt, qr/MyTest((\.)|(_xsgen))/;
    }
};

subtest "perl exception is thrown from C code" => sub {
    my $ok = eval { MyTest::call( sub { die "zzz" }) };
    ok !$ok;
    note $@;
    like "$@", qr/^zzz at /;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    note $bt;
    if ($bt =~ /panda::Backtrace::Backtrace/) {
        like $bt, qr/xs::Sub::_call/;
        unlike $bt, qr/panda::exception/;
    }
    else {
        like $bt, qr/libpanda\./;
        like $bt, qr/MyTest((\.)|(_xsgen))/;
    }
};

subtest "exception with newline is thrown" => sub {
    my $ok = eval { MyTest::throw_with_newline(); };
    ok !$ok;
    note $@;
    like "$@", qr/^\Q[std::logic_error] my-error\E$/;

    my $bt = Exception::Backtrace::get_backtrace_string($@);
    note $bt;
    if ($bt =~ /panda::Backtrace::Backtrace/) {
        pass "seems ok";
    }
    else {
        like $bt, qr/libpanda\./;
        like $bt, qr/MyTest((\.)|(_xsgen))/;
    }
};

done_testing;
