package List::RubyLike::Test;
use strict;
use warnings;
use base qw/Test::Class/;

use Test::More;
# These tests are from List::RubyLike wrote by Naoya Ito.
# http://github.com/naoya/list-rubylike/tree/master
# use List::RubyLike;

use lib 'lib';

use List::Enumerator E => { -as => 'list' };
use Data::Dumper;
sub p ($) { warn Dumper shift }

#sub test_instance : Test(12) {
#	## class->new
#	my $list = [qw/foo bar baz/];
#	my $object = List::RubyLike->new($list);
#	ok $object;
#
#	isa_ok $object, 'List::RubyLike';
#	ok UNIVERSAL::isa($list, 'List::RubyLike');
#
#	is @$object, 3;
#	is $object->[0], 'foo';
#
#	## $object->new
#	$object = $list->new([qw/foo bar baz/]);
#	isa_ok $object, 'List::RubyLike';
#	ok UNIVERSAL::isa($list, 'List::RubyLike');
#	is @$object, 3;
#	is $object->[0], 'foo';
#
#	## empty argument
#	$object = List::RubyLike->new;
#	isa_ok $object, 'List::RubyLike';
#	is_deeply $object->to_a, [];
#
#	## exception
#	eval { $object = List::RubyLike->new(qw/foo bar baz/) };
#	ok $@;
#}
#
#sub test_instantiate : Test(8) {
#	my $list = list([qw/foo bar baz/]);
#	isa_ok $list, 'List::RubyLike';
#	is @$list, 3;
#
#	$list = list(qw/foo bar baz/);
#	isa_ok $list, 'List::RubyLike';
#	is @$list, 3;
#
#	$list = list();
#	isa_ok $list, 'List::RubyLike';
#	is @$list, 0;
#
#	$list = list({ foo => 'bar' });
#	isa_ok $list, 'List::RubyLike';
#	is_deeply $list->to_a, [ { foo => 'bar' } ];
#}

sub test_push_and_pop : Test(7) {
	my $list = list(qw/foo bar baz/);
	$list->push('foo');
	is @$list, 4;
	is $list->[3], 'foo';

	$list->push('foo', 'bar');
	is @$list, 6;
	is $list->[5], 'bar';

	is $list->pop, 'bar';
	is @$list, 5;

#	isa_ok $list->push('baz'), 'List::RubyLike';
}

sub test_unshift_and_shift : Test(7) {
	my $list = list(qw/foo bar baz/);
	$list->unshift('hoge');
	is @$list, 4;
	is $list->[0], 'hoge';

	$list->unshift('moge', 'uge');
	is @$list, 6;
	is $list->[0], 'moge';

	is $list->shift, 'moge';
	is @$list, 5;

#	isa_ok $list->unshift('baz'), 'List::RubyLike';
}

sub test_first_and_last : Test(3) {
	my @elements = qw/foo bar baz/;
	my $list = list(@elements);
	is $list->first, 'foo';
	is $list->last, 'baz';
	is_deeply $list->to_a, [qw/foo bar baz/];
}

sub dump : Test(1) {
	my $struct = [
	qw /foo bar baz/,
	[0, 1, 2, 3, 4],
	];

	is_deeply($struct, eval list($struct)->dump);
}

sub join : Test(3) {
	my $list = list(qw/foo bar baz/);
	is $list->join('/'), 'foo/bar/baz';
	is $list->join('.'), 'foo.bar.baz';
	is $list->join(''), 'foobarbaz';
}

sub each : Test(3) {
	my $list =list(qw/foo bar baz/);
	my @resulsts;
	my $ret = $list->each(sub{ s!^ba!!; push @resulsts, $_  });
#	isa_ok $ret, 'List::RubyLike';
	is_deeply \@resulsts, [qw/foo r z/];
	is_deeply $ret->to_a, [qw/foo bar baz/];
}

sub each_index : Test(2) {
	my $list = list(qw/foo bar baz/);
	my @indexes;
	my $ret = $list->each_index(sub { push @indexes, $_ });
#	isa_ok $ret, 'List::RubyLike';
	is_deeply \@indexes, [0, 1, 2];
}

sub test_concat_and_append : Test(10) {
	for my $method (qw/concat append/) {
		my $list = list(qw/foo bar baz/);
		$list->$method(['foo']);
		is @$list, 4;
		is $list->[3], 'foo';
		$list->$method(['foo', 'bar']);
		is @$list, 6;
		is $list->[5], 'bar';
#		isa_ok $list->$method(['hoge']), 'List::RubyLike';

#         $list->$method('baz');
#         is @$list, 7;
#         is $list->[6], 'baz';
	}
}

sub test_prepend : Test(5) {
	my $list = list(qw/foo bar baz/);
	$list->prepend(['foo']);
	is @$list, 4;
	is $list->[0], 'foo';
	$list->prepend(['foo', 'bar']);
	is @$list, 6;
	is $list->[0], 'foo';
#	isa_ok $list->prepend(['hoge']), 'List::RubyLike';
}

sub test_add : Test(3) {
	my $list = list('foo');
	is_deeply($list + ['bar'], [qw/foo bar/]);
	is_deeply(['baz'] + $list, [qw/baz foo/]);
	is_deeply($list->to_a, ['foo']);
}

sub test_collect_and_map : Test(10) {
	for my $method (qw/collect map/) {
		my $list = list(qw/foo bar baz/);

		my $new = $list->$method(sub { s/^ba//; $_ });
#		isa_ok $new, 'List::RubyLike';
		is_deeply $new->to_a, [qw/foo r z/];
		is_deeply $list->to_a, [qw/foo bar baz/];

		my @new = $list->$method(sub { s/^ba//; $_ });
		is_deeply \@new, [qw/foo r z/];
		is_deeply $list->to_a, [qw/foo bar baz/];
	}
}

sub test_zip : Tests(4) {
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
}

sub test_delete :  Tests(4) {
	my $list = list([1,2,3,2,1]);

	is_deeply( $list->delete(2), 2);
	is_deeply( $list->to_a, [1,3,1]);
	is_deeply( $list->delete(2, sub { return $_ * $_}), 4);
	is_deeply( $list->to_a, [1,3,1]);
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
	is_deeply( $list->delete_if( sub { $_ < 3 ? 1 : 0 } )->to_a, [1,2]);
# Is this wrong?
#	is_deeply( $list->to_a, [1,2] );
}

sub test_inject: Tests(3) {
	my $list = list([1,2,3,4,5]);
	is_deeply( $list->inject(10, sub { $_[0] + $_[1] }), 25);
	is_deeply( $list->inject(10, sub { $_[0] - $_[1] }), -5);
	is_deeply( $list->inject('a', sub { $_[0] . $_[1] }), 'a12345');
}

sub test_grep : Tests(2) {
	my $list = list(qw/foo bar baz/);
#	isa_ok $list->grep(sub { $_ }), 'List::RubyLike';
	is_deeply $list->grep(sub { m/^b/ })->to_a, [qw/bar baz/];
}

sub test_sort : Tests(4) {
	my $list = list(3, 1, 2);
#	isa_ok $list->sort, 'List::RubyLike';
	is_deeply $list->sort->to_a, [1, 2, 3];
	is_deeply $list->sort(sub { $_[1] <=> $_[0] })->to_a, [3, 2, 1];
	is_deeply $list->to_a, [3, 1, 2];
}

sub test_compact : Tests {
	my $list = list(1, 2, undef, 4);
#	isa_ok $list->compact, 'List::RubyLike';

	is $list->compact->size, 3;
	is_deeply $list->compact->to_a, [1, 2, 4];

	is $list->size, 4;
	is_deeply $list->to_a, [1, 2, undef, 4];
}

sub test_length_and_size : Test(4) {
	for my $method (qw/length size/) {
		is list(1, 2, 3, 4)->size, 4;
		is list()->size, 0;
	}
}

sub test_flatten : Tests {
	my $list = list([1, 2, 3, [4, 5, 6, [7, 8, 9, {10 => '11'} ]]]);

#	isa_ok    $list->flatten, 'List::RubyLike';
	is_deeply $list->flatten->to_a, [1, 2, 3, 4, 5, 6, 7, 8, 9, { 10 => '11' }];
	is_deeply $list->to_a, [1, 2, 3, [4, 5, 6, [7, 8, 9, { 10 => '11' } ]]];
}

sub test_is_empty : Test(2) {
	ok list()->is_empty;
	ok not list(1, 2, 3)->is_empty;
}

sub test_uniq : Test(3) {
	my $list = list(1, 2, 3, 3, 4);
#	isa_ok $list->uniq, 'List::RubyLike';
	is_deeply $list->uniq->to_a, [1, 2, 3, 4];
	is_deeply $list->to_a, [1, 2, 3, 3, 4];
}

sub test_reduce : Test(1) {
	my $list = list(1, 2, 10, 5, 9);
	is $list->reduce(sub { $_[0] > $_[1] ? $_[0] : $_[1] }), 10;
}

sub test_dup : Test(3) {
	my $list = list(1, 2, 3);
	isnt $list, $list->dup;
#	isa_ok $list->dup, 'List::RubyLike';
	is_deeply $list->to_a, $list->dup->to_a;
}

sub test_slice : Test(12) {
	my $list = list(0, 1, 2);

	is_deeply $list->slice(0, 0)->to_a, [0];
	is_deeply $list->slice(0, 1)->to_a, [0, 1];
	is_deeply $list->slice(0, 2)->to_a, [0, 1, 2];
	is_deeply $list->slice(0, 3)->to_a, [0, 1, 2];

	is_deeply $list->slice(1, 1)->to_a, [1];
	is_deeply $list->slice(1, 2)->to_a, [1, 2];
	is_deeply $list->slice(1, 3)->to_a, [1, 2];

#	is_deeply $list->slice(0)->to_a, [0, 1, 2];
#	is_deeply $list->slice(1)->to_a, [0, 1, 2];
#	is_deeply $list->slice(2)->to_a, [];
#
#	is_deeply $list->slice(3)->to_a, [];
#	is_deeply $list->slice->to_a, [0, 1, 2];
}

sub test_find : Test(8) {
	my $list = list(1, 2, 3);

	is $list->find(sub { $_ == 1 }), 1;
	is $list->find(sub { $_ == 2 }), 2;
	is $list->find(sub { $_ == 3 }), 3;
	is $list->find(sub { $_ == 4 }), undef;

	is $list->find(1), 1;
	is $list->find(2), 2;
	is $list->find(3), 3;
	is $list->find(4), undef;
}

sub test_index_of : Test(7) {
	my $list = list(0, 1, 2, 3);

	is $list->index_of(0), 0;
	is $list->index_of(1), 1;
	is $list->index_of(2), 2;
	is $list->index_of(3), 3;
	is $list->index_of(4), undef;

	is $list->index_of(sub { shift == 2 }), 2;
	is $list->index_of(sub { shift == 5 }), undef;
}

sub test_as_list : Test(1) {
# I don't know an use case of this.
#	my $list = list(0, 1, 2, 3);
#	is $list->as_list, $list;
}

sub test_reverse : Test(1) {
	my $list = list(0, 1, 2, 3);
	is_deeply [3, 2, 1, 0], $list->reverse->to_a;
}

sub test_sum : Test(2) {
	is list(0, 1, 2, 3)->sum, 0 + 1 + 2 + 3;
	is list(1, 1, 1, 1)->sum, 1 + 1 + 1 + 1;
}

__PACKAGE__->runtests;

1;
