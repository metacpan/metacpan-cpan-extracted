#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Func::Util;

# Test util functions with various loop variable patterns

subtest 'map with $_' => sub {
    my @nums = (0, 5, 10, -3, 100);
    my @result = map { my $v = Func::Util::clamp($_, 2, 50); $v } @nums;
    is_deeply(\@result, [2, 5, 10, 2, 50], 'clamp with $_');
};

subtest 'for with $item' => sub {
    my @nums = (0, 5, 10, -3, 100);
    my @result;
    for my $item (@nums) {
        my $v = Func::Util::clamp($item, 2, 50);
        push @result, $v;
    }
    is_deeply(\@result, [2, 5, 10, 2, 50], 'clamp with $item');
};

subtest 'for with $val' => sub {
    my @nums = (1, 2, 3, 4, 5);
    my @result;
    for my $val (@nums) {
        my $c = Func::Util::clamp($val, 2, 4);
        push @result, $c;
    }
    is_deeply(\@result, [2, 2, 3, 4, 4], 'clamp with $val');
};

subtest 'for with $n' => sub {
    my @nums = (-5, 0, 5, 10);
    my @result;
    for my $n (@nums) {
        push @result, Func::Util::is_positive($n) ? 'pos' : 'not';
    }
    is_deeply(\@result, ['not', 'not', 'pos', 'pos'], 'is_positive with $n');
};

subtest 'for with $x' => sub {
    my @vals = (1, undef, 'a', undef, 0);
    my @result;
    for my $x (@vals) {
        push @result, $x if Func::Util::is_defined($x);
    }
    is_deeply(\@result, [1, 'a', 0], 'is_defined with $x');
};

subtest 'grep with $_' => sub {
    my @nums = (1, 2, 3, 4, 5, 6);
    my @evens = grep { Func::Util::is_even($_) } @nums;
    is_deeply(\@evens, [2, 4, 6], 'is_even grep with $_');
};

subtest 'for with $thing' => sub {
    my @mixed = (1, 'two', [1,2,3], {a=>1}, sub{});
    my @refs;
    for my $thing (@mixed) {
        push @refs, $thing if Func::Util::is_ref($thing);
    }
    is(scalar(@refs), 3, 'is_ref with $thing');
};

subtest 'string interpolation "key$_"' => sub {
    my @indices = (1, 2, 3);
    my @keys = map { "key$_" } @indices;
    my @result = map { Func::Util::starts_with($_, 'key') ? 1 : 0 } @keys;
    is_deeply(\@result, [1, 1, 1], 'starts_with on interpolated strings');
};

subtest 'nested loops $row/$col' => sub {
    my @matrix;
    for my $row (1..2) {
        my @row_data;
        for my $col (1..3) {
            my $val = $row * 10 + $col;
            my $c = Func::Util::clamp($val, 12, 22);
            push @row_data, $c;
        }
        push @matrix, \@row_data;
    }
    is_deeply(\@matrix, [[12, 12, 13], [21, 22, 22]], 'nested with $row/$col');
};

subtest 'while with local $_' => sub {
    my @data = (1, 5, 10, 15);
    my @result;
    my $i = 0;
    while ($i < @data) {
        local $_ = $data[$i];
        my $c = Func::Util::clamp($_, 3, 12);
        push @result, $c;
        $i++;
    }
    is_deeply(\@result, [3, 5, 10, 12], 'clamp in while with $_');
};

subtest 'triple nested $a/$b/$c' => sub {
    my @result;
    for my $a (1..2) {
        for my $b (1..2) {
            for my $c (1..2) {
                my $val = $a * 100 + $b * 10 + $c;
                my $clamped = Func::Util::clamp($val, 110, 220);
                push @result, $clamped;
            }
        }
    }
    is_deeply(\@result, [111, 112, 121, 122, 211, 212, 220, 220], 'triple nested');
};

subtest 'index with $idx' => sub {
    my @data = qw(apple banana cherry date elderberry);
    my @result;
    for my $idx (0..$#data) {
        if (Func::Util::starts_with($data[$idx], 'b') || Func::Util::starts_with($data[$idx], 'e')) {
            push @result, $idx;
        }
    }
    is_deeply(\@result, [1, 4], 'starts_with with $idx');
};

subtest 'hash with $key/$value' => sub {
    my %data = (a => 10, b => 20, c => 30);
    my @clamped;
    for my $key (sort keys %data) {
        my $value = $data{$key};
        my $c = Func::Util::clamp($value, 15, 25);
        push @clamped, $c;
    }
    is_deeply(\@clamped, [15, 20, 25], 'hash with $key/$value');
};

subtest 'each with $k, $v' => sub {
    my %data = (x => -5, y => 50, z => 500);
    my %result;
    for my $k (keys %data) {
        my $v = $data{$k};
        $result{$k} = Func::Util::clamp($v, 0, 100);
    }
    is($result{x}, 0, 'each x');
    is($result{y}, 50, 'each y');
    is($result{z}, 100, 'each z');
};

done_testing();
