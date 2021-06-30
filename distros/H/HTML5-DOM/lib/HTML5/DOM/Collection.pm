package HTML5::DOM::Collection;
use strict;
use warnings;

use List::Util;

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

sub first {
	my ($self, $callback) = (shift, shift);
	return $self->[0] if (!$callback);
	return List::Util::first { $_ =~ $callback } @$self if (_is_regexp($callback));
	return List::Util::first { $_->$callback(@_) } @$self;
}

sub last { shift->[-1] }
sub item { shift->[shift] }
sub array { [@{shift()}] }

sub slice {
	my ($self, $offset, $length) = @_;
	
	# handle negative value as offset from end
	$offset = scalar(@$self) + $offset if ($offset < 0);
	
	# validate offset
	return HTML5::DOM::Collection->new([]) if ($offset < 0 || $offset >= scalar(@$self) - 1);
	
	# mean all available elements if no length specified
	$length = scalar(@$self) if !defined $length;
	
	# get maximum available length from offset
	my $max_length = scalar(@$self) - $offset;
	
	# handle negative length
	$length = $max_length + $length if ($length < 0);
	
	# limit available length
	$length = $max_length if ($length > $max_length);
	
	# validate length
	return HTML5::DOM::Collection->new([]) if ($length <= 0);
	
	# return requested slice
	return HTML5::DOM::Collection->new([@$self[$offset..$offset + $length - 1]]);
}

sub head {
	my ($self, $length) = @_;
	return $self->slice(0, $length);
}

sub tail {
	my ($self, $length) = @_;
	return $self->slice(-$length);
}

sub each {
	my ($self, $callback) = (shift, shift);
	my $index = 0;
	for my $node (@$self) {
		$callback->($node, $index++, @_);
	}
	return $self;
}

sub uniq {
	my ($self, $callback) = (shift, shift);
	my %used;
	return HTML5::DOM::Collection->new([grep { my $id = $_->$callback(@_); !$used{defined($id) ? $id : ''}++ } @$self]) if ($callback);
	return HTML5::DOM::Collection->new([grep { !$used{$_->hash}++ } @$self]);
}

sub grep {
	my ($self, $callback) = (shift, shift);
	return HTML5::DOM::Collection->new([grep { $_ =~ $callback } @$self]) if (_is_regexp($callback));
	return HTML5::DOM::Collection->new([grep { $_->$callback(@_) } @$self]);
}

sub reverse {
	my ($self) = @_;
	return HTML5::DOM::Collection->new([reverse @$self]);
}

sub shuffle {
	my ($self) = @_;
	return HTML5::DOM::Collection->new([List::Util::shuffle @$self]);
}

sub map {
	my ($self, $callback) = (shift, shift);
	if (ref($callback) eq 'CODE') {
		my $index = 0;
		return HTML5::DOM::Collection->new([map { $_->$callback($index++, @_) } @$self]);
	} else {
		return HTML5::DOM::Collection->new([map { $_->$callback(@_) } @$self]);
	}
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

sub _is_regexp {
	return ref($_[0]) eq 'Regexp' || ref(\$_[0]) eq 'Regexp';
}

1;
