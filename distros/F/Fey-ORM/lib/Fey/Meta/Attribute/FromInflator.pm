package Fey::Meta::Attribute::FromInflator;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::ORM::Types qw( CodeRef );

use Moose;

extends 'Moose::Meta::Attribute';

has 'inflator' => (
    is       => 'ro',
    isa      => CodeRef,
    required => 1,
);

has 'raw_attribute' => (
    is       => 'ro',
    isa      => 'Fey::Meta::Attribute::FromColumn',
    required => 1,
);

sub column {
    return $_[0]->raw_attribute()->column();
}

# The parent class's constructor is not a Moose::Object-based
# constructor, so we don't want to inline one that is.
__PACKAGE__->meta()->make_immutable( inline_constructor => 0 );

1;

# ABSTRACT: An attribute metaclass for attributes with an inflator

__END__

=pod

=head1 NAME

Fey::Meta::Attribute::FromInflator - An attribute metaclass for attributes with an inflator

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  package MyApp::Song;

  has_table( $schema->table('Song') );

  for my $attr ( grep { $_->can('raw_attribute') } $self->meta()->get_all_attributes )
  {
      ...
  }

=head1 DESCRIPTION

This attribute metaclass is used when L<Fey::ORM::Table> creates
attributes based on an inflator transform.

=head1 METHODS

This class adds a two methods to those provided by
C<Moose::Meta::Attribute>:

=head2 $attr->raw_attribute()

Returns the attribute for the raw version of this data. This is the
original attribute created for the column, which was renamed when the
inflator was declared.

=head2 $attr->column()

Returns the L<Fey::Column> object associated with the raw attribute.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
