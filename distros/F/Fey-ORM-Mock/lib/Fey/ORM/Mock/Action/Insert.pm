package Fey::ORM::Mock::Action::Insert;
{
  $Fey::ORM::Mock::Action::Insert::VERSION = '0.06';
}

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;

extends 'Fey::ORM::Mock::Action';

has 'values' => (
    is       => 'ro',
    isa      => 'HashRef[Item]',
    required => 1,
);

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A record of an insert

__END__

=pod

=head1 NAME

Fey::ORM::Mock::Action::Insert - A record of an insert

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This class represents a record of a call to C<insert()> for a
C<Fey::ORM::Table> based object.

=head1 METHODS

This class provides the following methods:

=head2 $action->values()

Returns the values of the row inserted as a hash reference, with the
attribute names as keys. These values are provided as-is, so they may
include objects passed to C<insert()>

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
