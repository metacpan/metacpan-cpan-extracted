# original code is http://github.com/naoya/list-rubylike/tree/master/t/01-methods.t
package List::Rubyish::Test;
use strict;
use warnings;
use base qw/Test::Class/;

use Test::More;
use List::Rubyish;

__PACKAGE__->runtests;

sub list (@) {
    my @raw = (ref $_[0] and ref $_[0] eq 'ARRAY') ? @{$_[0]} : @_;
    List::Rubyish->new(\@raw);
}

sub test_instance : Tests(19) {
    ## class->new
    my $list = [qw/foo bar baz/];
    my $object = List::Rubyish->new($list);
    ok $object;

    isa_ok $object, 'List::Rubyish';
    ok UNIVERSAL::isa($list, 'List::Rubyish');

    is @$object, 3;
    is $object->[0], 'foo';

    ## $object->new
    $object = $list->new([qw/foo bar baz/]);
    isa_ok $object, 'List::Rubyish';
    ok UNIVERSAL::isa($list, 'List::Rubyish');
    is @$object, 3;
    is $object->[0], 'foo';

    ## empty argument
    $object = List::Rubyish->new;
    isa_ok $object, 'List::Rubyish';
    is_deeply $object->to_a, [];

    ## not array reference
    $object = List::Rubyish->new('foo');
    isa_ok $object, 'List::Rubyish';
    is_deeply $object->to_a, ['foo'];

    $object = List::Rubyish->new(qw/ foo bar baz /);
    isa_ok $object, 'List::Rubyish';
    is_deeply $object->to_a, [qw/ foo bar baz /];

    $object = List::Rubyish->new([[qw/ foo bar baz /]]);
    isa_ok $object, 'List::Rubyish';
    is_deeply $object->to_a, [[qw/ foo bar baz /]];

    $object = List::Rubyish->new({ foo => 1, bar => 2, baz => 3});
    isa_ok $object, 'List::Rubyish';
    is_deeply $object->to_a, [{ foo => 1, bar => 2, baz => 3}];
}

sub test_instantiate : Tests(8) {
    my $list = list([qw/foo bar baz/]);
    isa_ok $list, 'List::Rubyish';
    is @$list, 3;

    $list = list(qw/foo bar baz/);
    isa_ok $list, 'List::Rubyish';
    is @$list, 3;

    $list = list();
    isa_ok $list, 'List::Rubyish';
    is @$list, 0;

    $list = list({ foo => 'bar' });
    isa_ok $list, 'List::Rubyish';
    is_deeply $list->to_a, [ { foo => 'bar' } ];
}

sub test_push_and_pop : Tests(7) {
    my $list = list(qw/foo bar baz/);
    $list->push('foo');
    is @$list, 4;
    is $list->[3], 'foo';

    $list->push('foo', 'bar');
    is @$list, 6;
    is $list->[5], 'bar';

    is $list->pop, 'bar';
    is @$list, 5;

    isa_ok $list->push('baz'), 'List::Rubyish';
}

sub test_unshift_and_shift : Tests(7) {
    my $list = list(qw/foo bar baz/);
    $list->unshift('hoge');
    is @$list, 4;
    is $list->[0], 'hoge';

    $list->unshift('moge', 'uge');
    is @$list, 6;
    is $list->[0], 'moge';

    is $list->shift, 'moge';
    is @$list, 5;

    isa_ok $list->unshift('baz'), 'List::Rubyish';
}

sub test_first_and_last : Tests(7) {
    my @elements = qw/foo bar baz/;
    my $list = list(@elements);
    is $list->first, 'foo';
    is_deeply $list->first(2)->to_a, [qw/foo bar/];
    is_deeply $list->first(3)->to_a, [qw/foo bar baz/];

    is $list->last, 'baz';
    is_deeply $list->last(2)->to_a, [qw/bar baz/];
    is_deeply $list->last(3)->to_a, [qw/foo bar baz/];

    is_deeply $list->to_a, [qw/foo bar baz/];
}

sub test_select_and_find_all : Tests(4) {
    for my $method (qw/select find_all/) {
        my $list = list(qw/30 100 50 80 79 40 95/);
        is_deeply( $list->$method( sub { $_ >= 80 } )->to_a, [100, 80, 95]);
        is_deeply( $list->to_a, [qw/30 100 50 80 79 40 95/] );
    }
}

sub test_select_size_error : Tests(2) {
    no warnings 'redefine';
    local *List::Rubyish::size = sub {};
    my $list = list(qw/30 100 50 80 79 40 95/);
    is_deeply( $list->select( sub { $_ >= 80 } )->to_a, [qw/30 100 50 80 79 40 95/]);

    my $list2 = list();
    is_deeply( $list2->select( sub { $_ >= 80 } )->to_a, []);
}

sub dump : Tests(1) {
    my $struct = [
        qw /foo bar baz/,
        [0, 1, 2, 3, 4],
    ];

    is_deeply($struct, eval list($struct)->dump);
}

sub join : Tests(3) {
    my $list = list(qw/foo bar baz/);
    is $list->join('/'), 'foo/bar/baz';
    is $list->join('.'), 'foo.bar.baz';
    is $list->join(''), 'foobarbaz';
}

sub each : Tests(3) {
    my $list =list(qw/foo bar baz/);
    my @resulsts;
    my $ret = $list->each(sub{ s!^ba!!; push @resulsts, $_  });
    isa_ok $ret, 'List::Rubyish';
    is_deeply \@resulsts, [qw/foo r z/];
    is_deeply $ret->to_a, [qw/foo bar baz/];
}

sub each_index : Tests(2) {
    my $list = list(qw/foo bar baz/);
    my @indexes;
    my $ret = $list->each_index(sub { push @indexes, $_ });
    isa_ok $ret, 'List::Rubyish';
    is_deeply \@indexes, [0, 1, 2];
}

sub test_concat_and_append : Tests(10) {
    for my $method (qw/concat append/) {
        my $list = list(qw/foo bar baz/);
        $list->$method(['foo']);
        is @$list, 4;
        is $list->[3], 'foo';
        $list->$method(['foo', 'bar']);
        is @$list, 6;
        is $list->[5], 'bar';
        isa_ok $list->$method(['hoge']), 'List::Rubyish';

#         $list->$method('baz');
#         is @$list, 7;
#         is $list->[6], 'baz';
    }
}

sub test_prepend : Tests(5) {
    my $list = list(qw/foo bar baz/);
    $list->prepend(['foo']);
    is @$list, 4;
    is $list->[0], 'foo';
    $list->prepend(['foo', 'bar']);
    is @$list, 6;
    is $list->[0], 'foo';
    isa_ok $list->prepend(['hoge']), 'List::Rubyish';
}

sub test_add : Tests(3) {
    my $list = list('foo');
    is_deeply($list + ['bar'], [qw/foo bar/]);
    is_deeply(['baz'] + $list, [qw/baz foo/]);
    is_deeply($list->to_a, ['foo']);
}

sub test_collect_and_map : Tests(10) {
    for my $method (qw/collect map/) {
        my $list = list(qw/foo bar baz/);

        my $new = $list->$method(sub { s/^ba//; $_ });
        isa_ok $new, 'List::Rubyish';
        is_deeply $new->to_a, [qw/foo r z/];
        is_deeply $list->to_a, [qw/foo bar baz/];

        my @new = $list->$method(sub { s/^ba//; $_ });
        is_deeply \@new, [qw/foo r z/];
        is_deeply $list->to_a, [qw/foo bar baz/];
    }
}

sub test_zip : Tests(7) {
    my $list = list([1,2,3]);
    is_deeply(
        $list->zip([1,2,3], [1,2,3])->to_a,
        [[1,1,1],[2,2,2],[3,3,3]]
    );
    is_deeply(
        $list->zip(list([1,2,3]), [1,2,3])->to_a,
        [[1,1,1],[2,2,2],[3,3,3]]
    );
    is_deeply(
        $list->zip(list([1,2,3]), [1,2])->to_a,
        [[1,1,1],[2,2,2],[3,3,undef]]
    );
    is_deeply(
        $list->zip(list([1,2,3]), [1,2,3,4])->to_a,
        [[1,1,1],[2,2,2],[3,3,3]]
    );
    is_deeply(
        $list->zip(list([1,2,3]), [1,2,3,4], [4,3,2,1])->to_a,
        [[1,1,1,4],[2,2,2,3],[3,3,3,2]]
    );
    is_deeply(
        $list->zip(list([1,2,3]), [1,2,3,4], [4,3,2,1], list([1,2,3]))->to_a,
        [[1,1,1,4,1],[2,2,2,3,2],[3,3,3,2,3]]
    );
    is_deeply($list->to_a, [1,2,3]);
}

sub test_delete :  Tests(8) {
    my $list = list([1,2,3,2,1,5]);

    my $code = sub { $_ == 5 };
    is( $list->delete($code), $code);
    is_deeply( $list->to_a, [1,2,3,2,1]);
    is( $list->delete(2), 2);
    is_deeply( $list->to_a, [1,3,1]);
    is( $list->delete(2), undef);
    is( $list->delete(2, +{}), undef);
    is( $list->delete(2, sub { return $_ * $_}), 4);
    is_deeply( $list->to_a, [1,3,1]);
}

sub test_delete_str :  Tests(3) {
    my $list = list([qw/ foo bar baz /]);

    is_deeply( $list->to_a, [qw/ foo bar baz /]);
    is( $list->delete('bar'), 'bar');
    is_deeply( $list->to_a, [qw/ foo baz /]);
}

sub test_delete_at : Tests(6) {
    my $ary = [1,2,3,4,5];
    my $list = list($ary);
    ok not $list->delete_at(5);
    is_deeply( $list->to_a, $ary);
    is_deeply( $list->delete_at(2), 3);
    is_deeply( $list->to_a, [1,2,4,5]);
    is_deeply( $list->delete_at(0), 1);
    is_deeply( $list->to_a, [2,4,5]);
}

sub test_delete_if: Tests(2) {
    my $list = list([1,2,3,4,5]);
    is_deeply( $list->delete_if( sub { $_ < 3 } )->to_a, [3,4,5]);
    is_deeply( $list->to_a, [3,4,5] );
}

sub test_reject: Tests {
    my $list = list([1,2,3,4,5]);
    is_deeply( $list->reject( sub { $_ < 3 } )->to_a, [3,4,5]);
    is_deeply( $list->to_a, [1,2,3,4,5] );
}

sub test_inject: Tests(3) {
    my $list = list([1,2,3,4,5]);
    is_deeply( $list->inject(10, sub { $_[0] + $_[1] }), 25);
    is_deeply( $list->inject(10, sub { $_[0] - $_[1] }), -5);
    is_deeply( $list->inject('a', sub { $_[0] . $_[1] }), 'a12345');
}

sub test_grep : Tests(3) {
    my $list = list(qw/foo bar baz/);
    isa_ok $list->grep(sub { $_ }), 'List::Rubyish';
    is_deeply $list->grep(sub { m/^b/ })->to_a, [qw/bar baz/];

    my @ret = $list->grep(sub { m/^b/ });
    is_deeply \@ret, [qw/bar baz/];
}

sub test_sort : Tests(5) {
    my $list = list(3, 1, 2);
    isa_ok $list->sort, 'List::Rubyish';
    is_deeply $list->sort->to_a, [1, 2, 3];
    is_deeply $list->sort(sub { $_[1] <=> $_[0] })->to_a, [3, 2, 1];
    is_deeply $list->to_a, [3, 1, 2];

    my @ret = $list->sort(sub { $_[1] <=> $_[0] });
    is_deeply \@ret, [3, 2, 1];
}

sub test_sort_by : Tests(4) {
    my $list = list([ [3], [1], [2] ]);
    isa_ok $list->sort_by(sub { $_->[0] }), 'List::Rubyish';
    is_deeply $list->sort_by(sub { $_->[0] })->to_a, [[1], [2], [3]];
    is_deeply $list->sort_by(sub { $_->[0] }, sub { $_[1] <=> $_[0] })->to_a, [[3], [2], [1]];
    my @ret = $list->sort_by(sub { $_->[0] });
    is_deeply \@ret, [[1], [2], [3]];
}

sub test_compact : Tests {
    my $list = list(1, 2, undef, 4);
    isa_ok $list->compact, 'List::Rubyish';

    is $list->compact->size, 3;
    is_deeply $list->compact->to_a, [1, 2, 4];

    is $list->size, 4;
    is_deeply $list->to_a, [1, 2, undef, 4];
}

sub test_length_and_size : Tests(4) {
    for my $method (qw/length size/) {
        is list(1, 2, 3, 4)->size, 4;
        is list()->size, 0;
    }
}

sub test_flatten : Tests(3) {
    my $list = list([1, 2, 3, [4, 5, 6, [7, 8, 9, {10 => '11'} ]]]);

    isa_ok    $list->flatten, 'List::Rubyish';
    is_deeply $list->flatten->to_a, [1, 2, 3, 4, 5, 6, 7, 8, 9, { 10 => '11' }];
    is_deeply $list->to_a, [1, 2, 3, [4, 5, 6, [7, 8, 9, { 10 => '11' } ]]];
}

sub test_is_empty : Tests(2) {
    ok list()->is_empty;
    ok not list(1, 2, 3)->is_empty;
}

sub test_uniq : Tests(3) {
    my $list = list(1, 2, 3, 3, 4);
    isa_ok $list->uniq, 'List::Rubyish';
    is_deeply $list->uniq, [1, 2, 3, 4];
    is_deeply $list->to_a, [1, 2, 3, 3, 4];
}

sub test_reduce : Tests(1) {
    my $list = list(1, 2, 10, 5, 9);
    is $list->reduce(sub { $_[0] > $_[1] ? $_[0] : $_[1] }), 10;
}

sub test_dup : Tests(3) {
    my $list = list(1, 2, 3);
    isnt $list, $list->dup;
    isa_ok $list->dup, 'List::Rubyish';
    is_deeply $list->to_a, $list->dup->to_a;
}

sub test_slice : Tests(12) {
    my $list = list(0, 1, 2);

    is_deeply $list->slice(0, 0)->to_a, [0];
    is_deeply $list->slice(0, 1)->to_a, [0, 1];
    is_deeply $list->slice(0, 2)->to_a, [0, 1, 2];
    is_deeply $list->slice(0, 3)->to_a, [0, 1, 2];

    is_deeply $list->slice(1, 1)->to_a, [1];
    is_deeply $list->slice(1, 2)->to_a, [1, 2];
    is_deeply $list->slice(1, 3)->to_a, [1, 2];

    is_deeply $list->slice(0)->to_a, [0, 1, 2];
    is_deeply $list->slice(1)->to_a, [0, 1, 2];
    is_deeply $list->slice(2)->to_a, [];

    is_deeply $list->slice(3)->to_a, [];
    is_deeply $list->slice->to_a, [0, 1, 2];
}

sub test_find_and_detect : Tests(24) {
    my $list = list(1, 2, 3);

    for my $method (qw/find detect/) {
        is $list->$method(sub { $_ == 1 }), 1;
        is $list->$method(sub { $_ == 2 }), 2;
        is $list->$method(sub { $_ == 3 }), 3;
        is $list->$method(sub { $_ == 4 }), undef;

        is $list->$method(1), 1;
        is $list->$method(2), 2;
        is $list->$method(3), 3;
        is $list->$method(4), undef;

        is $list->$method(+{ kyururi => 1 }), undef;
        is $list->$method(+{ kyururi => 2 }), undef;
        is $list->$method(+{ kyururi => 3 }), undef;
        is $list->$method(+{ kyururi => 4 }), undef;
    }
}

sub test_index_of : Tests(7) {
    my $list = list(0, 1, 2, 3);

    is $list->index_of(0), 0;
    is $list->index_of(1), 1;
    is $list->index_of(2), 2;
    is $list->index_of(3), 3;
    is $list->index_of(4), undef;

    is $list->index_of(sub { shift == 2 }), 2;
    is $list->index_of(sub { shift == 5 }), undef;
}

sub test_as_list : Tests(1) {
    my $list = list(0, 1, 2, 3);
    is $list->as_list, $list;
}

sub test_reverse : Tests(1) {
    my $list = list(0, 1, 2, 3);
    is_deeply [3, 2, 1, 0], $list->reverse->to_a;
}

sub test_sum : Tests(2) {
    is list(0, 1, 2, 3)->sum, 0 + 1 + 2 + 3;
    is list(1, 1, 1, 1)->sum, 1 + 1 + 1 + 1;
}

sub test_some_method_argument_in_not_a_code : Tests(6) {
    my $obj = List::Rubyish->new;

    for my $method (qw/ delete_if inject each collect reduce select /) {
        local $@;
        eval { $obj->$method( +{} ) };
        like $@, qr/Argument must be a code/, $method;
    }
}

sub test__last_index : Tests(1) {
    my $obj = List::Rubyish->new;
    no warnings 'redefine';
    local *List::Rubyish::length = sub {};
    is $obj->_last_index, 0;
}

sub test_grep_argment_error : Tests(2) {
    my $obj = List::Rubyish->new;

    ok !$obj->grep;
    local $@;
    eval { $obj->grep(+{}) };
    like $@, qr/Invalid code/;
}

1;
