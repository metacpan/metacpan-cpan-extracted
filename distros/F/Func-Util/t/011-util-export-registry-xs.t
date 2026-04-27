#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


# Check if modules can load BEFORE running any tests
# This avoids "Bad plan" errors when skip_all is needed
BEGIN {
    # Cygwin/Windows can't link the test extension against Util.dll without
    # an import library that we don't ship. Skip outright instead of letting
    # the dlopen failure consume Cygwin fork resources and corrupt later
    # tests in the run.
    if ($^O eq 'cygwin' || $^O eq 'MSWin32' || $^O eq 'msys') {
        plan skip_all => "export-registry XS test cannot link against Util.dll on $^O";
        exit 0;
    }

    # Try to load util first
    eval { require Func::Util };
    if ($@) {
        plan skip_all => "Func::Util not loadable: $@";
        exit 0;
    }
    Func::Util->import();

    # Try to load funcutil_export_test (depends on util.so)
    eval { require funcutil_export_test; funcutil_export_test->import(); };
    if ($@) {
        plan skip_all => "funcutil_export_test not loadable (linking issue): $@";
        exit 0;
    }
}

pass('Func::Util loaded');
pass('funcutil_export_test loaded');

# ============================================
# Verify XS functions were registered with Func::Util
# ============================================

subtest 'XS functions registered with Func::Util' => sub {
    ok(Func::Util::has_export('xs_double'), 'xs_double registered');
    ok(Func::Util::has_export('xs_triple'), 'xs_triple registered');
    ok(Func::Util::has_export('xs_square'), 'xs_square registered');
    ok(Func::Util::has_export('xs_sum_args'), 'xs_sum_args registered');
    ok(Func::Util::has_export('xs_concat_args'), 'xs_concat_args registered');
    ok(Func::Util::has_export('xs_is_lucky'), 'xs_is_lucky registered');
    ok(Func::Util::has_export('xs_make_pair'), 'xs_make_pair registered');

    # list_exports should include them
    my %exports = map { $_ => 1 } @{Func::Util::list_exports()};
    ok($exports{'xs_double'}, 'xs_double in list');
    ok($exports{'xs_triple'}, 'xs_triple in list');
    ok($exports{'xs_square'}, 'xs_square in list');
};

# ============================================
# Import XS functions via Func::Util
# ============================================

subtest 'import XS functions via Func::Util' => sub {
    {
        package TestXS1;
        Func::Util->import('xs_double', 'xs_triple', 'xs_square');

        main::is(xs_double(5), 10, 'xs_double(5) = 10');
        main::is(xs_double(0), 0, 'xs_double(0) = 0');
        main::is(xs_double(-3), -6, 'xs_double(-3) = -6');
        main::is(xs_double(2.5), 5, 'xs_double(2.5) = 5');

        main::is(xs_triple(4), 12, 'xs_triple(4) = 12');
        main::is(xs_triple(0), 0, 'xs_triple(0) = 0');
        main::is(xs_triple(-2), -6, 'xs_triple(-2) = -6');

        main::is(xs_square(3), 9, 'xs_square(3) = 9');
        main::is(xs_square(5), 25, 'xs_square(5) = 25');
        main::is(xs_square(-4), 16, 'xs_square(-4) = 16');
        main::is(xs_square(0), 0, 'xs_square(0) = 0');
    }
};

subtest 'import variadic XS functions via Func::Util' => sub {
    {
        package TestXS2;
        Func::Util->import('xs_sum_args', 'xs_concat_args');

        main::is(xs_sum_args(1, 2, 3), 6, 'xs_sum_args(1,2,3) = 6');
        main::is(xs_sum_args(10), 10, 'xs_sum_args(10) = 10');
        main::is(xs_sum_args(), 0, 'xs_sum_args() = 0');
        main::is(xs_sum_args(1, 2, 3, 4, 5), 15, 'xs_sum_args(1..5) = 15');
        main::is(xs_sum_args(-1, 1), 0, 'xs_sum_args(-1, 1) = 0');

        main::is(xs_concat_args('a', 'b', 'c'), 'abc', 'concat abc');
        main::is(xs_concat_args('hello'), 'hello', 'concat single');
        main::is(xs_concat_args(), '', 'concat empty');
        main::is(xs_concat_args('foo', ' ', 'bar'), 'foo bar', 'concat with space');
    }
};

subtest 'import predicate XS function via Func::Util' => sub {
    {
        package TestXS3;
        Func::Util->import('xs_is_lucky');

        main::ok(xs_is_lucky(7), 'xs_is_lucky(7) is true');
        main::ok(!xs_is_lucky(6), 'xs_is_lucky(6) is false');
        main::ok(!xs_is_lucky(8), 'xs_is_lucky(8) is false');
        main::ok(!xs_is_lucky(0), 'xs_is_lucky(0) is false');
        main::ok(!xs_is_lucky(-7), 'xs_is_lucky(-7) is false');
    }
};

subtest 'import multi-return XS function via Func::Util' => sub {
    {
        package TestXS4;
        Func::Util->import('xs_make_pair');

        my @pair = xs_make_pair('a', 'b');
        main::is_deeply(\@pair, ['a', 'b'], 'make_pair list context');

        @pair = xs_make_pair(1, 2);
        main::is($pair[0], 1, 'make_pair first');
        main::is($pair[1], 2, 'make_pair second');
    }
};

# ============================================
# Mix XS and built-in util functions
# ============================================

subtest 'mix XS and built-in imports' => sub {
    {
        package TestXS5;
        Func::Util->import('xs_double', 'xs_square', 'is_array', 'is_hash', 'memo');

        # XS functions work
        main::is(xs_double(10), 20, 'xs_double with built-ins');
        main::is(xs_square(4), 16, 'xs_square with built-ins');

        # Built-in functions still work
        main::ok(is_array([]), 'is_array still works');
        main::ok(is_hash({}), 'is_hash still works');

        # memo still works
        my $count = 0;
        my $fn = memo(sub { $count++; $_[0] * 2 });
        main::is($fn->(5), 10, 'memo first call');
        main::is($fn->(5), 10, 'memo cached');
        main::is($count, 1, 'memo only called once');
    }
};

# ============================================
# Direct access vs Func::Util import
# ============================================

subtest 'direct module access vs Func::Util import' => sub {
    # Direct access to test module function
    is(funcutil_export_test::direct_quadruple(5), 20, 'direct access works');

    # Can't import direct_quadruple via Func::Util (it wasn't registered)
    ok(!Func::Util::has_export('direct_quadruple'), 'direct_quadruple not in Func::Util');

    eval {
        package TestXS6;
        Func::Util->import('direct_quadruple');
    };
    like($@, qr/unknown export/, 'cannot import unregistered function');
};

# ============================================
# Edge cases
# ============================================

subtest 'XS function edge cases' => sub {
    {
        package TestXS7;
        Func::Util->import('xs_double', 'xs_sum_args');

        # Large numbers
        main::is(xs_double(1e10), 2e10, 'xs_double large');
        main::is(xs_sum_args(1e10, 2e10, 3e10), 6e10, 'xs_sum_args large');

        # Floating point precision
        my $result = xs_double(0.1);
        main::ok(abs($result - 0.2) < 1e-10, 'xs_double float precision');
    }
};

subtest 'XS function error handling' => sub {
    {
        package TestXS8;
        Func::Util->import('xs_double', 'xs_square');

        # Wrong number of args
        eval { xs_double() };
        main::like($@, qr/Usage/, 'xs_double no args croaks');

        eval { xs_double(1, 2) };
        main::like($@, qr/Usage/, 'xs_double too many args croaks');

        eval { xs_square() };
        main::like($@, qr/Usage/, 'xs_square no args croaks');
    }
};

# ============================================
# Verify no namespace pollution
# ============================================

subtest 'no namespace pollution' => sub {
    # Functions should only exist in packages that imported them
    ok(!main->can('xs_double'), 'xs_double not in main');
    ok(!main->can('xs_triple'), 'xs_triple not in main');

    # But TestXS1 should have them
    ok(TestXS1->can('xs_double'), 'xs_double in TestXS1');
    ok(TestXS1->can('xs_triple'), 'xs_triple in TestXS1');

    # TestXS2 should have different ones
    ok(TestXS2->can('xs_sum_args'), 'xs_sum_args in TestXS2');
    ok(!TestXS2->can('xs_double'), 'xs_double not in TestXS2');
};

done_testing;
