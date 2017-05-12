package List::Filter::Storage::CODE;
#use base qw( List::Filter::StorageBase );
use base qw( List::Filter::Storage::MEM );

=head1 NAME

List::Filter::Storage::CODE - reads in standard libraries of filters from code

=head1 SYNOPSIS

   # This is a plugin, not intended for direct use.
   # See: List:Filter:Storage

   use List::Filter::Storage::CODE;

   # load all of transforms from standard library module location
   my $storage = List::Filter::Storage::CODE->new({
             type       => 'transform',
           });

   # load just the specified filter libraries
   # (Note: allows non-standard locations, and/or conserves memory)
   my $storage = List::Filter::Storage::CODE->new({
            connect_to => [ Some::Odd::Library::Module And::Another ],
            type       => 'filter',
          });

   # Retrieving a filter
   my $filter = $storage->lookup( ':omit' );

=head1 DESCRIPTION

The L<List::Filter> project ships with some standard filters defined
in perl code.  The "CODE" storage location format allows these filters
to be looked up by name using the standard storage interface.

This format may be used in two ways:

(1) by default it will slurp in all definitions found in all of
the modules found in the standard library location for the data
type (e.g. for "filter" it will look in
"List::Filter::Library::*" , for "transform" it will look in
"List::Filter::Transform::Library::*").

(2) It can be provided with a list of libary names, (which should
correspond to file names: <*>.pm), and it will only load the
filters from those particular files.

=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util qw( lock_keys unlock_keys );
use Module::List::Pluggable qw( list_modules_under import_modules );

our $VERSION = '0.01';
my $DEBUG = 0;

=item new

Instantiates a new List::Filter::Storage::CODE object.

With no arguments, the newly created profile will be loaded
with all filters from the appropriate installed code libraries.

If connect_to is defined as a list of library module names,
it will load only those library modules.

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

  my $lib_href = {};
  my $libraries_list = $args->{ connect_to };
  if ( $libraries_list ) {
     $lib_href = $self->load_given_libraries( $libraries_list );
  } else {
     $lib_href = $self->load_all_libraries;
  }

  $self->set_filter_data( $lib_href );

  lock_keys( %{ $self } );
  return $self;
}

=item lookup

See "lookup" in  L<List::Filter::Storage::MEM/lookup>

=cut

=item save

=cut

sub save {
  my $self = shift;

  $self->debug( "The 'save' method is not implemented for the 'CODE' storage format" );

  return 0;
}

=back

=head2 internally used methods

=over


=item define_library_location

From the type of the stored filters (e.g. 'filter', 'transform'),
determine the appropriate filter library location in the perl
module namespace.

This implements the convention:

List::Filter::<upper-case type>::Library, except that for
type 'filter' the class is just "List::Filter::Library::".

Gets "type" from the object data, unless supplied as an argument.

=cut

sub define_library_location {
  my $self = shift;
  my $type = shift || $self->type;
  my $library_location;
  if (not ($type) ) {
    croak "define_library_location in CODE.pm at line " .
      __LINE__ .
        ": needs a defined 'type' (e.g. 'filter', 'transform').";

  } elsif ($type eq 'filter') {
    $library_location = 'List::Filter::Library';
  } else {
    $library_location = 'List::Filter::' . ucfirst( $type ) . '::Library';
  }
  return $library_location;
}

=item load_all_libraries

Loads all available libraries of filters.

The type ('filter', 'transform', etc.) will come from the
object data, unless passed in as a second argument.

=cut

sub load_all_libraries {
  my $self = shift;
  my $type = shift || $self->type;
  my $library_location = $self->define_library_location( $type );
  my $library_names = list_modules_under( $library_location );
  my $library_href = $self->load_given_libraries( $library_names );

  return $library_href;
}



=item load_given_libraries

Loads all requested libraries of filters, from the tree of
libraries for the type ('filter', 'transform').  This type
must be passed in in the attributes hash reference.
The given list of names should be an aref of module names.

The type ('filter', 'transform', etc.) will come from the
object data, unless passed in as a second argument.

=cut

# Note, using this feature you can get it to look in nonstandard
# locations.

sub load_given_libraries {
  my $self          = shift;
  my $library_names = shift;
  my $type = shift || $self->type;

  my $filter_lib = {};
  foreach my $library (@{ $library_names }) {
    eval "require $library";
    if ($@) {
      carp "Problem with require $library:$@";
    }
    my $lib     = $library->new();
    my $new_lib = $lib->define_filters_href();
    merge_hash( $filter_lib, $new_lib );
  }

  return $filter_lib;
}


=back

=head2 proceedural routines

=over

=item merge_hash

This routine does hash addition, merging the key-value pairs of
one hash into another.

It takes two hash references, and adds the values of the second
into the first.

Inputs: (1) the summation href, (2) the href to be added into the first.

Return: a copy of the summation href, for convenience: don't assume
that the first argument isn't modified.

=cut

sub merge_hash {
  my $big_hash = shift;
  my $add_hash = shift;

  my @keys = (keys %{ $add_hash });
  @{ $big_hash }{ @keys }  = @{ $add_hash }{ @keys };

  return $big_hash;
}

=back

=head2 basic setters and getters

See L<List::Filter::StorageBase> for the basic accessors.

=cut

1;

=head1 SEE ALSO

L<List::Filter::Project>
L<List:Filter:Storage>
L<List::Filter>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
24 May 2007

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
