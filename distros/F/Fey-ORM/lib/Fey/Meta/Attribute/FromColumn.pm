package Fey::Meta::Attribute::FromColumn;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Moose;

extends 'Moose::Meta::Attribute';

has 'column' => (
    is       => 'ro',
    isa      => 'Fey::Column',
    required => 1,
);

# The parent class's constructor is not a Moose::Object-based
# constructor, so we don't want to inline one that is.
__PACKAGE__->meta()->make_immutable( inline_constructor => 0 );

1;

# ABSTRACT: An attribute metaclass for column-based attributes

__END__

=pod

=head1 NAME

Fey::Meta::Attribute::FromColumn - An attribute metaclass for column-based attributes

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  package MyApp::Song;

  has_table( $schema->table('Song') );

  for my $attr ( grep { $_->can('column') } $self->meta()->get_all_attributes )
  {
      ...
  }

=head1 DESCRIPTION

This attribute metaclass is used when L<Fey::ORM::Table> creates
attributes for the class's associated table.

=head1 METHODS

This class adds a single method to those provided by
C<Moose::Meta::Attribute>:

=head2 $attr->column()

Returns the L<Fey::Column> object associated with this attribute.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
