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

sub map {
	my $self = shift;
	my @result;
	if (ref($_[0]) eq 'CODE') {
		my $method = shift;
		my $index = 0;
		for my $node (@$self) {
			push @result, $method->($node, $index, @_);
			++$index;
		}
	} else {
		my $method = shift;
		for my $node (@$self) {
			push @result, $node->$method(@_);
		}
	}
	return HTML5::DOM::Collection->new(\@result);
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
