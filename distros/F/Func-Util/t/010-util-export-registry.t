#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


use_ok('Func::Util');

# ============================================
# list_exports - list all registered exports
# ============================================

subtest 'list_exports basic' => sub {
    my $exports = Func::Util::list_exports();
    ok(ref($exports) eq 'ARRAY', 'list_exports returns arrayref');
    ok(scalar(@$exports) > 0, 'list_exports has items');

    # Check some built-in exports exist
    my %export_hash = map { $_ => 1 } @$exports;
    ok($export_hash{'is_array'}, 'has is_array');
    ok($export_hash{'is_hash'}, 'has is_hash');
    ok($export_hash{'is_string'}, 'has is_string');
    ok($export_hash{'is_ref'}, 'has is_ref');
    ok($export_hash{'is_code'}, 'has is_code');
    ok($export_hash{'is_defined'}, 'has is_defined');
    ok($export_hash{'memo'}, 'has memo');
    ok($export_hash{'pipeline'}, 'has pipeline');
};

# ============================================
# has_export - check if export exists
# ============================================

subtest 'has_export basic' => sub {
    # Built-in exports
    ok(Func::Util::has_export('is_array'), 'has_export: is_array');
    ok(Func::Util::has_export('is_hash'), 'has_export: is_hash');
    ok(Func::Util::has_export('memo'), 'has_export: memo');
    ok(Func::Util::has_export('pipeline'), 'has_export: pipeline');

    # Non-existent
    ok(!Func::Util::has_export('nonexistent_function'), 'has_export: nonexistent');
    ok(!Func::Util::has_export(''), 'has_export: empty string');
};

# ============================================
# register_export - register custom functions
# ============================================

subtest 'register_export basic' => sub {
    # Register a simple function
    Func::Util::register_export('test_double', sub { $_[0] * 2 });
    ok(Func::Util::has_export('test_double'), 'registered test_double');

    # Register another
    Func::Util::register_export('test_triple', sub { $_[0] * 3 });
    ok(Func::Util::has_export('test_triple'), 'registered test_triple');

    # Both should be in list
    my $exports = Func::Util::list_exports();
    my %export_hash = map { $_ => 1 } @$exports;
    ok($export_hash{'test_double'}, 'test_double in list');
    ok($export_hash{'test_triple'}, 'test_triple in list');
};

subtest 'register_export validation' => sub {
    # Must be coderef
    eval { Func::Util::register_export('bad_ref', [1,2,3]) };
    like($@, qr/coderef/, 'rejects non-coderef');

    eval { Func::Util::register_export('bad_scalar', 'not_a_ref') };
    like($@, qr/coderef/, 'rejects scalar');

    eval { Func::Util::register_export('bad_hash', {a => 1}) };
    like($@, qr/coderef/, 'rejects hashref');
};

subtest 'register_export duplicate' => sub {
    # Register a function
    Func::Util::register_export('test_unique', sub { 'first' });
    ok(Func::Util::has_export('test_unique'), 'first registration');

    # Try to register same name again
    eval { Func::Util::register_export('test_unique', sub { 'second' }) };
    like($@, qr/already registered/, 'rejects duplicate');
};

# ============================================
# Import registered functions
# ============================================

subtest 'import registered function' => sub {
    # Register and import
    Func::Util::register_export('custom_add', sub { $_[0] + $_[1] });

    # Import into a test package
    {
        package TestPkg1;
        Func::Util->import('custom_add');

        # Test it works
        main::is(custom_add(2, 3), 5, 'custom_add works');
        main::is(custom_add(10, 20), 30, 'custom_add second call');
    }
};

subtest 'import multiple functions' => sub {
    Func::Util::register_export('custom_mul', sub { $_[0] * $_[1] });
    Func::Util::register_export('custom_div', sub { $_[0] / $_[1] });

    {
        package TestPkg2;
        Func::Util->import('custom_mul', 'custom_div', 'is_array');

        main::is(custom_mul(3, 4), 12, 'custom_mul works');
        main::is(custom_div(20, 5), 4, 'custom_div works');
        main::ok(is_array([]), 'is_array works');
    }
};

subtest 'import unknown function' => sub {
    eval {
        package TestPkg3;
        Func::Util->import('totally_unknown_function');
    };
    like($@, qr/unknown export/, 'rejects unknown function');
};

# ============================================
# Use case: Module registering functions
# ============================================

subtest 'module registration pattern' => sub {
    # Simulate a module registering its functions
    {
        package MyModule;

        sub greet { "Hello, $_[0]!" }
        sub farewell { "Goodbye, $_[0]!" }

        # Register with util
        Func::Util::register_export('greet', \&greet);
        Func::Util::register_export('farewell', \&farewell);
    }

    # User imports via Func::Util
    {
        package UserCode;
        Func::Util->import('greet', 'farewell');

        main::is(greet('World'), 'Hello, World!', 'greet imported');
        main::is(farewell('World'), 'Goodbye, World!', 'farewell imported');
    }
};

# ============================================
# Edge cases
# ============================================

subtest 'register closure with state' => sub {
    my $counter = 0;
    Func::Util::register_export('get_count', sub { return ++$counter });

    {
        package TestPkg4;
        Func::Util->import('get_count');

        main::is(get_count(), 1, 'first call');
        main::is(get_count(), 2, 'second call');
        main::is(get_count(), 3, 'third call');
    }
};

subtest 'register function with multiple returns' => sub {
    Func::Util::register_export('multi_return', sub {
        return wantarray ? (1, 2, 3) : 'scalar';
    });

    {
        package TestPkg5;
        Func::Util->import('multi_return');

        my @arr = multi_return();
        main::is_deeply(\@arr, [1, 2, 3], 'list context');

        my $scalar = multi_return();
        main::is($scalar, 'scalar', 'scalar context');
    }
};

subtest 'register function accessing $_' => sub {
    Func::Util::register_export('uses_dollar_under', sub {
        local $_ = $_[0] // $_;
        return uc($_);
    });

    {
        package TestPkg6;
        Func::Util->import('uses_dollar_under');

        main::is(uses_dollar_under('hello'), 'HELLO', 'with arg');
    }
};

# ============================================
# Verify original util functions still work
# ============================================

subtest 'built-in functions still work' => sub {
    {
        package TestPkg7;
        Func::Util->import('is_array', 'is_hash', 'is_string', 'memo');

        main::ok(is_array([]), 'is_array');
        main::ok(!is_array({}), 'is_array false');
        main::ok(is_hash({}), 'is_hash');
        main::ok(!is_hash([]), 'is_hash false');
        main::ok(is_string('hello'), 'is_string');
        main::ok(!is_string([]), 'is_string false');

        # memo
        my $count = 0;
        my $fn = memo(sub { $count++; $_[0] * 2 });
        main::is($fn->(5), 10, 'memo first');
        main::is($fn->(5), 10, 'memo cached');
        main::is($count, 1, 'memo only called once');
    }
};

done_testing;
