#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


use_ok('Func::Util');
use Func::Util qw(
    is_ref is_array is_hash is_code is_defined is_string
    is_num is_int is_blessed is_scalar_ref is_regex is_glob
    is_true is_false bool
);

# ============================================
# is_ref - any reference type
# ============================================

subtest 'is_ref basic types' => sub {
    # Non-references
    ok(!is_ref(undef), 'is_ref: undef');
    ok(!is_ref(0), 'is_ref: 0');
    ok(!is_ref(1), 'is_ref: 1');
    ok(!is_ref(''), 'is_ref: empty string');
    ok(!is_ref('string'), 'is_ref: string');
    ok(!is_ref(3.14), 'is_ref: float');

    # References
    ok(is_ref([]), 'is_ref: empty array');
    ok(is_ref([1,2,3]), 'is_ref: array');
    ok(is_ref({}), 'is_ref: empty hash');
    ok(is_ref({a=>1}), 'is_ref: hash');
    ok(is_ref(sub {}), 'is_ref: code');
    ok(is_ref(\my $x), 'is_ref: scalar ref');
    ok(is_ref(qr/test/), 'is_ref: regex');
};

subtest 'is_ref edge cases' => sub {
    # Blessed references are still refs
    my $obj = bless {}, 'MyClass';
    ok(is_ref($obj), 'is_ref: blessed hash');

    my $arr_obj = bless [], 'MyArray';
    ok(is_ref($arr_obj), 'is_ref: blessed array');

    # Nested refs
    my $nested = \[1,2,3];
    ok(is_ref($nested), 'is_ref: nested ref');

    # Ref to ref
    my $val = 42;
    my $ref = \$val;
    my $refref = \$ref;
    ok(is_ref($refref), 'is_ref: ref to ref');
};

# ============================================
# is_array
# ============================================

subtest 'is_array basic' => sub {
    # Not arrays
    ok(!is_array(undef), 'is_array: undef');
    ok(!is_array(0), 'is_array: 0');
    ok(!is_array(''), 'is_array: empty string');
    ok(!is_array({}), 'is_array: hash');
    ok(!is_array(sub {}), 'is_array: code');
    ok(!is_array(\my $x), 'is_array: scalar ref');

    # Arrays
    ok(is_array([]), 'is_array: empty array');
    ok(is_array([1]), 'is_array: single element');
    ok(is_array([1,2,3]), 'is_array: multiple elements');
    ok(is_array([[],[]]), 'is_array: nested arrays');
};

subtest 'is_array edge cases' => sub {
    # Blessed array
    my $obj = bless [], 'ArrayClass';
    ok(is_array($obj), 'is_array: blessed array');

    # Blessed hash is not array
    my $hash_obj = bless {}, 'HashClass';
    ok(!is_array($hash_obj), 'is_array: blessed hash');

    # Array with undef elements
    my $arr = [undef, undef];
    ok(is_array($arr), 'is_array: array of undefs');
};

# ============================================
# is_hash
# ============================================

subtest 'is_hash basic' => sub {
    # Not hashes
    ok(!is_hash(undef), 'is_hash: undef');
    ok(!is_hash(0), 'is_hash: 0');
    ok(!is_hash(''), 'is_hash: empty string');
    ok(!is_hash([]), 'is_hash: array');
    ok(!is_hash(sub {}), 'is_hash: code');
    ok(!is_hash(\my $x), 'is_hash: scalar ref');

    # Hashes
    ok(is_hash({}), 'is_hash: empty hash');
    ok(is_hash({a => 1}), 'is_hash: single key');
    ok(is_hash({a => 1, b => 2}), 'is_hash: multiple keys');
    ok(is_hash({nested => {}}), 'is_hash: nested hash');
};

subtest 'is_hash edge cases' => sub {
    # Blessed hash
    my $obj = bless {}, 'HashClass';
    ok(is_hash($obj), 'is_hash: blessed hash');

    # Blessed array is not hash
    my $arr_obj = bless [], 'ArrayClass';
    ok(!is_hash($arr_obj), 'is_hash: blessed array');

    # Hash with various value types
    my $mixed = {
        str => 'hello',
        num => 42,
        arr => [],
        hash => {},
        undef => undef,
    };
    ok(is_hash($mixed), 'is_hash: mixed values');
};

# ============================================
# is_code
# ============================================

subtest 'is_code basic' => sub {
    # Not code
    ok(!is_code(undef), 'is_code: undef');
    ok(!is_code(0), 'is_code: 0');
    ok(!is_code(''), 'is_code: empty string');
    ok(!is_code([]), 'is_code: array');
    ok(!is_code({}), 'is_code: hash');
    ok(!is_code(\my $x), 'is_code: scalar ref');

    # Code
    ok(is_code(sub {}), 'is_code: empty sub');
    ok(is_code(sub { 42 }), 'is_code: sub returning value');
    ok(is_code(sub { my $x = shift; $x * 2 }), 'is_code: sub with args');
};

subtest 'is_code edge cases' => sub {
    # Named sub reference
    ok(is_code(\&is_code), 'is_code: named sub ref');

    # Blessed code ref
    my $obj = bless sub {}, 'CodeClass';
    ok(is_code($obj), 'is_code: blessed code');

    # Closure
    my $counter = 0;
    my $closure = sub { $counter++ };
    ok(is_code($closure), 'is_code: closure');
};

# ============================================
# is_defined
# ============================================

subtest 'is_defined basic' => sub {
    # Undefined
    ok(!is_defined(undef), 'is_defined: undef');

    # Defined values (including falsy)
    ok(is_defined(0), 'is_defined: 0');
    ok(is_defined(''), 'is_defined: empty string');
    ok(is_defined('0'), 'is_defined: string 0');
    ok(is_defined(1), 'is_defined: 1');
    ok(is_defined('string'), 'is_defined: string');
    ok(is_defined([]), 'is_defined: array');
    ok(is_defined({}), 'is_defined: hash');
    ok(is_defined(sub {}), 'is_defined: code');
};

subtest 'is_defined edge cases' => sub {
    # Empty list element (hash with undef value)
    my %h = (key => undef);
    ok(!is_defined($h{key}), 'is_defined: hash undef value');
    ok(is_defined($h{key} // 'default'), 'is_defined: defaulted value');

    # Array element
    my @a = (undef, 1, undef);
    ok(!is_defined($a[0]), 'is_defined: array undef element');
    ok(is_defined($a[1]), 'is_defined: array defined element');
};

# ============================================
# is_string
# ============================================

subtest 'is_string basic' => sub {
    # Not strings (undefined or references)
    ok(!is_string(undef), 'is_string: undef');
    ok(!is_string([]), 'is_string: array');
    ok(!is_string({}), 'is_string: hash');
    ok(!is_string(sub {}), 'is_string: code');
    ok(!is_string(\my $x), 'is_string: scalar ref');

    # Strings (defined non-refs)
    ok(is_string(''), 'is_string: empty string');
    ok(is_string('hello'), 'is_string: string');
    ok(is_string(0), 'is_string: 0');
    ok(is_string(42), 'is_string: integer');
    ok(is_string(3.14), 'is_string: float');
    ok(is_string('0'), 'is_string: string 0');
};

subtest 'is_string edge cases' => sub {
    # Stringified number
    my $num = 42;
    my $str = "$num";
    ok(is_string($str), 'is_string: stringified number');

    # Blessed reference is not a string
    my $obj = bless {}, 'Class';
    ok(!is_string($obj), 'is_string: blessed ref');

    # Large number
    ok(is_string(1e100), 'is_string: large number');

    # Negative
    ok(is_string(-42), 'is_string: negative');
};

# ============================================
# is_num
# ============================================

subtest 'is_num basic' => sub {
    # Not numbers
    ok(!is_num(undef), 'is_num: undef');
    ok(!is_num('hello'), 'is_num: non-numeric string');
    ok(!is_num(''), 'is_num: empty string');
    ok(!is_num([]), 'is_num: array');
    ok(!is_num({}), 'is_num: hash');

    # Numbers
    ok(is_num(0), 'is_num: 0');
    ok(is_num(42), 'is_num: positive int');
    ok(is_num(-42), 'is_num: negative int');
    ok(is_num(3.14), 'is_num: float');
    ok(is_num(-3.14), 'is_num: negative float');
    ok(is_num(1e10), 'is_num: scientific notation');
};

subtest 'is_num edge cases' => sub {
    # String that looks like number
    ok(is_num('42'), 'is_num: string 42');
    ok(is_num('3.14'), 'is_num: string 3.14');
    ok(is_num('-5'), 'is_num: string -5');
    ok(is_num('1e10'), 'is_num: string scientific');

    # Special values (Perl's looks_like_number considers these numeric)
    ok(is_num(0.0), 'is_num: 0.0');
    ok(is_num('NaN'), 'is_num: string NaN (Perl considers numeric)');
    ok(is_num('inf'), 'is_num: string inf (Perl considers numeric)');

    # Whitespace (Perl's looks_like_number accepts leading/trailing spaces)
    ok(is_num('  42  '), 'is_num: number with spaces (Perl accepts)');
    ok(!is_num('42abc'), 'is_num: number with trailing text');
};

# ============================================
# is_int
# ============================================

subtest 'is_int basic' => sub {
    # Not integers
    ok(!is_int(undef), 'is_int: undef');
    ok(!is_int('hello'), 'is_int: string');
    ok(!is_int(3.14), 'is_int: float');
    ok(!is_int(-3.14), 'is_int: negative float');
    ok(!is_int([]), 'is_int: array');

    # Integers
    ok(is_int(0), 'is_int: 0');
    ok(is_int(42), 'is_int: positive');
    ok(is_int(-42), 'is_int: negative');
    ok(is_int(1000000), 'is_int: large');
};

subtest 'is_int edge cases' => sub {
    # Whole number floats
    ok(is_int(5.0), 'is_int: 5.0');
    ok(is_int(-10.0), 'is_int: -10.0');

    # Very close to integer
    ok(!is_int(5.0001), 'is_int: 5.0001');
    ok(!is_int(4.9999), 'is_int: 4.9999');

    # String integers
    ok(is_int('42'), 'is_int: string 42');
    ok(is_int('-5'), 'is_int: string -5');
};

# ============================================
# is_blessed
# ============================================

subtest 'is_blessed basic' => sub {
    # Not blessed
    ok(!is_blessed(undef), 'is_blessed: undef');
    ok(!is_blessed(42), 'is_blessed: number');
    ok(!is_blessed('string'), 'is_blessed: string');
    ok(!is_blessed([]), 'is_blessed: unblessed array');
    ok(!is_blessed({}), 'is_blessed: unblessed hash');
    ok(!is_blessed(sub {}), 'is_blessed: unblessed code');

    # Blessed
    my $obj = bless {}, 'MyClass';
    ok(is_blessed($obj), 'is_blessed: blessed hash');

    my $arr = bless [], 'MyArray';
    ok(is_blessed($arr), 'is_blessed: blessed array');

    my $code = bless sub {}, 'MyCode';
    ok(is_blessed($code), 'is_blessed: blessed code');
};

subtest 'is_blessed edge cases' => sub {
    # Blessed scalar ref
    my $val = 42;
    my $obj = bless \$val, 'ScalarClass';
    ok(is_blessed($obj), 'is_blessed: blessed scalar ref');

    # Blessed into main package
    my $main_obj = bless {}, 'main';
    ok(is_blessed($main_obj), 'is_blessed: blessed into main');
};

# ============================================
# is_scalar_ref
# ============================================

subtest 'is_scalar_ref basic' => sub {
    # Not scalar refs
    ok(!is_scalar_ref(undef), 'is_scalar_ref: undef');
    ok(!is_scalar_ref(42), 'is_scalar_ref: number');
    ok(!is_scalar_ref('string'), 'is_scalar_ref: string');
    ok(!is_scalar_ref([]), 'is_scalar_ref: array');
    ok(!is_scalar_ref({}), 'is_scalar_ref: hash');
    ok(!is_scalar_ref(sub {}), 'is_scalar_ref: code');

    # Scalar refs
    my $val = 42;
    ok(is_scalar_ref(\$val), 'is_scalar_ref: ref to number');

    my $str = 'hello';
    ok(is_scalar_ref(\$str), 'is_scalar_ref: ref to string');

    my $undef;
    ok(is_scalar_ref(\$undef), 'is_scalar_ref: ref to undef');
};

# ============================================
# is_regex
# ============================================

subtest 'is_regex basic' => sub {
    # Not regex
    ok(!is_regex(undef), 'is_regex: undef');
    ok(!is_regex(42), 'is_regex: number');
    ok(!is_regex('pattern'), 'is_regex: string pattern');
    ok(!is_regex([]), 'is_regex: array');
    ok(!is_regex({}), 'is_regex: hash');

    # Regex
    ok(is_regex(qr//), 'is_regex: empty regex');
    ok(is_regex(qr/test/), 'is_regex: simple regex');
    ok(is_regex(qr/test/i), 'is_regex: regex with flags');
    ok(is_regex(qr/^\d+$/), 'is_regex: complex regex');
};

# ============================================
# is_glob
# ============================================

subtest 'is_glob basic' => sub {
    # Not globs
    ok(!is_glob(undef), 'is_glob: undef');
    ok(!is_glob(42), 'is_glob: number');
    ok(!is_glob('*STDOUT'), 'is_glob: string');
    ok(!is_glob([]), 'is_glob: array');
    ok(!is_glob({}), 'is_glob: hash');

    # Globs
    ok(is_glob(*STDOUT), 'is_glob: STDOUT');
    ok(is_glob(*STDERR), 'is_glob: STDERR');
    ok(is_glob(*STDIN), 'is_glob: STDIN');
};

# ============================================
# is_true / is_false / bool
# ============================================

subtest 'is_true basic' => sub {
    # False values
    ok(!is_true(undef), 'is_true: undef');
    ok(!is_true(0), 'is_true: 0');
    ok(!is_true(''), 'is_true: empty string');
    ok(!is_true('0'), 'is_true: string 0');

    # True values
    ok(is_true(1), 'is_true: 1');
    ok(is_true(-1), 'is_true: -1');
    ok(is_true('1'), 'is_true: string 1');
    ok(is_true('hello'), 'is_true: string');
    ok(is_true([]), 'is_true: empty array (ref is true)');
    ok(is_true({}), 'is_true: empty hash (ref is true)');
    ok(is_true(sub {}), 'is_true: code ref');
};

subtest 'is_false basic' => sub {
    # False values
    ok(is_false(undef), 'is_false: undef');
    ok(is_false(0), 'is_false: 0');
    ok(is_false(''), 'is_false: empty string');
    ok(is_false('0'), 'is_false: string 0');

    # True values
    ok(!is_false(1), 'is_false: 1');
    ok(!is_false(-1), 'is_false: -1');
    ok(!is_false('hello'), 'is_false: string');
    ok(!is_false([]), 'is_false: array ref');
};

subtest 'bool basic' => sub {
    # Normalize to false (empty string)
    is(bool(undef), '', 'bool: undef -> empty');
    is(bool(0), '', 'bool: 0 -> empty');
    is(bool(''), '', 'bool: empty -> empty');
    is(bool('0'), '', 'bool: string 0 -> empty');

    # Normalize to true (1)
    is(bool(1), 1, 'bool: 1 -> 1');
    is(bool(-1), 1, 'bool: -1 -> 1');
    is(bool('hello'), 1, 'bool: string -> 1');
    is(bool([]), 1, 'bool: array -> 1');
    is(bool({}), 1, 'bool: hash -> 1');
};

subtest 'is_true/is_false edge cases' => sub {
    # String that looks numeric
    ok(is_true('00'), 'is_true: string 00 is true');
    ok(is_true('0.0'), 'is_true: string 0.0 is true');
    ok(is_true('0e0'), 'is_true: string 0e0 is true');

    # Numeric zero variations
    ok(!is_true(0.0), 'is_true: 0.0 is false');
    ok(!is_true(-0), 'is_true: -0 is false');

    # Whitespace
    ok(is_true(' '), 'is_true: space is true');
    ok(is_true("\t"), 'is_true: tab is true');
    ok(is_true("\n"), 'is_true: newline is true');
};

done_testing;
