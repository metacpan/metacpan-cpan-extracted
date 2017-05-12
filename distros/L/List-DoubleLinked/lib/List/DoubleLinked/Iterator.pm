package List::DoubleLinked::Iterator;
$List::DoubleLinked::Iterator::VERSION = '0.005';
use strict;
use warnings FATAL => 'all';

use Carp qw/croak/;
use Scalar::Util 'weaken';
use namespace::clean 0.20;

use overload 
	'==' => sub {
		my ($left, $right, $switch) = @_;
		return $left->[0] == $right->[0];
	},
	'!=' => sub {
		my ($left, $right, $switch) = @_;
		return $left->[0] != $right->[0];
	},
	fallback => 1;

sub new {
	my ($class, $node) = @_;
	my $self = bless [ $node ], $class;
	weaken $self->[0];
	Internals::SvREADONLY(@{$self}, 1);
	return $self;
}

sub get {
	my $self = shift;
	return if not defined $self->[0];
	return $self->[0]{item};
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)

sub next {
	my $self = shift;
	my $node  = $self->[0];
	croak 'Node no longer exists' if not defined $node;
	return __PACKAGE__->new($node->{next});
}

sub previous {
	my $self = shift;
	my $node  = $self->[0];
	croak 'Node no longer exists' if not defined $node;
	return __PACKAGE__->new($node->{prev});
}

sub insert_before {
	my ($self, @items) = @_;
	my $node  = $self->[0];
	for my $item (reverse @items) {
		my $new_node = {
			item => $item,
			prev => $node->{prev},
			next => $node,
		};
		$node->{prev}{next} = $new_node;
		$node->{prev} = $new_node;

		$node = $new_node;
	}
	return;
}

sub insert_after {
	my ($self, @items) = @_;
	my $node  = $self->[0];
	for my $item (@items) {
		my $new_node = {
			item => $item,
			prev => $node,
			next => $node->{next},
		};
		$node->{next}{prev} = $new_node;
		$node->{next} = $new_node;

		$node = $new_node;
	}
	return;
}

# ABSTRACT: Double Linked List Iterators

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

List::DoubleLinked::Iterator - Double Linked List Iterators

=head1 VERSION

version 0.005

=head1 METHODS

=head2 get()

Get the value of the iterator

=head2 next()

Get the next iterator, this does not change the iterator itself.

=head2 previous()

Get the previous iterator, this does not change the iterator.

=head2 remove()

Remove the element from the list. This invalidates the iterator.

=head2 insert_before(@elements)

Insert @elements before the current iterator

=head2 insert_after

Insert @elements after the current iterator

=for Pod::Coverage new

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
