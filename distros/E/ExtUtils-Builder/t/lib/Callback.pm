package Callback;

use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use ExtUtils::Builder::Util 'code';

sub add_foo {
	my ($planner, $num) = @_;
	$planner->create_node(
		target => "foo$_",
		dependencies => [],
		actions => [ code(code => "push \@::triggered, $_" ) ],
	);
}

sub add_methods {
	my ($self, $planner) = @_;

	$planner->add_delegate('add_foo', \&add_foo);
	return;
}

1;
