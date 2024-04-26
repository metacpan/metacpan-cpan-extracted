package Callback;

use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use ExtUtils::Builder::Node;
use ExtUtils::Builder::Action::Code;

sub add_foo {
	my ($num) = @_;
	ExtUtils::Builder::Node->new(
		target => "foo$_",
		dependencies => [],
		actions => [ ExtUtils::Builder::Action::Code->new(code => "push \@::triggered, $_" ) ],
	);
}

sub add_methods {
	my ($self, $planner) = @_;

	$self->add_delegate($planner, 'add_foo', \&add_foo);
	return;
}

1;
