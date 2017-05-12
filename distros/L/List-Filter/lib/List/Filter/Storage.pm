package List::Filter::Storage;
use base qw( Class::Base );


=head1 NAME

List::Filter::Storage - storage handler for filters (e.g. filters)

=head1 SYNOPSIS

   use List::Filter::Storage;
   $stash_file = "$ENV{HOME}/project_filters.yaml";
   my $filter_storage = List::Filter::Storage->new({
                    storage => [ $stash_file ],
                 });
   my $filter = List::Filter->new(
      { name         => 'skip_boring_stuff',
        terms        => ['-\.vb$', '\-.js$'],
        method       => 'skip_boring_stuff',
        description  => "Skip the really boring stuff",
        modifiers    => "xi",
      } );

   $filter_storage->save( $filter );

   # And later, in some other code...

   my $filter_storage = List::Filter::Storage->new({ storage =>
                                                    [ $stash_file ] });

   my $filter = $filter_storage->lookup( 'skip_boring_stuff' );


    # Filters lookd up from a path of storage locations:
    # (1) yaml file (2) a DBI database connection
    my $yaml_file = "/tmp/filter_storage.yaml";
    my $lfs = List::Filter::Storage->new( {
           storage=> [
             $yaml_file,
             { format     => 'DBI',
               connect_to => $connect_to,  # e.g. "dbi:Pg:dbname=$dbname"
               owner      => $owner,
               password   => $password,
             },
          ] } );


  # storage format "MEM" keeps data in memory only
    my $lfs = List::Filter::Storage->new( {
           storage=> [
            [
              { format     => 'MEM',
                connect_to => {},
              }
            ] });

   # automatically make copies in the yaml file of any filters used from DBI
   my $filter_storage = List::Filter::Storage->new(
                { save_filters_when_used => $args->{ save_filters_when_used },
                  storage                => [ $yaml_file,
                                              { format     => 'DBI',
                                                connect_to => $connect_to,
                                                owner      => $owner,
                                                password   => $password,
                                              },
                                            ],

                } );

   # a storage handler can save objects of type 'transform'
   # (a child of filter):
   my $storage_tran = List::Filter::Storage->new(
                                { storage => [ $stash_file ],
                                  type    => 'transform',
                                } );
   $storage_tran->save( $transform );



=head1 DESCRIPTION

List::Filter::Storage is a "storage handler", it deals with
multiple locations of different types of pluggable backing stores
to save and retrieve "filters" (and variant types of filters such
as 'transforms').  See L<List::Filter> and L<List::Filter::Transform>.

To review the nature of the items that need to be stored: At the
heart of a "filter" is an array reference called 'terms' which
contains a list of arbitrary perl data structures.  In the case
of the simple 'filter" type, this is a list of regular
expressions, in the case of 'transform' it's a list of array
references, each containing the three parts of a perl
substitution (in an unusual order, counting from 1 to 3: s/1/3/2).

Also, in addition to this list of 'terms', each filter object
also has some attached to it some additional fields of data:
'name', 'method', 'modifiers', and 'description'.

So this might be thought of an ORM system, except that it's much
more specialized (or perhaps "even more braindead") than ORMs
usually are.  Also, while it can use a database as a backing
store (via DBI), the default storage system is simply to dump the
data to YAML files, which have the advantage of being relatively
easy to read and edit.

=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util qw( lock_keys unlock_keys );
use List::Filter::Internal;
use File::Path      qw(mkpath);
use File::Basename  qw(dirname fileparse);
use Env  qw(HOME);
use YAML qw(DumpFile LoadFile);
use Module::List::Pluggable qw( list_modules_under import_modules );

our $VERSION = '0.01';
my $DEBUG = 0;

=item new

Instantiates a new List::Filter::Storage object.

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes.

With no arguments creates a storage handler using the
default values: we're assumed to be storing data of type
"filter" in a "filters.yaml" file located in the
".list-filter" subdirectory of the users home directory.

Optional arguments:

=over

=item type

scalar: the type of the filter to be stored (e.g. 'filter', 'transform')
Default: 'filter'

=item storage

aref: a search path of yaml files or hrefs specifying less
commonly used storage formats (DBI, MEM, CODE, etc)
Filter look-ups try each one in sequence.

If not specified, defaults to a single yaml file in a dot
location in the $HOME directory.

Valid entries in the storage path are described in more detail
below in L</"the storage search path">

=item write_storage

By default filters are saved to the first place in the storage path.
Setting this field should be done to save to an alternate location.

(This may or may not be a location present in the storage path,
but it almost always will be, or else you would then be saving
things you couldn't see again later.  Sometimes though, you might
want to do this, e.g. when copying filters from one location to
another.)

=item save_filters_when_used

A flag to indicate that copies of any filters that are used
should be saved off to the "write_storage" location.

=back

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

  # get names of all modules under List::Filter::Storage
  my $storage_plugins = list_modules_under( 'List::Filter::Storage');

  # create a lookup hash to check for existence of a plugin
  my %lookup;
  @lookup{ @{ $storage_plugins } } = (1) x @{ $storage_plugins };
  my $storage_plugin_lookup = \%lookup;
  $self->set_storage_plugin_lookup( $storage_plugin_lookup ); # later init code needs this

  my $type = $args->{ type } || 'filter';
  $self->set_type( $type );                                   # later init code needs this

  my $lfi = List::Filter::Internal->new();
  my $storage = $lfi->qualify_storage_from_namespace(
                        $args->{ storage },
                        $type,
                       );

  my $storage_objects = $self->define_storage_objects( $storage );

  # First entry in storage attribute is the default location to save to
  my $write_storage = $args->{write_storage} || $storage->[0];
  my $write_storage_object = $self->objectify_storage( $write_storage );

  # define new attributes
  my $attributes = {
              type                   => $type,
              storage                => $storage,                # aref
              write_storage          => $write_storage,          # scalar
              save_filters_when_used => $args->{ save_filters_when_used },  # boolean

              # internal use
              write_storage_object   => $write_storage_object,   # scalar
              storage_objects        => $storage_objects,        # aref
              storage_plugin_lookup  => $storage_plugin_lookup,  # href
           };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  lock_keys( %{ $self } );
  return $self;
}

=item lookup

Given a filter name, returns a matching filter object, or undef.

Interates over the storage path, looking in each until a matching
name has been found.

If the lookup fails it returns undef, emitting the warning:
  "Failed lookup of $type with name: $name";

=cut

sub lookup {
  my $self = shift;
  my $name = shift;
  my $storage_objects = $self->{storage_objects};

  # interate over storage path, look in each until a matching
  # name has been found.

  my $filter;
  foreach my $storage_handle ( @{ $storage_objects } ) {
    if ( $filter = $storage_handle->lookup( $name ) ) {
      last;
    }
  }

  unless( $filter ) {
    my $type = $self->type;
    carp "Failed lookup of $type with name: $name";
    return;
  }

  # let the filter know where it came from
  $filter->set_storage_handler( $self );

  # pass on the flag setting to the filter
  if( $self->save_filters_when_used ) {
    $filter->set_save_filters_when_used( 1 );
  }

  return $filter;
}

=item save

Save the given filter object.

Returns a copy of it.

=cut

sub save {
  my $self = shift;
  my $filter = shift;

  my $wso = $self->write_storage_object;
  $wso->save( $filter );
  return $filter; # more likely to be a useful return than $self
}

=item define_storage_objects

Converts the array of storage locations into an array of
storage objects to make "lookups" simpler.

=cut

sub define_storage_objects {
  my $self = shift;
  my $storage = shift;

  my @storage_objects = ();
  foreach my $stash (@{ $storage }){
    my $storage_object = $self->objectify_storage( $stash );
    push @storage_objects, $storage_object;
  }
  return \@storage_objects;
}

=item objectify_storage

Convert an entry from the storage path into an object of the
appropriate class:  List::Filter::Storage::*

=cut

# Determines the type of storage requested (YAML, DBI, etc.)
# and does a "require" of the appropriate plugin, or croaks
# if it can't be found.
sub objectify_storage {
  my $subname = ( caller(0) )[3];
  my $self  = shift;
  my $stash = shift;

  # allowed list of plugin formats (a hash ref)
  my $storage_plugin_lookup = $self->storage_plugin_lookup;

  my ($format, @plugin_name, $plugin_class, $db_type,
      $connect_to, $owner, $password, $attributes);

  if (ref $stash eq 'HASH') {

    $format      = $stash->{format};
    $connect_to  = $stash->{connect_to};
    $owner       = $stash->{owner};
    $password    = $stash->{password};
    $attributes  = $stash->{attributes};

    push @plugin_name, uc( $format );

    if ($format eq 'DBI') {
      require DBI;
      $db_type = ( split ":", $connect_to )[1];
      my $specific_plugin = "DBI::$db_type";
      push @plugin_name, $specific_plugin;
    }

  } else { # if not href, $stash is a file name, extension determines format
    $connect_to = $stash;

    # examine the string, looking for a file-extension.
    my $ext_pat = qr{ (?<=\.) [^.]{0,5} $ }x;
           # extension up to 5 chars, sans dot
    my $extension = ( fileparse($stash, $ext_pat ) )[2];

    push @plugin_name, uc( $extension );
  }

  # does a plugin exist?  For DBI plugins, use database-specific
  # one if available.

 PLUGIN:
  foreach my $plugin_name (@plugin_name) {
    $plugin_class = "List::Filter::Storage::$plugin_name";
    if ( $storage_plugin_lookup->{ $plugin_class } ) {
      last PLUGIN;
    }
  } continue {
    my $mess = "No storage plug-in found for format $format";
    $mess .= " (db type: $db_type)" if $db_type;
    croak $mess;
  }
  # "last PLUGIN" jumps to here

  eval "require $plugin_class";
  if ($@) {
    die "Could not require $plugin_class: $@\n";
  }

  my $type = $self->type;
  my $storage_obj = $plugin_class->new(
                        { connect_to  => $connect_to,
                          owner       => $owner,
                          password    => $password,
                          attributes  => $attributes,
                          type        => $type,          # type of filters to store
                        } );

  return $storage_obj;
}



=item list_filters

Returns a list of all avaliable named filters.

=cut

sub list_filters {
  my $self = shift;

  my %uniq = ();
  my $storage_objects = $self->storage_objects;
  foreach my $store (@{ $storage_objects}) {
    my $add_filters = $store->list_filters;
    @uniq{ @{ $add_filters } } = (1) x @{ $add_filters };
  }

  my @filters = keys( %uniq );
  return \@filters;
}



=back

=head2 Basic accessors (setters use "set_" prefix, getters have none)

=over

=item type

Getter for object attribute type

=cut

sub type {
  my $self = shift;
  my $type = $self->{ type };
  return $type;
}

=item set_type

Setter for object attribute set_type

=cut

sub set_type {
  my $self = shift;
  my $type = shift;
  $self->{ type } = $type;
  return $type;
}

=item storage

Getter for object attribute storage

=cut

sub storage {
  my $self = shift;
  my $storage = $self->{ storage };
  return $storage;
}

=item set_storage

Setter for object attribute set_storage

=cut

sub set_storage {
  my $self = shift;
  my $storage = shift;
  $self->{ storage } = $storage;

  # if this is changed, keep storage_objects in sync
  my $storage_objects = $self->define_storage_objects( $storage );
  $self->set_storage_objects( $storage_objects );

  return $storage;
}


=item write_storage

Getter for object attribute write_storage

=cut

sub write_storage {
  my $self = shift;
  my $write_storage = $self->{ write_storage };
  return $write_storage;
}

=item set_write_storage

Setter for object attribute set_write_storage.

Note, this also automatically sets write_storage_object.

=cut

sub set_write_storage {
  my $self = shift;
  my $write_storage = shift;
  $self->{ write_storage } = $write_storage;

  # if this is changed, keep the object form of this in sync
  my $write_storage_object = $self->objectify_storage( $write_storage );
  $self->set_write_storage_object( $write_storage_object );

  return $write_storage;
}



=item save_filters_when_used

Getter for object attribute save_filters_when_used

=cut

sub save_filters_when_used {
  my $self = shift;
  my $save_filters_when_used = $self->{ save_filters_when_used };
  return $save_filters_when_used;
}

=item set_save_filters_when_used

Setter for object attribute set_save_filters_when_used

=cut

sub set_save_filters_when_used {
  my $self = shift;
  my $save_filters_when_used = shift;
  $self->{ save_filters_when_used } = $save_filters_when_used;
  return $save_filters_when_used;
}

=item write_storage_object

Getter for object attribute write_storage_object.

=cut


sub write_storage_object {
  my $self = shift;
  my $write_storage_object = $self->{ write_storage_object };
  return $write_storage_object;
}

=item set_write_storage_object

Setter for object attribute set_write_storage_object

=cut

sub set_write_storage_object {
  my $self = shift;
  my $write_storage_object = shift;
  $self->{ write_storage_object } = $write_storage_object;
  return $write_storage_object;
}

=item storage_plugin_lookup

Getter for object attribute storage_plugin_lookup

=cut

sub storage_plugin_lookup {
  my $self = shift;
  my $storage_plugin_lookup = $self->{ storage_plugin_lookup };

  return $storage_plugin_lookup;
}

=item set_storage_plugin_lookup

Setter for object attribute set_storage_plugin_lookup

=cut

sub set_storage_plugin_lookup {
  my $self = shift;
  my $storage_plugin_lookup = shift;
  $self->{ storage_plugin_lookup } = $storage_plugin_lookup;
  return $storage_plugin_lookup;
}

=item storage_objects

Getter for object attribute storage_objects

=cut

sub storage_objects {
  my $self = shift;
  my $storage_objects = $self->{ storage_objects };
  return $storage_objects;
}

=item set_storage_objects

Setter for object attribute set_storage_objects

=cut

sub set_storage_objects {
  my $self = shift;
  my $storage_objects = shift;
  $self->{ storage_objects } = $storage_objects;
  return $storage_objects;
}

1;

=back

=head1 MOTIVATION

L<List::Filter::Storage> was designed to answer an immediate need
of the L<List::Filter> project: to provide a way to share
"filters" among different applications.  This in itself is
requires only a very light-duty storage apparatus (dumping to
L<YAML> files will most likely be more than adequate).

But in order to hold open the door that List::Filter might
someday need to scale larger than it's current intended purposes
(writing command line utilities, and so on), it seemed logical to
allow the use of storage facilities that allow concurrent, shared
access, and this could be done most obviously via L<DBI>.

(However: this project makes no use whatsover of the "relational"
aspects of an RDBMS, and I offer my sincere apologies if this
seems to be part of a disturbing trend -- remember, providing for
DBI storage I<at all> already seems like over-kill for this
project.  And qualifying perl regular expressions with a
relational database is a bit beyond the current scope.)

So, having gone that far, I took the project one step further,
and provided a plug-in extension mechanism so that other storage
formats could be defined in the future.  Possibilities include:
XML, TSV, CSV, INI...  and so on.


=head2 the storage search path

The "storage" search path hopefully seems like a straight-forward
concept (search paths are common enough: the PATH environment
variable, the perl @INC array, etc.). However, the syntax of the
"storage" attribute may seem a little peculiar: the general idea
is to make it indefinitely extensible without making the most
likely immediate uses excessively complex.

The most common thing (or so I imagine) is to just use a single
yaml file in your home directory, so that's the default if no
"storage" is specified:

  ~/.list-filter/filters.yaml

There might be some need for more than one of these files (say, a
private one and a shared, or perhaps multiple ones for different
projects), so that's the next most simple case: an array reference
of multiple file paths.

If a file path is specified, the file extension is used to
determine the format.  Currently YAML is the only one supported,
but plugins can be added for other formats (csv, etc.).

In order to specify something like a DBI database connection, we
need a more complicated data-structure, so rather than simple
scalars, a hash reference can appear in the storage path.  With a
hash ref, the format of the storage is spelled out explicitly,
along with various other connection parameters that might be
needed.  This is discussed further in the following sections.

=head2 storage location hash references

The "storage" object attribute is designed to be very simple to
use in the most common cases (see the discussion above).

The next step up in complexity beyond a single yaml file, is to
use an array reference of storage locations that are searched in
given sequence: a scalar element of this array is presumed to be
a path to a data file.  If the element is a hash reference, it
can be used to specify something else, most commonly some sort of
database accessed via DBI.

An example of intermixing DBI storage with a yaml file:

    # Filters lookd up from a path of storage locations:
    # (1) yaml file (2) a DBI database connection
    my $yaml_file = "/tmp/filter_storage.yaml";
    my $lfs = List::Filter::Storage->new( {
           storage=> [
             $yaml_file,
             { format     => 'DBI',
               connect_to => $connect_to,
               owner      => $owner,
               password   => $password,
             },
          ] } );

Note the fields in the hash reference in the second position in
the storage array: The first is "format" (which obviously, is
defined as 'DBI' in the case of DBI access), and the remaining
three fields will no doubt seem familiar from L<DBI>.

In the case of the 'DBI' format, these three parameters are
passed through to the DBI module to create a database handle used
internally.  For example, postgresql, the "connect_to" would be:
"dbi:Pg:dbname=$dbname".

These fields can have a different meaning for different storage
formats, e.g. in the case of the 'MEM' (in-memory) format, the
"connect_to" parameter takes an href of hrefs containing
filter data in a format similar to what you see inside the yaml files.
See L<List::Filter::Storage::MEM>.

=head2 Storage formats

Storage formats (e.g. 'DBI', 'YAML', 'MEM', etc.) are defined
using a plug-in system, so that new types may be defined at a
later date, all of them are named with the form
List::Filter::Storage::<FORMAT>.

For the special case of DBI handles, it is possible to define a
database specific format handler that will over-ride the generic
L<List::Filter::Storage::DBI>.  These should be named following
the convention List::Filter::Storage::DBI::<db>, where <db>
should match an existing DBD::<db> driver (e.g. "Pg" for the
postgresql database: L<DBD::Pg>).

As mentioned above, in the case of the 'MEM' format, the
"connect_to" is used to point to a data structure. Other formats
are free to use these connection parameters as they like.  For
example, a 'LWP' format might be written some day where the
"connect_to" is a URL.

At present, documentation on how to write the code to handle a new
storage format is very limited.  It's suggested that you use the
existing format definition modules as examples:

L<List::Filter::Storage::DBI>
L<List::Filter::Storage::YAML>
L<List::Filter::Storage::CODE>
L<List::Filter::Storage::MEM>

=head1 SEE ALSO

L<List::Filter::Project>
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
