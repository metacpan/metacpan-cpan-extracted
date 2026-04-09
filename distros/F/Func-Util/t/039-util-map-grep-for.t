#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Test util module functions work correctly in map/grep/for contexts
# This ensures call checkers properly handle $_ usage

use Func::Util qw(
    is_num is_int is_positive is_negative is_zero is_defined
    is_array is_hash is_code is_ref is_string is_empty
    is_even is_odd is_between
    trim ltrim rtrim starts_with ends_with
    clamp sign min2 max2
    first any all none count
    pick pluck omit uniq partition
    nvl coalesce
    array_first array_last array_len
);

# ============================================
# Numeric predicates in map/grep
# ============================================

subtest 'is_num in map' => sub {
    my @values = (1, 2.5, 'hello', undef, 3, '4abc');
    my @results = map { is_num($_) ? 1 : 0 } @values;
    is_deeply(\@results, [1, 1, 0, 0, 1, 0], 'is_num in map');
};

subtest 'is_num in grep' => sub {
    my @values = (1, 'two', 3.14, undef, 5);
    my @nums = grep { is_num($_) } @values;
    is_deeply(\@nums, [1, 3.14, 5], 'is_num in grep');
};

subtest 'is_int in grep' => sub {
    my @values = (1, 2.5, 3, 4.0, 5.5);
    my @ints = grep { is_int($_) } @values;
    is_deeply(\@ints, [1, 3, 4.0], 'is_int in grep');
};

subtest 'is_positive/is_negative in map' => sub {
    my @values = (-2, -1, 0, 1, 2);
    my @pos = map { is_positive($_) ? 1 : 0 } @values;
    my @neg = map { is_negative($_) ? 1 : 0 } @values;
    is_deeply(\@pos, [0, 0, 0, 1, 1], 'is_positive in map');
    is_deeply(\@neg, [1, 1, 0, 0, 0], 'is_negative in map');
};

subtest 'is_even/is_odd in grep' => sub {
    my @nums = 1..10;
    my @evens = grep { is_even($_) } @nums;
    my @odds = grep { is_odd($_) } @nums;
    is_deeply(\@evens, [2, 4, 6, 8, 10], 'is_even in grep');
    is_deeply(\@odds, [1, 3, 5, 7, 9], 'is_odd in grep');
};

subtest 'is_zero in grep' => sub {
    my @values = (0, 1, 0.0, '', undef, 0);
    my @zeros = grep { defined($_) && is_num($_) && is_zero($_) } @values;
    is($#zeros + 1, 3, 'is_zero found 3 zeros');
};

subtest 'is_between in grep' => sub {
    my @nums = 1..20;
    my @between = grep { is_between($_, 5, 15) } @nums;
    is_deeply(\@between, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], 'is_between in grep');
};

# ============================================
# Type predicates in map/grep
# ============================================

subtest 'is_defined in grep' => sub {
    my @values = (1, undef, 'hello', undef, []);
    my @defined = grep { is_defined($_) } @values;
    is(scalar(@defined), 3, 'is_defined found 3 defined values');
};

subtest 'is_array/is_hash in map' => sub {
    my @values = ([], {}, 'string', [1,2], {a=>1});
    my @arr_flags = map { is_array($_) ? 1 : 0 } @values;
    my @hash_flags = map { is_hash($_) ? 1 : 0 } @values;
    is_deeply(\@arr_flags, [1, 0, 0, 1, 0], 'is_array in map');
    is_deeply(\@hash_flags, [0, 1, 0, 0, 1], 'is_hash in map');
};

subtest 'is_ref in grep' => sub {
    my @values = (1, [], {}, 'string', sub {}, \my $x);
    my @refs = grep { is_ref($_) } @values;
    is(scalar(@refs), 4, 'is_ref found 4 references');
};

subtest 'is_code in grep' => sub {
    my @values = (sub {}, sub { 1 }, 'string', [], {});
    my @codes = grep { is_code($_) } @values;
    is(scalar(@codes), 2, 'is_code found 2 code refs');
};

# ============================================
# String functions in map/grep
# ============================================

subtest 'trim in map' => sub {
    my @strings = ('  hello  ', 'world  ', '  foo', 'bar');
    my @trimmed = map { trim($_) } @strings;
    is_deeply(\@trimmed, ['hello', 'world', 'foo', 'bar'], 'trim in map');
};

subtest 'ltrim/rtrim in map' => sub {
    my @strings = ('  hello  ', '  world');
    my @left = map { ltrim($_) } @strings;
    my @right = map { rtrim($_) } @strings;
    is_deeply(\@left, ['hello  ', 'world'], 'ltrim in map');
    is_deeply(\@right, ['  hello', '  world'], 'rtrim in map');
};

subtest 'starts_with in grep' => sub {
    my @words = qw(apple apricot banana avocado orange);
    my @a_words = grep { starts_with($_, 'a') } @words;
    is_deeply(\@a_words, ['apple', 'apricot', 'avocado'], 'starts_with in grep');
};

subtest 'ends_with in grep' => sub {
    my @files = qw(test.txt data.csv log.txt readme.md notes.txt);
    my @txt_files = grep { ends_with($_, '.txt') } @files;
    is_deeply(\@txt_files, ['test.txt', 'log.txt', 'notes.txt'], 'ends_with in grep');
};

subtest 'is_empty in grep' => sub {
    my @strings = ('hello', '', '  ', 'world', undef);
    my @non_empty = grep { !is_empty($_) } @strings;
    is(scalar(@non_empty), 3, 'is_empty filters correctly');
};

# ============================================
# Numeric functions in map
# ============================================

subtest 'clamp in map' => sub {
    my @values = (-5, 0, 5, 10, 15, 20);
    my @clamped = map { clamp($_, 0, 10) } @values;
    is_deeply(\@clamped, [0, 0, 5, 10, 10, 10], 'clamp in map');
};

subtest 'sign in map' => sub {
    my @values = (-5, -1, 0, 1, 5);
    my @signs = map { sign($_) } @values;
    is_deeply(\@signs, [-1, -1, 0, 1, 1], 'sign in map');
};

subtest 'min2/max2 in map' => sub {
    my @pairs = ([1, 5], [3, 2], [7, 7], [0, 10]);
    my @mins = map { min2($_->[0], $_->[1]) } @pairs;
    my @maxs = map { max2($_->[0], $_->[1]) } @pairs;
    is_deeply(\@mins, [1, 2, 7, 0], 'min2 in map');
    is_deeply(\@maxs, [5, 3, 7, 10], 'max2 in map');
};

# ============================================
# Collection functions with callbacks in map/grep
# ============================================

subtest 'first in map over arrays' => sub {
    my @arrays = ([1, 2, 3], [10, 20, 30], [5, 15, 25]);
    # first takes a list, not arrayref - use @$_ to flatten
    my @firsts = map { first(sub { $_ > 5 }, @$_) } @arrays;
    is_deeply(\@firsts, [undef, 10, 15], 'first with callback in map');
};

subtest 'any in map over arrays' => sub {
    my @arrays = ([1, 2, 3], [1, 10, 3], [7, 8, 9]);
    my @has_gt5 = map { any(sub { $_ > 5 }, @$_) ? 1 : 0 } @arrays;
    is_deeply(\@has_gt5, [0, 1, 1], 'any with callback in map');
};

subtest 'all in map over arrays' => sub {
    my @arrays = ([1, 2, 3], [6, 7, 8], [10, 11, 12]);
    my @all_gt5 = map { all(sub { $_ > 5 }, @$_) ? 1 : 0 } @arrays;
    is_deeply(\@all_gt5, [0, 1, 1], 'all with callback in map');
};

subtest 'none in map over arrays' => sub {
    my @arrays = ([1, 2, 3], [1, 6, 3], [4, 5, 6]);
    my @none_gt5 = map { none(sub { $_ > 5 }, @$_) ? 1 : 0 } @arrays;
    is_deeply(\@none_gt5, [1, 0, 0], 'none with callback in map');
};

subtest 'count in map over arrays' => sub {
    # count matching elements using grep
    my @arrays = ([1, 2, 3, 4, 5], [10, 20, 3, 4, 50], [1, 1, 1, 1, 1]);
    # [1,2,3,4,5] > 3: 4, 5 = 2
    # [10,20,3,4,50] > 3: 10, 20, 4, 50 = 4
    # [1,1,1,1,1] > 3: none = 0
    my @counts = map {
        my $arr = $_;
        my $c = 0;
        $c++ for grep { $_ > 3 } @$arr;
        $c
    } @arrays;
    is_deeply(\@counts, [2, 4, 0], 'count with grep in map');
};

# ============================================
# Transform functions in map
# ============================================

subtest 'pick in map over hashes' => sub {
    my @hashes = (
        { a => 1, b => 2, c => 3 },
        { a => 10, b => 20, c => 30 },
    );
    # pick returns hashref in scalar context
    my @picked = map { scalar pick($_, qw(a c)) } @hashes;
    is_deeply($picked[0], { a => 1, c => 3 }, 'pick in map [0]');
    is_deeply($picked[1], { a => 10, c => 30 }, 'pick in map [1]');
};

subtest 'omit in map over hashes' => sub {
    my @hashes = (
        { a => 1, b => 2, c => 3 },
        { a => 10, b => 20, c => 30 },
    );
    # omit returns hashref in scalar context
    my @omitted = map { scalar omit($_, qw(b)) } @hashes;
    is_deeply($omitted[0], { a => 1, c => 3 }, 'omit in map [0]');
    is_deeply($omitted[1], { a => 10, c => 30 }, 'omit in map [1]');
};

subtest 'pluck in map' => sub {
    my @datasets = (
        [{ name => 'a', val => 1 }, { name => 'b', val => 2 }],
        [{ name => 'x', val => 10 }, { name => 'y', val => 20 }],
    );
    my @names = map { pluck($_, 'name') } @datasets;
    is_deeply($names[0], ['a', 'b'], 'pluck names [0]');
    is_deeply($names[1], ['x', 'y'], 'pluck names [1]');
};

subtest 'uniq in map over arrays' => sub {
    my @arrays = (
        [1, 2, 2, 3, 3, 3],
        ['a', 'b', 'a', 'c'],
    );
    # uniq takes a list, returns list - wrap result in arrayref
    my @unique = map { [ uniq(@$_) ] } @arrays;
    is_deeply($unique[0], [1, 2, 3], 'uniq numbers');
    is_deeply($unique[1], ['a', 'b', 'c'], 'uniq strings');
};

# ============================================
# Coalesce functions in map
# ============================================

subtest 'nvl in map' => sub {
    my @values = (1, undef, 3, undef, 5);
    my @filled = map { nvl($_, 0) } @values;
    is_deeply(\@filled, [1, 0, 3, 0, 5], 'nvl in map');
};

subtest 'coalesce in map' => sub {
    my @rows = (
        [undef, undef, 'default'],
        ['first', undef, 'default'],
        [undef, 'second', 'default'],
    );
    my @results = map { coalesce(@$_) } @rows;
    is_deeply(\@results, ['default', 'first', 'second'], 'coalesce in map');
};

# ============================================
# Array accessors in map
# ============================================

subtest 'array_first/array_last in map' => sub {
    my @arrays = ([1, 2, 3], [10, 20], [100]);
    my @firsts = map { array_first($_) } @arrays;
    my @lasts = map { array_last($_) } @arrays;
    is_deeply(\@firsts, [1, 10, 100], 'array_first in map');
    is_deeply(\@lasts, [3, 20, 100], 'array_last in map');
};

subtest 'array_len in map' => sub {
    my @arrays = ([], [1], [1, 2, 3], [1, 2, 3, 4, 5]);
    my @lens = map { array_len($_) } @arrays;
    is_deeply(\@lens, [0, 1, 3, 5], 'array_len in map');
};

# ============================================
# for/foreach loops with util functions
# ============================================

subtest 'is_num in foreach' => sub {
    my @values = (1, 'two', 3, undef, 5);
    my @nums;
    for (@values) {
        push @nums, $_ if is_num($_);
    }
    is_deeply(\@nums, [1, 3, 5], 'is_num in foreach');
};

subtest 'trim in foreach' => sub {
    my @strings = ('  a  ', '  b  ', '  c  ');
    my @trimmed;
    for (@strings) {
        push @trimmed, trim($_);
    }
    is_deeply(\@trimmed, ['a', 'b', 'c'], 'trim in foreach');
};

subtest 'clamp in foreach' => sub {
    my @values = (-10, 0, 5, 10, 20);
    my @clamped;
    for (@values) {
        push @clamped, clamp($_, 0, 10);
    }
    is_deeply(\@clamped, [0, 0, 5, 10, 10], 'clamp in foreach');
};

subtest 'nested for with predicates' => sub {
    my @groups = ([1, 2, 3], [4, 5, 6], [7, 8, 9]);
    my @results;
    for my $group (@groups) {
        my $count = 0;
        for (@$group) {
            $count++ if is_odd($_);
        }
        push @results, $count;
    }
    is_deeply(\@results, [2, 1, 2], 'nested for with is_odd');
};

# ============================================
# partition in various contexts
# ============================================

subtest 'partition in map' => sub {
    my @arrays = ([1, 2, 3, 4, 5], [10, 15, 20, 25]);
    # partition(sub, list) returns ([matched], [unmatched]) as first element
    my @partitions = map {
        my @result = partition(sub { $_ % 2 == 0 }, @$_);
        # result[0] is [[evens], [odds]]
        { even => $result[0][0], odd => $result[0][1] }
    } @arrays;
    is_deeply($partitions[0]{even}, [2, 4], 'partition evens [0]');
    is_deeply($partitions[0]{odd}, [1, 3, 5], 'partition odds [0]');
    is_deeply($partitions[1]{even}, [10, 20], 'partition evens [1]');
    is_deeply($partitions[1]{odd}, [15, 25], 'partition odds [1]');
};

# ============================================
# Chained operations
# ============================================

subtest 'chained map operations' => sub {
    my @strings = ('  -5  ', '  10  ', '  hello  ', '  3.14  ');

    # Trim, filter numbers, clamp
    my @results =
        map { clamp($_, 0, 5) }
        grep { is_num($_) }
        map { trim($_) }
        @strings;

    is_deeply(\@results, [0, 5, 3.14], 'chained trim -> filter -> clamp');
};

subtest 'complex pipeline' => sub {
    my @data = (
        { name => '  Alice  ', score => 85 },
        { name => '  Bob  ', score => 92 },
        { name => '  Charlie  ', score => 78 },
        { name => '  Diana  ', score => 95 },
    );

    # Trim names, filter high scores, extract names
    my @high_scorers =
        map { trim($_->{name}) }
        grep { $_->{score} >= 90 }
        @data;

    is_deeply(\@high_scorers, ['Bob', 'Diana'], 'complex pipeline');
};

done_testing();
