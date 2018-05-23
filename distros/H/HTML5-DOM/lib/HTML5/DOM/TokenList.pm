package HTML5::DOM::TokenList;
use strict;
use warnings;

use HTML5::DOM::Node;

use overload
	'""'		=> sub { $_[0]->text }, 
	'@{}'		=> sub { $_[0]->_items }, 
	'bool'		=> sub { 1 }, 
	fallback	=> 1;

sub new {
	my ($class, $node, $attr) = @_;
	my $self = {
		node	=> $node, 
		attr	=> $attr
	};
	bless $self, $class;
	return $self;
}

sub text {
	my $attr = $_[0]->{node}->attr($_[0]->{attr});
	return defined $attr ? $attr : "";
}

sub _items {
	my ($self) = @_;
	my $attr = $self->{node}->attr($self->{attr});
	if (defined $attr) {
		my @items = split(/\s+/, $attr);
		return [] if (scalar(@items) == 1 && $items[0] eq '');
		return \@items;
	}
	return [];
}

sub item {
	my ($self, $index) = @_;
	return $self->_items()->[$index];
}

sub length {
	my ($self) = @_;
	return scalar(@{$self->_items()});
}

sub has {
	my ($self, $token) = @_;
	my $attr = $self->{node}->attr($self->{attr});
	if (defined $attr) {
		return $attr =~ /(\s|^)\Q$token\E(\s|$)/;
	}
	return 0;
}

sub contains { shift->has(@_) }

sub add {
	my $self = shift;
	my $items = $self->_items();
	for my $token (@_) {
		next if ($self->has($token));
		push @$items, $token;
	}
	$self->{node}->attr($self->{attr}, join(" ", @$items));
	return $self;
}

sub remove {
	my $self = shift;
	my $attr = $self->{node}->attr($self->{attr});
	if (defined $attr) {
		for my $token (@_) {
			$attr =~ s/(\s|^)\Q$token\E(\s|$)/ /g;
		}
		$attr =~ s/^\s+|\s+$//;
		$self->{node}->attr($self->{attr}, $attr);
	}
	return $self;
}

sub replace {
	my ($self, $key, $value) = @_;
	my $attr = $self->{node}->attr($self->{attr});
	if (defined $attr) {
		$attr =~ s/(\s|^)\Q$key\E(\s|$)/$1$value$2/g;
		$self->{node}->attr($self->{attr}, $attr);
	}
	return $self;
}

sub toggle {
	my ($self, $token, $force) = @_;
	my $state = defined $force ? $force : !$self->has($token);
	$state ? $self->add($token) : $self->remove($token);
	return $state;
}

sub each {
	my ($self, $callback) = @_;
	my $index = 0;
	for my $node (@{$self->_items()}) {
		$callback->($node, $index);
		++$index;
	}
	return $self;
}

1;
