package List::Enumerator::Test;
use strict;
use warnings;
use base qw/Test::Class/;
use Test::More;
use Test::Exception;

use lib "lib";
use List::Enumerator qw/E/;
use List::Enumerator::Array;
use List::Enumerator::Sub;

use Data::Dumper;
sub p ($) { warn Dumper shift }

sub test_each : Test(3) {
	my $result = [];

	E(1, 2, 3)->each(sub {
		push @$result, $_;
	});
	is_deeply $result, [1, 2, 3];

	$result = [];
	my $array_enum = E(1, 2, 3);
	$array_enum->each(sub {
		push @$result, $_;
	});
	is_deeply $result, [1, 2, 3];

	$result = [];
	$array_enum->each(sub {
		push @$result, $_;
	});
	is_deeply $result, [1, 2, 3];
}

sub test_to_list : Test(3) {
	is_deeply [ E(1, 2, 3)->to_list ], [1, 2, 3];

	my $list = E(1, 2, 3);
	$list->next;
	is_deeply [ $list->to_list ], [1, 2, 3];
	is_deeply [ $list->to_list ], [1, 2, 3];
}


sub test_sub_basic : Test(2) {
	my $list;

	$list = List::Enumerator::Sub->new(
		next => sub {
			156
		},
		rewind => sub {
		}
	);

	is $list->next, 156;

	$list = E({
		next => sub {
			156
		}
	});
	is $list->next, 156;
}


sub test_to_a : Test(2) {
	is_deeply E(1, 2, 3)->to_a, [1, 2, 3];
	is_deeply [ E(1, 2, 3)->to_a ], [ [1, 2, 3] ];
}


sub test_map : Test(4) {
	my $list;

	$list = E(1, 2, 3)->map(sub { $_ * $_ });
	is_deeply $list->to_a, [1, 4, 9];
	is_deeply $list->to_a, [1, 4, 9];

	$list = E(1, 2, 3);
	is_deeply [ $list->map(sub { $_ * $_ }) ], [1, 4, 9];
	is_deeply [ $list->map(sub { $_ * $_ }) ], [1, 4, 9];
}

sub test_dup : Test(2) {
	my $list = E(1, 2, 3);

	is $list->dup->next, 1;
	is $list->next, 1;
}



sub test_cycle : Test(9) {
	my $list = E(1, 2, 3)->cycle;
	is $list->next, 1;
	is $list->next, 2;
	is $list->next, 3;
	is $list->next, 1;
	is $list->next, 2;
	is $list->next, 3;
	is $list->next, 1;
	is $list->next, 2;
	is $list->next, 3;
}


sub test_countup : Test(14) {
	my $list;

	$list = E()->countup;
	is $list->next, 0;
	is $list->next, 1;
	is $list->next, 2;
	is $list->next, 3;
	is $list->rewind->next, 0;
	is $list->next, 1;
	is $list->next, 2;
	is $list->next, 3;

	is_deeply E(1)->to(5)->to_a, [1, 2, 3, 4, 5];
	is_deeply E(5)->to(5)->to_a, [5];

	$list = E(1, 2);
	is $list->next, 1;
	my $countup = $list->countup;
	is $countup->next, 2;
	is $countup->next, 3;
	is $countup->rewind->next, 2;
}

sub test_take : Test(6) {
	is_deeply E(1, 2, 3, 4, 5)->take(0)->to_a, [];

	is_deeply E(1, 2, 3, 4, 5)->take(3)->to_a, [1, 2, 3];

	is_deeply [ E(1, 2, 3)->cycle->take(5) ], [1, 2, 3, 1, 2];
	is_deeply [ E(1)->countup->take(5) ], [1, 2, 3, 4, 5];

	is_deeply [ E(1)->countup->take(sub { $_ <= 5 }) ], [1, 2, 3, 4, 5];
	is_deeply [ E(1)->countup->take_while(sub { $_ * $_ <= 9 }) ], [1, 2, 3];
}

sub test_drop : Test(4) {
	is_deeply [ E(1, 2, 3)->drop(1) ], [2, 3];
	is_deeply [ E()->countup->drop(3)->take(5) ], [3, 4, 5, 6, 7];
	is_deeply [ E()->countup->drop(sub { $_ * $_ <= 9 })->take(5) ], [4, 5, 6, 7, 8];
	is_deeply [ E()->countup->drop(sub { $_ * $_ <= 9 })->take(5)->drop(3) ], [7, 8];
}


sub test_zip : Test(3) {
	is_deeply [ E(1, 2, 3, 4, 5)->zip(E()->countup, [qw/a b c/]) ], [
		[1, 0, "a"],
		[2, 1, "b"],
		[3, 2, "c"],
		[4, 3, undef],
		[5, 4, undef]
	];

	my $result = [];
	E(1, 2, 3)->zip([qw/a b c/])->each(sub {
		push @$result, $_;
	});
	is_deeply $result, [ [1, "a"], [2, "b"], [3, "c"] ];

	my $list1 = E(1, 2, 3);
	my $list2 = E(qw/a b c/);
	$list1->next; $list2->next;

	my $zip = $list1->zip($list2);
	is_deeply $zip->to_a, [ [1, "a"], [2, "b"], [3, "c"] ];
}


sub test_with_index : Test(1) {
	my $result = [];
	E("a", "b", "c")->with_index->each(sub {
		my ($item, $index) = @$_;
		push @$result, $item, $index;
	});
	is_deeply $result, [qw/a 0 b 1 c 2/];
}

sub test_select : Test(3) {
	is_deeply E(1)->to(10)->select(sub {
		$_ % 2 == 0;
	})->to_a, [2, 4, 6, 8, 10];

	is_deeply E(1)->countup->select(sub {
		$_ % 2 == 0;
	})->take(4)->to_a, [2, 4, 6, 8];

	my $list = E(1)->countup;
	$list->next;
	is_deeply $list->select(sub {
		$_ % 2 == 0;
	})->take(4)->to_a, [2, 4, 6, 8];
}

sub test_reduce : Test(2) {
	is E(1, 2, 3)->reduce(sub { 
		$a + $b
	}), 6;

	is_deeply E(1, 2, 3)->zip([qw/a b c/])->reduce({}, sub {
		my ($n, $c) = @$b;
		$a->{$b->[1]} = $n;
		$a;
	}), {
		a => 1,
		b => 2,
		c => 3,
	};
}

sub test_find : Test {
	is E(1, 2, 3)->find(sub { $_ > 1 }), 2;
}

sub test_max : Test(2) {
	is E(1, 2, 3)->max, 3;
	is E(1, 2, 3)->max_by(sub { 100 - $_ }), 1;
}

sub test_min : Test(2) {
	is E(1, 2, 3)->min, 1;
	is E(1, 2, 3)->min_by(sub { 100 - $_ }), 3;
}

sub test_chain : Test(4) {
	is_deeply E(1, 2, 3)->chain([4, 5, 6])->to_a , [1, 2, 3, 4, 5, 6];

	my $list1 = E(1, 2, 3);
	$list1->next;
	my $list2 = E(4, 5, 6);
	$list2->next;
	my $chain = $list1->chain($list2);

	is_deeply $chain->to_a, [1, 2, 3, 4, 5, 6];

	$chain->rewind;
	is_deeply $chain->to_a, [1, 2, 3, 4, 5, 6];

	$chain->rewind;
	is_deeply $chain->to_a, [1, 2, 3, 4, 5, 6];
}

sub test_act_as_arrayref : Test(2) {
	my $list;

	$list = E(1, 2, 3);
	is $list->[0], 1;

	$list = E(1, 2, 3)->cycle;
	is $list->[3], 1;
}

sub test_sub : Test(1) {
	my $list = E({
		next => sub {
			$_->stop;
		}
	});

	is_deeply $list->to_a, [];
}

sub test_performance : Test(9) {
	my $list = E(1)->to(10);
	my ($next, $rewind);

	my $enum = E({
		next => sub {
			$next++;
			$list->next;
		},
		rewind => sub {
			$rewind++;
			$list->rewind;
		}
	});

	$enum->rewind;
	($next, $rewind) = (0, 0);
	is_deeply $enum->take(5)->to_a, [1, 2, 3, 4, 5];
	is $next, 5;
	is $rewind, 0;

	$enum->rewind;
	($next, $rewind) = (0, 0);
	is_deeply $enum->drop(5)->to_a, [6, 7, 8, 9, 10];
	is $next, 11;
	is $rewind, 0;

	$enum->rewind;
	($next, $rewind) = (0, 0);
	is_deeply $enum->drop(5)->take(5)->to_a, [6, 7, 8, 9, 10];
	is $next, 10;
	is $rewind, 0;
}

sub test_group_by : Test {
	is_deeply E([
		{ cat => 'a', n => 0 }, { cat => 'a', n => 1 },{ cat => 'a', n => 2 },{ cat => 'a', n => 3 },
		{ cat => 'b', n => 0 }, { cat => 'b', n => 1 },{ cat => 'b', n => 2 },{ cat => 'b', n => 3 },
		{ cat => 'c', n => 0 }, { cat => 'c', n => 1 },{ cat => 'c', n => 2 },{ cat => 'c', n => 3 },
	])->group_by(sub {
		$_->{cat};
	}), {
		'a' => [ { cat => 'a', n => 0 }, { cat => 'a', n => 1 },{ cat => 'a', n => 2 },{ cat => 'a', n => 3 } ],
		'b' => [ { cat => 'b', n => 0 }, { cat => 'b', n => 1 },{ cat => 'b', n => 2 },{ cat => 'b', n => 3 } ],
		'c' => [ { cat => 'c', n => 0 }, { cat => 'c', n => 1 },{ cat => 'c', n => 2 },{ cat => 'c', n => 3 } ],
	};
}

sub test_reject : Test {
	is_deeply E(1)->to(10)->reject(sub { $_ % 2 == 0 })->to_a, [1, 3, 5, 7, 9];
}

sub test_partition : Test(3) {
	is_deeply scalar E(1)->to(10)->partition(sub { $_ % 2 == 0 }), [ [2, 4, 6, 8, 10], [1, 3, 5, 7, 9] ];

	my ($even, $odd) = E(1)->to(10)->partition(sub { $_ % 2 == 0 });
	is_deeply $even, [2, 4, 6, 8, 10];
	is_deeply $odd,  [1, 3, 5, 7, 9];
}

sub test_is_include : Test(4) {
	is E(qw/a b c/)->is_include("a"), 1;
	is E(qw/a b c/)->is_include(1), 0;
	is E(qw/a b c/)->include("a"), 1;
	is E(qw/a b c/)->include(1), 0;
}

sub test_grep : Test {
	is_deeply E(1)->to(10)->grep(sub { $_ % 2 == 0 })->to_a, [2, 4, 6, 8, 10];
}

sub test_each_cons : Test(3) {
	my $result = [];

	$result = [];
	E(1, 2, 3, 4, 5)->each_cons(2, sub {
		push @$result, $_;
	});
	is_deeply $result, [
		[1, 2],
		[2, 3],
		[3, 4],
		[4, 5]
	];

	$result = [];
	E(1, 2, 3, 4, 5)->each_cons(3, sub {
		push @$result, $_;
	});
	is_deeply $result, [
		[1, 2, 3],
		[2, 3, 4],
		[3, 4, 5]
	];

	is_deeply E(1)->countup->each_cons(3)->take(3)->to_a, [
		[1, 2, 3],
		[2, 3, 4],
		[3, 4, 5]
	];
}

sub test_slice : Test(15) {
	my $list = E(1..100);

	is $list->slice(0), 1;
	is $list->slice(99), 100;
	is $list->slice(100), undef;
	is $list->slice(-1), 100;
	is $list->slice(-2), 99;
	is $list->slice(-100), 1;
	is $list->slice(-101), undef;

	is_deeply [ $list->slice(0, 0) ], [ 1 ];
	is_deeply [ $list->slice(99, 99) ], [ 100 ];
	is_deeply [ $list->slice(-1, -1) ], [ 100 ];
	is_deeply [ $list->slice(-2, -2) ], [ 99 ];
	is_deeply [ $list->slice(100, 100) ], [];

	is_deeply [ $list->slice(9, 11) ], [ 10, 11, 12 ];
	is_deeply [ $list->slice(-91, -89) ], [ 10, 11, 12 ];

	is_deeply [ $list->slice(-101, 2) ], [];
}

sub test_each_slice : Test(3) {
	my $result;

	$result = [];
	E(1, 2, 3, 4, 5)->each_slice(2, sub {
		push @$result, $_;
	});
	is_deeply $result, [
		[1, 2],
		[3, 4],
		[5]
	];

	$result = [];
	E(1..10)->each_slice(3, sub {
		push @$result, $_;
	});
	is_deeply $result, [
		[1, 2, 3],
		[4, 5, 6],
		[7, 8, 9],
		[10]
	];

	is_deeply E(1)->countup->each_slice(3)->take(3)->to_a, [
		[1, 2, 3],
		[4, 5, 6],
		[7, 8, 9],
	];
}

sub test_find_index : Test(3) {
	is E(qw/a b c/)->find_index("a"), 0;
	is E(qw/a b c/)->find_index("c"), 2;
	is E(qw/a b c/)->find_index("d"), undef;
}

sub test_minmax : Test(4) {
	my ($min, $max);

	($min, $max) = E(1, 2, 3)->minmax;
	is $min, 1;
	is $max, 3;

	($min, $max) = E([{ n => 1 }, { n => 2 }, { n => 3 }])->minmax_by(sub { $_->{n} });
	is_deeply $min, { n => 1 };
	is_deeply $max, { n => 3 };
}

sub test_is_none : Test(6) {
	is E(0, 0, 0, 0)->none, 1;
	is E(0, 0, 0, 1)->none, 0;
	is E(0, 0, 1, 1)->none, 0;

	is E(3, 5, 7, 9)->none(sub { $_ % 2 == 0 }), 1;
	is E(2, 5, 7, 9)->none(sub { $_ % 2 == 0 }), 0;
	is E(2, 4, 7, 9)->none(sub { $_ % 2 == 0 }), 0;
}

sub test_is_one : Test(6) {
	is E(0, 0, 0, 0)->one, 0;
	is E(0, 0, 0, 1)->one, 1;
	is E(0, 0, 1, 1)->one, 0;

	is E(3, 5, 7, 9)->one(sub { $_ % 2 == 0 }), 0;
	is E(2, 5, 7, 9)->one(sub { $_ % 2 == 0 }), 1;
	is E(2, 4, 7, 9)->one(sub { $_ % 2 == 0 }), 0;
}

sub test_some : Test(2) {
	is E(2, 5, 8, 1, 4)->some(sub {
		$_ >= 10;
	}), 0;

	is E(12, 5, 8, 1, 4)->some(sub {
		$_ >= 10;
	}), 1;
}

sub test_every : Test(2) {
	is E(12, 5, 8, 130, 44)->every(sub {
		$_ >= 10;
	}), 0;

	is E(12, 54, 80, 130, 44)->every(sub {
		$_ >= 10;
	}), 1;
}

sub test_sum : Test {
	is E(1, 2, 3)->sum, 6;
}

sub test_uniq : Test {
	is_deeply E(1, 1, 2, 3, 3, 4)->uniq->to_a, [1, 2, 3, 4];
}

sub test_sort : Test {
	is_deeply E(5, 2, 1, 3, 4)->sort->to_a, [1, 2, 3, 4, 5];
}

sub test_sort_by : Test {
	is_deeply E([
		{ key => 1 },
		{ key => 4 },
		{ key => 5 },
		{ key => 3 },
		{ key => 2 },
	])->sort_by(sub { $_->{key} })->to_a, [
		{ key => 1 },
		{ key => 2 },
		{ key => 3 },
		{ key => 4 },
		{ key => 5 },
	];
}

sub test_compact : Test {
	is_deeply E(undef, 1, undef, 2, 3)->compact->to_a, [1, 2, 3];
}

sub test_length : Test(4) {
	is E(1, 2, 3)->length, 3;
	is E()->length, 0;
	is E(1, 2, 3)->size, 3;
	is E()->size, 0;
}

sub test_flatten : Test(3) {
	is_deeply E([1, 2, [3, 4], 5])->flatten->to_a, [1, 2, 3, 4, 5];
	is_deeply E([1, [2, [3, 4]], 5])->flatten->to_a, [1, 2, 3, 4, 5];
	is_deeply E([1, [2, [3, 4]], 5])->flatten(1)->to_a, [1, 2, [3, 4], 5];
}

sub test_reverse : Test(1) {
	is_deeply E(5, 2, 1, 3, 4)->reverse->to_a, [4, 3, 1, 2, 5];
}

sub test_choice : Test(6) {
	my $r = [];

	is E(1)->choice, 1;
	is E(1)->sample, 1;

	push @$r, E(1, 2)->choice for 0..10;
	ok grep { $_ == 1 } @$r;
	ok grep { $_ == 2 } @$r;
	ok !@{[ grep { $_ != 1 and $_ != 2 } @$r ]};

	push @$r, E(1..10)->choice for 0..100;
	ok !@{[ grep { !(1 <= $_ and $_ <= 10) } @$r ]};
}

sub test_shuffle : Test(2) {
	my $r;

	$r = [ E(1, 2, 3)->shuffle ];
	is scalar(@$r), 3;

	$r = E(1, 2, 3)->shuffle->to_a;
	is scalar(@$r), 3;
}

sub test_transpose : Test(3) {
	is_deeply [ E([])->transpose ], [];

	is_deeply [ E([
		[1, 2],
		[3, 4],
		[5, 6],
	])->transpose ], [
		[1, 3, 5],
		[2, 4, 6],
	];

	throws_ok {
		E([1, 2])->transpose;
	} qr/not a matrix/;
}

sub test_first_and_last : Test(8) {
	my $list = E(1..9);

	is_deeply $list->first(0), [];
	is_deeply $list->first(1), [qw/1/];
	is_deeply $list->first(2), [qw/1 2/];
	is_deeply $list->first(3), [qw/1 2 3/];

	is_deeply $list->last(0), [];
	is_deeply $list->last(1), [qw/9/];
	is_deeply $list->last(2), [qw/8 9/];
	is_deeply $list->last(3), [qw/7 8 9/];
}

__PACKAGE__->runtests;

