package HTML5::DOM::Collection;
use strict;
use warnings;

use overload
	'""'		=> sub { shift->html }, 
	'bool'		=> sub { 1 }, 
	fallback	=> 1;

sub new {
	my ($class, $nodes) = @_;
	$nodes = [] if (!$nodes || ref($nodes) ne 'ARRAY');
	return bless $nodes, $class;
}

sub add {
	my $self = shift;
	push @{$self}, shift;
	return $self;
}

sub length { scalar(@{shift()}); }
sub first { shift->[0] }
sub last { shift->[-1] }
sub item { shift->[shift] }
sub array { [@{shift()}] }

sub each {
	my ($self, $callback) = @_;
	my $index = 0;
	for my $node (@{shift()}) {
		$callback->($node, $index);
		++$index;
	}
	return $self;
}

sub text {
	my @nodes;
	for my $node (@{shift()}) {
		push @nodes, $node->text;
	}
	return join("", @nodes);
}

sub html {
	my @nodes;
	for my $node (@{shift()}) {
		push @nodes, $node->html;
	}
	return join("", @nodes);
}

1;
