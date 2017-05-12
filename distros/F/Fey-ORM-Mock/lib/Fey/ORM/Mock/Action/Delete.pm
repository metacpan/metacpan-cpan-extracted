package Fey::ORM::Mock::Action::Delete;
{
  $Fey::ORM::Mock::Action::Delete::VERSION = '0.06';
}

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;

extends 'Fey::ORM::Mock::Action';

has 'pk' => (
    is       => 'ro',
    isa      => 'HashRef[Value]',
    required => 1,
);

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A record of a deletion

__END__

=pod

=head1 NAME

Fey::ORM::Mock::Action::Delete - A record of a deletion

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This class represents a record of a call to C<delete()> for a
C<Fey::ORM::Table> based object.

=head1 METHODS

This class provides the following methods:

=head2 $action->pk()

Returns the primary key of the row deleted as a hash reference, with
the attribute names as keys.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
