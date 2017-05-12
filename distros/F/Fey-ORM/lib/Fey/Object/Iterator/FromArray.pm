package Fey::Object::Iterator::FromArray;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::ORM::Types qw( IterableArrayRef );

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

with 'Fey::ORM::Role::Iterator';

has '_objects' => (
    is       => 'ro',
    isa      => IterableArrayRef,
    coerce   => 1,
    required => 1,
    init_arg => 'objects',
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _get_next_result {
    my $self = shift;

    return $self->_objects()->[ $self->index() ];
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub reset {
    my $self = shift;

    $self->_reset_index();
}
## use critic

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An iterator which iterates over an array of objects

__END__

=pod

=head1 NAME

Fey::Object::Iterator::FromArray - An iterator which iterates over an array of objects

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  use Fey::Object::Iterator::FromArray;

  my $iter = Fey::Object::Iterator::FromArray->new(
      classes => 'MyApp::User',
      objects => \@users,
  );

  my $iter2 = Fey::Object::Iterator::FromArray->new(
      classes => [ 'MyApp::User', 'MyApp::Group' ],
      objects => [ [ $user1, $group1 ], [ $user2, $group1 ] ],
  );

  print $iter->index();    # 0

  while ( my $user = $iter->next() ) {
      print $iter->index();    # 1, 2, 3, ...
      print $user->username();
  }

  # will return cached objects now
  $iter->reset();

=head1 DESCRIPTION

This class provides an object which does the
C<Fey::ORM::Role::Iterator> role, but gets its data from an array
reference. This lets you provide a single API that accepts data from
L<Fey::ORM>-created iterators, or existing data sets.

=head1 METHODS

This class provides the following methods:

=head2 $iterator->new()

The constructor requires two parameters, C<classes> and
C<objects>. The C<classes> parameter can be a single class name, or an
array reference of names.

The C<objects> parameter should be an array reference. That reference
can contain a list of objects, or an a list of array references, each
of which contains objects.

In either case, the objects must be subclasses of
L<Fey::Object::Table>.

=head2 $iterator->reset()

Resets the iterator so that the next call to C<< $iterator->next() >>
returns the first object(s).

=head1 ROLES

This class does the L<Fey::ORM::Role::Iterator> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
