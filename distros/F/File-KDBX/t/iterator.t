#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Iterator;
use File::KDBX::Entry;
use File::KDBX::Util qw(:load);
use Iterator::Simple qw(:all);
use Test::More;

subtest 'Basic' => sub {
    my $it = File::KDBX::Iterator->new(1..10);

    is $it->(), 1, 'Get next item (1)';
    is $it->(), 2, 'Get next item (2)';
    $it->unget(-5);
    is $it->(), -5, 'Unget';
    is $it->peek, 3, 'Peek at next';
    is $it->(), 3, 'Get next item (3)';
    is $it->count, 7, 'Get current size';

    my $limited = $it->limit(3);
    is $limited->count, 3, 'Get current size';
    my $enum = ienumerate $limited;
    is_deeply $enum->to_array, [[0, 4], [1, 5], [2, 6]], 'Use Iterator::Simple functions';

    is $it->(), 7, 'Original iterator is drained by composing iterator';

    is $it->next(sub { $_ == 9 }), 9, 'Find next matching item';
    is $it->next, 10, 'Item got skipped while finding next match';
    is $it->peek, undef, 'No more items (peek)';
    is $it->next, undef, 'No more items (next)';

    $it->(qw{10 20 30});
    is_deeply [$it->each], [qw{10 20 30}], 'Fill buffer and get each item (list)';
    is $it->(), undef, 'Empty';

    $it->(my $buffer = [qw{a b c}]);
    my @each;
    $it->each(sub { push @each, $_ });
    is_deeply \@each, [qw{a b c}], 'Fill buffer and get each item (function)';
    is_deeply $buffer, [], 'Buffer is empty';
};

subtest 'Sorting' => sub {
    my $new_it = sub {
        File::KDBX::Iterator->new(
            File::KDBX::Entry->new(label => 'foo', icon_id => 1),
            File::KDBX::Entry->new(label => 'bar', icon_id => 5),
            File::KDBX::Entry->new(label => 'BaZ', icon_id => 3),
            File::KDBX::Entry->new(label => 'qux', icon_id => 2),
            File::KDBX::Entry->new(label => 'Muf', icon_id => 4),
        );
    };

    my @sort = (label => collate => 0);

    my $it = $new_it->();
    is_deeply $it->sort_by(@sort)->map(sub { $_->label })->to_array,
        [qw{BaZ Muf bar foo qux}], 'Sort text ascending';

    $it = $new_it->();
    is_deeply $it->sort_by(@sort, case => 0)->map(sub { $_->label })->to_array,
        [qw{bar BaZ foo Muf qux}], 'Sort text ascending, ignore-case';

    $it = $new_it->();
    is_deeply $it->sort_by(@sort, ascending => 0)->map(sub { $_->label })->to_array,
        [qw{qux foo bar Muf BaZ}], 'Sort text descending';

    $it = $new_it->();
    is_deeply $it->sort_by(@sort, ascending => 0, case => 0)->map(sub { $_->label })->to_array,
        [qw{qux Muf foo BaZ bar}], 'Sort text descending, ignore-case';

    SKIP: {
        plan skip_all => 'Unicode::Collate required to test collation sorting'
            if !try_load_optional('Unicode::Collate');

        # FIXME I'm missing something....
        # $it = $new_it->();
        # is_deeply $it->sort_by('label')->map(sub { $_->label })->to_array,
        #     [qw{BaZ Muf bar foo qux}], 'Sort text ascending using Unicode::Collate';

        $it = $new_it->();
        is_deeply $it->sort_by('label', case => 0)->map(sub { $_->label })->to_array,
            [qw{bar BaZ foo Muf qux}], 'Sort text ascending, ignore-case using Unicode::Collate';
    }

    $it = $new_it->();
    is_deeply $it->nsort_by('icon_id')->map(sub { $_->label })->to_array,
        [qw{foo qux BaZ Muf bar}], 'Sort text numerically, ascending';

    $it = $new_it->();
    is_deeply $it->nsort_by('icon_id', ascending => 0)->map(sub { $_->label })->to_array,
        [qw{bar Muf BaZ qux foo}], 'Sort text numerically, descending';
};

done_testing;
