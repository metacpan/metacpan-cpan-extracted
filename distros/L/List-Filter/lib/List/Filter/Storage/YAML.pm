package List::Filter::Storage::YAML;
use base qw( List::Filter::StorageBase );

=head1 NAME

List::Filter::Storage::YAML - plugin for filter storage via YAML files

=head1 SYNOPSIS

   # This is a plugin, not intended for direct use.
   # See: List:Filter:Storage

   use List::Filter::Storage::YAML;
   my $storage = List::Filter::Storage::YAML->new( {
                                     connect_to  => $yaml_file,
                                   } );

    my $filter = List::Filter->new(
     { name         => 'some_search_filter',
         # [... see List::Filter ...]
     } );

   $storage->save( $filter )

   my $named_filter = $storage->lookup( $name );


=head1 DESCRIPTION

List::Filter::Storage::YAML is the plugin
that handles storage of List::Filter "filters"
(e.g. "filters", "transforms") to YAML files.

=head2 METHODS

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util qw( lock_keys unlock_keys );
use File::Path     qw(mkpath);
use File::Basename qw(dirname fileparse);
use Env  qw(HOME);
use YAML qw(DumpFile LoadFile);

our $VERSION = '0.01';

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

  $self->SUPER::init( $args );

  lock_keys( %{ $self } );
  return $self;
}


=head2 main methods

=over

=item lookup

Given a filter name, returns a matching filter object, or undef.

=cut

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

=item save

Given a filter, adds it to the internal mass of "filter_data",
and saves the entire set to a yaml file.

Excludes any filters that are named with a leading underscore.

Returns a reference to the given filter object.

=cut

sub save {
  my $self    = shift;
  my $filter  = shift;

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

  # write all filter_data out to the yaml file.
  my $stash = $self->connect_to;
  #  DumpFile( $stash, $filter_data );

  # exclude filters named with a leading underscore
  my $saves = {};
  foreach my $name (keys %{ $filter_data }) {
    unless ($name =~ m{^_}x) {
      $saves->{ $name } = $filter_data->{ $name };
    }
  }
  DumpFile( $stash, $saves );

  return $filter;
}

=back

=head1 internal routines

=over

=item slurp_yaml_filter_data

This method actually reads the yaml file, and stores the hash of hashes
structure inside of the object in "filter_data".

=cut

# Rather than call this from init, this method is used from the
# filter_data accessor, to conserve memory until the data is
# needed.
sub slurp_yaml_filter_data {
  my $self = shift;

  my $filter_data;
  my $stash = $self->connect_to;
  if (-f $stash) {
    $filter_data = LoadFile("$stash");
    $self->set_filter_data( $filter_data );
  }
  return $filter_data;
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

Note: the yaml file is not slurped in until an attempt is made
to access this data.

=cut

sub filter_data {
  my $self = shift;
  my $filter_data = $self->extra->{ filter_data };

  # if filter_data doesn't yet exist, slurp it now
  unless( $filter_data ) {
    $filter_data = $self->slurp_yaml_filter_data;
  }

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

=head2 basic accessors (defined in List::Filter::Storage);

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

=head2 INTERNALS

Outside of this module, a "filter" is an object, inside of this
module, it's a hashref with four fields: "method", "description",
"terms", "modifiers".  Note, that the "name" is excluded
from this list, because each of these hashrefs is stored inside
a larger hashref, keyed by "name" for rapid lookups.

The external YAML file contains a copy of this data structure,
and it is read and written in it's entirety, and held cached in
memory inside this object.

=head2 NOTES

=head1 SEE ALSO

L<List::Filter::Project>
L<List:Filter:Storage>
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
