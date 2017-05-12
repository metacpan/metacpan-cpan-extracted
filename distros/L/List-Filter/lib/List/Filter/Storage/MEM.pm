package List::Filter::Storage::MEM;
# use base qw( Class::Base );
use base qw( List::Filter::StorageBase );

=head1 NAME

List::Filter::Storage::MEM - filter storage in memory

=head1 SYNOPSIS

   use List::Filter::Storage::MEM;
   my $ffpsm = List::Filter::Storage::MEM->new();

   # This is a plugin, not intended for direct use.
   # See: List:Filter:Storage

=head1 DESCRIPTION

List::Filter::Storage::MEM, is a Plug-in to use for
"storing" List::Filter filters in memory, so that they can be
recalled using the List::Filter::Storage interface that
scans through multiple storage locations.

The filter_data structure may be passed in as the "connect_to"
parameter, or one will be created internally if one has not been
passed in.  This may be added to with the "save" method.
The entire structure can be extracted with the "filter_data"
accessor, or (more typically) filter's may be looked up by name,
using the "lookup" method.

=head2 METHODS

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util qw( lock_keys unlock_keys );

our $VERSION = '0.01';

=head2 initialization code

=over

=item new

Instantiates a new List::Filter::Profile object.

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes.

With no arguments, the newly created filter will be empty.

=cut

# Note: "new" (inherited from Class::Base)
# calls the following "init" routine automatically.

=item init

Initialize object attributes and then lock them down to prevent
accidental creation of new ones.

Note: there is no leading underscore on name "init", though it's
arguably an "internal" routine (i.e. not likely to be of use to
client code).

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  $self->SUPER::init( $args );  # uncomment if this is a child class

  my $filter_data = $args->{connect_to} || {};
  $self->set_filter_data( $filter_data );

  lock_keys( %{ $self } );
  return $self;
}

=item save

Given a filter "saves" it in memory.

Returns the ref to the filter object.

=cut

sub save {
  my $self    = shift;
  my $filter = shift;

  # convert $filter object into a data structure,

  my $filter_name   = $filter->name;

  my $method         = $filter->method;
  my $description    = $filter->description;
  my $terms          = $filter->terms;
  my $modifiers      = $filter->modifiers;

  my $filter_href = {  method       => $method,
                       description  => $description,
                       terms        => $terms,
                       modifiers    => $modifiers,
                     };

  # add it to the internal stash (replaces any existing one of same name)
  my $filter_data = $self->filter_data;
  $filter_data->{ $filter_name } = $filter_href;

  return $filter;
}


=item lookup

=cut

# Note: this is *identical* to the code in (the original) YAML.pm
sub lookup {
  my $self = shift;
  my $name = shift;

  my $filter_data = $self->filter_data;

  my $filter;
  if ( my $filter_href = $filter_data->{ $name } ) {

    # convert this data into a filter object.
    my $terms        = $filter_href->{terms};
    my $method       = $filter_href->{method};
    my $description  = $filter_href->{description};
    my $modifiers    = $filter_href->{modifiers};

    my $filter_class = $self->define_filter_class;
    $filter = $filter_class->new(
      { name         => $name,
        terms        => $terms,
        method       => $method,
        description  => $description,
        modifiers    => $modifiers,
      } );

  }
  return $filter;
}



=item list_filters

Returns a list of all avaliable named filters.

=cut

sub list_filters {
  my $self = shift;
  my $filter_data = $self->filter_data;
  my @names = keys (%{ $filter_data });
  return \@names;
}


=back

=head2 special accessors (access the "extra" namespace)

=over

=item filter_data

Getter for object attribute filter_data

=cut

sub filter_data {
  my $self = shift;
  my $filter_data = $self->extra->{ filter_data };

  return $filter_data;
}

=item set_filter_data

Setter for object attribute set_filter_data

=cut

sub set_filter_data {
  my $self = shift;
  my $filter_data = shift;
  $self->extra->{ filter_data } = $filter_data;
  return $filter_data;
}


1;

=back

=head2 basic accessors (defined in L<List::Filter::StorageBase>);

=over

=item connect_to

Getter for object attribute connect_to

=item set_connect_to

Setter for object attribute set_connect_to

=item owner

Getter for object attribute owner

=cut

=item set_owner

Setter for object attribute set_owner

=cut

=item password

Getter for object attribute password

=cut

=item set_password

Setter for object attribute set_password

=cut

=item attributes

Getter for object attribute attributes

=item set_attributes

Setter for object attribute set_attributes

=item extra

Getter for object attribute extra

=item set_extra

Setter for object attribute set_extra

=back

=head1 SEE ALSO

L<List::Filter>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
18 May 2007

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
