package List::DoubleLinked;
$List::DoubleLinked::VERSION = '0.005';
use strict;
use warnings FATAL => 'all';

use Carp qw/carp croak/;
use Scalar::Util 'weaken';
use namespace::clean 0.20;
#no autovivication;

sub new {
	my ($class, @items) = @_;
	my $self = bless {
		head => undef,
		tail => undef,
		head => { prev => undef },
		tail => { tail => undef },
	}, $class;
	$self->{head}{next} = $self->{tail};
	$self->{tail}{prev} = $self->{head};
	$self->push(@items);
	return $self;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms, ControlStructures::ProhibitCStyleForLoops)

sub push {
	my ($self, @items) = @_;
	for my $item (@items) {
		my $new_tail = {
			item => $item,
			prev => $self->{tail}{prev},
			next => $self->{tail},
		};
		$self->{tail}{prev}{next} = $new_tail;
		$self->{tail}{prev} = $new_tail;
		$self->{head}{next} = $new_tail if $self->{head}{next} == $self->{tail};
	}
	return;
}

sub pop {
	my $self = shift;
	croak 'No items to pop from the list' if $self->{tail}{prev} == $self->{head};
	my $ret  = $self->{tail}{prev};
	$self->{tail}{prev} = $ret->{prev};
	$ret->{prev}{next} = $self->{tail};
	return $ret->{item};
}

sub unshift {
	my ($self, @items) = @_;
	for my $item (reverse @items) {
		my $new_head = {
			item => $item,
			prev => $self->{head},
			next => $self->{head}{next},
		};
		$self->{head}{next}{prev} = $new_head;
		$self->{head}{next} = $new_head;
	}
	return;
}

sub shift {
	my $self = CORE::shift;
	croak 'No items to shift from the list' if $self->{head}{next} == $self->{tail};
	my $ret  = $self->{head}{next};
	$self->{head}{next} = $ret->{next};
	$ret->{next}{prev} = $self->{head};
	return $ret->{item};
}

sub flatten {
	my $self = CORE::shift;
	my @ret;
	for (my $current = $self->{head}{next} ; $current != $self->{tail}; $current = $current->{next}) {
		CORE::push @ret, $current->{item};
	}
	return @ret;
}

sub front {
	my $self = CORE::shift;
	return $self->{head}{next}{item};
}

sub back {
	my $self = CORE::shift;
	return $self->{tail}{prev}{item};
}

sub empty {
	my $self = CORE::shift;
	return $self->{head}{next} == $self->{tail}
}

sub size {
	my $self = CORE::shift;
	my $ret  = 0;
	for (my $current = $self->{head}{next} ; $current != $self->{tail}; $current = $current->{next}) {
		$ret++;
	}
	return $ret;
}

sub erase {
	my ($self, $iter) = @_;

	my $ret = $iter->next;
	my $node = $iter->[0];

	$node->{prev}{next} = $node->{next};
	$node->{next}{prev} = $node->{prev};

	weaken $node;
	carp 'Node may be leaking' if $node;

	return $ret;
}

sub begin {
	my $self = CORE::shift;
	require List::DoubleLinked::Iterator;

	return List::DoubleLinked::Iterator->new($self->{head}{next});
}

sub end {
	my $self = CORE::shift;
	require List::DoubleLinked::Iterator;

	return List::DoubleLinked::Iterator->new($self->{tail});
}

sub DESTROY {
	my $self    = CORE::shift;
	my $current = $self->{head};
	while ($current) {
		delete $current->{prev};
		$current = delete $current->{next};
	}
	return;
}

# ABSTRACT: Double Linked Lists for Perl

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

List::DoubleLinked - Double Linked Lists for Perl

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use List::DoubleLinked;
 my $list = List::DoubleLinked->new(qw/foo bar baz/);
 $list->begin->insert_after(qw/quz/);
 $list->erase($list->end->previous);

=head1 DESCRIPTION

This module provides a double linked list for Perl. You should ordinarily use arrays instead of this, they are faster for almost any usage. However there is a small set of use-cases where linked lists are necessary. While you can use the list as an object directly, for most purposes it's recommended to use iterators. C<begin()> and C<end()> will give you iterators pointing at the start and end of the list.

=head1 METHODS

=head2 new(@elements)

Create a new double linked list. @elements is pushed to the list.

=head2 begin()

Return an L<iterator|List::Double::Linked::Iterator> to the first element of the list.

=head2 end()

Return an L<iterator|List::Double::Linked::Iterator> to the last element of the list.

=head2 flatten()

Return an array containing the same values as the list does. This runs in linear time.

=head2 push(@elements)

Add @elements to the end of the list.

=head2 pop()

Remove an element from the end of the list and return it

=head2 unshift(@elements)

Add @elements to the start of the list.

=head2 shift()

Remove an element from the end of the list and return it

=head2 front()

Return the first element in the list

=head2 back()

Return the last element in the list.

=head2 empty()

Returns true if the list has no elements in it, returns false otherwise.

=head2 size()

Return the length of the list. This runs in linear time.

=head2 erase($iterator)

Remove the element under $iterator. Note that this invalidates C<$iterator>, therefore it returns the next iterator.

=head1 WTF WHERE YOU THINKING?

This module is a rather an exercise in C programming. I was surprised that I was ever going to need this (and even more surprised no one ever uploaded something like this to CPAN before), but B<I needed a data structure that provided me with stable iterators>. I need to be able to splice off any arbitrary element without affecting any other arbitrary element. You can't really implement that using arrays, you need a double linked list for that.

This module is aiming for correctness, it is not optimized for speed. Linked lists in Perl are practically never faster than arrays anyways, if you're looking at this because you think it will be faster please think again. L<splice|perlfunc/"splice"> is your friend.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
