use Test::Pod::Coverage tests=>1;
pod_coverage_ok(
	"Games::Alak",
	# This module has a number of private methods whose names do not begin with
	# _.  This is kind of unfortunate, but it's too late now to change things,
	# so I will just manually omit them.
	{ also_private => [
		qw/^(?:dump_tree|figure_successors|grow|new_node|omit_if_zero|optimal_move|play|prompt_for_next_move)$/
	], },
	"Games::Alak is covered"
);
