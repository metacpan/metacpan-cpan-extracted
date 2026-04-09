#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test is_array
ok(Func::Util::is_array([1, 2, 3]), 'is_array: arrayref is array');
ok(!Func::Util::is_array({a => 1}), 'is_array: hashref is not array');
ok(!Func::Util::is_array('hello'), 'is_array: string is not array');
ok(!Func::Util::is_array(42), 'is_array: number is not array');

# Test is_hash
ok(Func::Util::is_hash({a => 1}), 'is_hash: hashref is hash');
ok(!Func::Util::is_hash([1, 2, 3]), 'is_hash: arrayref is not hash');
ok(!Func::Util::is_hash('hello'), 'is_hash: string is not hash');

# Test is_code
ok(Func::Util::is_code(sub { 1 }), 'is_code: coderef is code');
ok(!Func::Util::is_code([1, 2, 3]), 'is_code: arrayref is not code');
ok(!Func::Util::is_code('hello'), 'is_code: string is not code');

# Test is_scalar_ref
my $x = 42;
ok(Func::Util::is_scalar_ref(\$x), 'is_scalar_ref: scalar ref is scalar ref');
ok(!Func::Util::is_scalar_ref([1, 2, 3]), 'is_scalar_ref: arrayref is not scalar ref');
ok(!Func::Util::is_scalar_ref(42), 'is_scalar_ref: number is not scalar ref');

# Test is_ref
ok(Func::Util::is_ref([1, 2, 3]), 'is_ref: arrayref is ref');
ok(Func::Util::is_ref({a => 1}), 'is_ref: hashref is ref');
ok(Func::Util::is_ref(sub { 1 }), 'is_ref: coderef is ref');
ok(!Func::Util::is_ref('hello'), 'is_ref: string is not ref');
ok(!Func::Util::is_ref(42), 'is_ref: number is not ref');

# Test is_regex
my $rx = qr/test/;
ok(Func::Util::is_regex($rx), 'is_regex: qr// is regex');
ok(!Func::Util::is_regex('test'), 'is_regex: string is not regex');
ok(!Func::Util::is_regex([1, 2]), 'is_regex: arrayref is not regex');

# Test is_glob
ok(Func::Util::is_glob(*STDOUT), 'is_glob: *STDOUT is glob');
ok(!Func::Util::is_glob('hello'), 'is_glob: string is not glob');

# Test is_blessed
my $obj = bless {}, 'MyClass';
ok(Func::Util::is_blessed($obj), 'is_blessed: blessed ref is blessed');
ok(!Func::Util::is_blessed({a => 1}), 'is_blessed: unblessed hashref is not blessed');
ok(!Func::Util::is_blessed('hello'), 'is_blessed: string is not blessed');

done_testing();
