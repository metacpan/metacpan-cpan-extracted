#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


use_ok('Func::Util');
use Func::Util qw(
    memo pipeline compose partial
    lazy force
    dig tap
    nvl coalesce
    identity always noop
    stub_true stub_false stub_array stub_hash stub_string stub_zero
    negate once maybe
);

# ============================================
# memo - memoization
# ============================================

subtest 'memo basic' => sub {
    my $call_count = 0;
    my $double = memo(sub { $call_count++; $_[0] * 2 });

    is($double->(5), 10, 'memo: first call returns correct value');
    is($call_count, 1, 'memo: first call executes function');

    is($double->(5), 10, 'memo: cached call returns correct value');
    is($call_count, 1, 'memo: cached call does not execute function');

    is($double->(10), 20, 'memo: different arg executes function');
    is($call_count, 2, 'memo: second unique arg increments count');
};

subtest 'memo multiple args' => sub {
    my $call_count = 0;
    my $add = memo(sub { $call_count++; $_[0] + $_[1] });

    is($add->(2, 3), 5, 'memo: multi-arg first call');
    is($call_count, 1, 'memo: multi-arg count 1');

    is($add->(2, 3), 5, 'memo: multi-arg cached');
    is($call_count, 1, 'memo: multi-arg still 1');

    is($add->(3, 2), 5, 'memo: different arg order');
    is($call_count, 2, 'memo: different order = new call');
};

subtest 'memo edge cases' => sub {
    # Memoizing with undef argument
    my $count = 0;
    my $fn = memo(sub { $count++; defined $_[0] ? $_[0] : 'default' });

    is($fn->(undef), 'default', 'memo: undef arg first');
    is($count, 1, 'memo: undef counted');
    is($fn->(undef), 'default', 'memo: undef cached');
    is($count, 1, 'memo: undef still 1');

    # Memoizing with empty string
    is($fn->(''), '', 'memo: empty string');
    is($count, 2, 'memo: empty string is new');
    is($fn->(''), '', 'memo: empty string cached');
    is($count, 2, 'memo: empty string still 2');
};

# ============================================
# pipeline - chain function calls
# ============================================

subtest 'pipeline basic' => sub {
    my $result = pipeline(5,
        sub { $_[0] * 2 },      # 10
        sub { $_[0] + 3 },      # 13
        sub { $_[0] * 2 }       # 26
    );
    is($result, 26, 'pipeline: chained operations');
};

subtest 'pipeline edge cases' => sub {
    # Single function
    my $result = pipeline(5, sub { $_[0] * 2 });
    is($result, 10, 'pipeline: single function');

    # With identity
    $result = pipeline(5,
        sub { $_[0] * 2 },
        \&identity,
        sub { $_[0] + 1 }
    );
    is($result, 11, 'pipeline: with identity');

    # Starting with undef
    $result = pipeline(undef, sub { defined $_[0] ? $_[0] : 0 });
    is($result, 0, 'pipeline: starting with undef');
};

# ============================================
# compose - create composed function
# ============================================

subtest 'compose basic' => sub {
    my $fn = compose(
        sub { $_[0] * 2 },     # applied third
        sub { $_[0] + 3 },     # applied second
        sub { $_[0] * 2 }      # applied first
    );
    # 5 -> 10 -> 13 -> 26
    is($fn->(5), 26, 'compose: right-to-left');
};

subtest 'compose edge cases' => sub {
    # Single function
    my $fn = compose(sub { $_[0] * 2 });
    is($fn->(5), 10, 'compose: single function');

    # Composed function is reusable
    my $double_then_add = compose(
        sub { $_[0] + 1 },
        sub { $_[0] * 2 }
    );
    is($double_then_add->(5), 11, 'compose: first call');
    is($double_then_add->(10), 21, 'compose: second call');
};

# ============================================
# partial - partial application
# ============================================

subtest 'partial basic' => sub {
    my $add = sub { $_[0] + $_[1] };
    my $add5 = partial($add, 5);

    is($add5->(3), 8, 'partial: 5 + 3');
    is($add5->(10), 15, 'partial: 5 + 10');
    is($add5->(0), 5, 'partial: 5 + 0');
};

subtest 'partial multiple args' => sub {
    my $concat = sub { join('', @_) };

    my $greet = partial($concat, 'Hello, ');
    is($greet->('World'), 'Hello, World', 'partial: greeting');

    my $full_greet = partial($concat, 'Hello, ', 'dear ');
    is($full_greet->('friend'), 'Hello, dear friend', 'partial: multiple bound');
};

subtest 'partial edge cases' => sub {
    # Partial with no additional args needed
    my $get_pi = partial(sub { 3.14159 });
    is($get_pi->(), 3.14159, 'partial: no args');

    # Partial with undef
    my $nvl_42 = partial(sub { defined $_[0] ? $_[0] : $_[1] }, undef);
    is($nvl_42->(99), 99, 'partial: undef bound');
};

# ============================================
# lazy / force
# ============================================

subtest 'lazy/force basic' => sub {
    my $call_count = 0;
    my $expensive = lazy(sub { $call_count++; 42 });

    is($call_count, 0, 'lazy: not executed on creation');

    my $result = force($expensive);
    is($result, 42, 'force: returns computed value');
    is($call_count, 1, 'force: executed once');

    $result = force($expensive);
    is($result, 42, 'force: cached value');
    is($call_count, 1, 'force: not re-executed');
};

subtest 'lazy/force edge cases' => sub {
    # Lazy returning undef
    my $lazy_undef = lazy(sub { undef });
    is(force($lazy_undef), undef, 'lazy: can return undef');

    # Lazy returning ref
    my $lazy_ref = lazy(sub { [1, 2, 3] });
    is_deeply(force($lazy_ref), [1, 2, 3], 'lazy: can return ref');

    # Force on non-lazy value
    my $plain = 42;
    is(force($plain), 42, 'force: non-lazy passes through');
    is(force('string'), 'string', 'force: string passes through');
    is_deeply(force([1,2,3]), [1,2,3], 'force: array passes through');
};

# ============================================
# dig - safe hash traversal
# ============================================

subtest 'dig basic' => sub {
    my $data = {
        a => {
            b => {
                c => 42
            }
        }
    };

    is(dig($data, 'a', 'b', 'c'), 42, 'dig: nested access');
    is(dig($data, 'a', 'b'), $data->{a}{b}, 'dig: partial path');
    is(dig($data, 'a'), $data->{a}, 'dig: single key');
};

subtest 'dig missing keys' => sub {
    my $data = {a => {b => 1}};

    is(dig($data, 'x'), undef, 'dig: missing top-level');
    is(dig($data, 'a', 'x'), undef, 'dig: missing nested');
    is(dig($data, 'a', 'b', 'c'), undef, 'dig: path too deep');
};

subtest 'dig edge cases' => sub {
    # Undef at some level
    my $with_undef = {a => {b => undef}};
    is(dig($with_undef, 'a', 'b'), undef, 'dig: undef value');
    is(dig($with_undef, 'a', 'b', 'c'), undef, 'dig: path through undef');

    # Deeply nested
    my $deep = {a => {b => {c => {d => {e => 'deep'}}}}};
    is(dig($deep, 'a', 'b', 'c', 'd', 'e'), 'deep', 'dig: deeply nested');
};

# ============================================
# tap - side effects
# ============================================

subtest 'tap basic' => sub {
    my $captured;
    my $result = tap(sub { $captured = $_[0] }, 42);

    is($result, 42, 'tap: returns original value');
    is($captured, 42, 'tap: side effect executed');
};

subtest 'tap with $_ ' => sub {
    my $captured;
    my $result = tap(sub { $captured = $_ }, 'hello');

    is($result, 'hello', 'tap: returns string');
    is($captured, 'hello', 'tap: $_ set correctly');
};

subtest 'tap edge cases' => sub {
    # With undef
    my $captured = 'not_set';
    my $result = tap(sub { $captured = $_[0] // 'was_undef' }, undef);
    is($result, undef, 'tap: returns undef');
    is($captured, 'was_undef', 'tap: captured undef');

    # With reference
    my $arr = [1, 2, 3];
    $result = tap(sub { push @{$_[0]}, 4 }, $arr);
    is_deeply($result, [1, 2, 3, 4], 'tap: modified ref returned');
};

# ============================================
# nvl - null value logic
# ============================================

subtest 'nvl basic' => sub {
    is(nvl(42, 0), 42, 'nvl: defined value');
    is(nvl(0, 42), 0, 'nvl: zero is defined');
    is(nvl('', 42), '', 'nvl: empty string is defined');
    is(nvl(undef, 42), 42, 'nvl: undef uses default');
};

subtest 'nvl edge cases' => sub {
    is(nvl(undef, undef), undef, 'nvl: both undef');
    is(nvl(undef, 0), 0, 'nvl: default is zero');
    is(nvl(undef, ''), '', 'nvl: default is empty');

    # With refs
    my $default = [1, 2, 3];
    is_deeply(nvl(undef, $default), $default, 'nvl: ref default');
    is_deeply(nvl([], $default), [], 'nvl: defined empty array');
};

# ============================================
# coalesce - first defined
# ============================================

subtest 'coalesce basic' => sub {
    is(coalesce(1, 2, 3), 1, 'coalesce: first');
    is(coalesce(undef, 2, 3), 2, 'coalesce: skip first undef');
    is(coalesce(undef, undef, 3), 3, 'coalesce: skip two undefs');
    is(coalesce(undef, undef, undef), undef, 'coalesce: all undef');
};

subtest 'coalesce edge cases' => sub {
    is(coalesce(0, 1), 0, 'coalesce: zero is defined');
    is(coalesce('', 'default'), '', 'coalesce: empty is defined');
    is(coalesce(undef), undef, 'coalesce: single undef');
};

# ============================================
# identity
# ============================================

subtest 'identity basic' => sub {
    is(identity(42), 42, 'identity: number');
    is(identity('hello'), 'hello', 'identity: string');
    is(identity(undef), undef, 'identity: undef');

    my $arr = [1, 2, 3];
    is(identity($arr), $arr, 'identity: same ref');
};

# ============================================
# always
# ============================================

subtest 'always basic' => sub {
    my $get42 = always(42);
    is($get42->(), 42, 'always: no args');
    is($get42->(1, 2, 3), 42, 'always: ignores args');
    is($get42->('anything'), 42, 'always: always returns same');
};

subtest 'always edge cases' => sub {
    my $get_undef = always(undef);
    is($get_undef->(), undef, 'always: can return undef');

    my $arr = [1, 2, 3];
    my $get_arr = always($arr);
    is($get_arr->(), $arr, 'always: same ref each time');
    is($get_arr->(), $get_arr->(), 'always: consistent ref');
};

# ============================================
# noop
# ============================================

subtest 'noop basic' => sub {
    is(noop(), undef, 'noop: returns undef');
    is(noop(1, 2, 3), undef, 'noop: ignores args');
};

# ============================================
# stub functions
# ============================================

subtest 'stub functions' => sub {
    is(stub_true(), 1, 'stub_true: returns 1');
    is(stub_false(), '', 'stub_false: returns empty');
    is(stub_zero(), 0, 'stub_zero: returns 0');
    is(stub_string(), '', 'stub_string: returns empty');

    # These return fresh refs each time
    my $arr1 = stub_array();
    my $arr2 = stub_array();
    isnt($arr1, $arr2, 'stub_array: different refs');
    is_deeply($arr1, [], 'stub_array: empty array');

    my $hash1 = stub_hash();
    my $hash2 = stub_hash();
    isnt($hash1, $hash2, 'stub_hash: different refs');
    is_deeply($hash1, {}, 'stub_hash: empty hash');
};

# ============================================
# negate
# ============================================

subtest 'negate basic' => sub {
    my $is_even = sub { $_[0] % 2 == 0 };
    my $is_odd = negate($is_even);

    ok($is_odd->(1), 'negate: 1 is odd');
    ok($is_odd->(3), 'negate: 3 is odd');
    ok(!$is_odd->(2), 'negate: 2 is not odd');
    ok(!$is_odd->(4), 'negate: 4 is not odd');
};

subtest 'negate edge cases' => sub {
    # Negate always true
    my $always_true = sub { 1 };
    my $never = negate($always_true);
    ok(!$never->(), 'negate: never true');

    # Negate always false
    my $always_false = sub { 0 };
    my $always = negate($always_false);
    ok($always->(), 'negate: always true');
};

# ============================================
# once
# ============================================

subtest 'once basic' => sub {
    my $count = 0;
    my $init = once(sub { $count++; 'initialized' });

    my $result1 = $init->();
    is($result1, 'initialized', 'once: first call');
    is($count, 1, 'once: count after first');

    my $result2 = $init->();
    is($result2, 'initialized', 'once: cached result');
    is($count, 1, 'once: count still 1');

    my $result3 = $init->();
    is($count, 1, 'once: third call still 1');
};

subtest 'once edge cases' => sub {
    # Once with undef return
    my $called = 0;
    my $fn = once(sub { $called++; undef });
    is($fn->(), undef, 'once: returns undef');
    is($fn->(), undef, 'once: cached undef');
    is($called, 1, 'once: only called once for undef');
};

# ============================================
# maybe
# ============================================

subtest 'maybe basic' => sub {
    is(maybe(1, 'yes'), 'yes', 'maybe: defined returns then');
    is(maybe(0, 'yes'), 'yes', 'maybe: zero is defined');
    is(maybe('', 'yes'), 'yes', 'maybe: empty is defined');
    is(maybe(undef, 'yes'), undef, 'maybe: undef returns undef');
};

subtest 'maybe edge cases' => sub {
    # With refs
    is_deeply(maybe([1], [2,3]), [2,3], 'maybe: array defined');
    is(maybe(undef, [2,3]), undef, 'maybe: array undef');

    # Chained
    my $val = maybe(1, maybe(1, 'deep'));
    is($val, 'deep', 'maybe: chained both defined');

    $val = maybe(undef, maybe(1, 'deep'));
    is($val, undef, 'maybe: outer undef');
};

done_testing;
