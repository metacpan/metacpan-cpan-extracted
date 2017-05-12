package List::Filter::StorageBase;
use base qw( Class::Base );


=head1 NAME

StorageBase - base class for filter storage plugins

=head1 SYNOPSIS

   package List::Filter::Storage::NewFormat;
   use base qw( List::Filter::StorageBase );

   sub init {
   }

   sub lookup {
     # ...
   }

   sub save {
     # ...
   }

   sub list_filters {
     # ...
   }


   1;


=head1 DESCRIPTION

This is module is purely an interface, which the storage plugins
are intended to inherit from.  The documentation of this module
is thus oriented toward people interested in writing new storage plugins,
see the existing plugins for documentation on how to use them.

=head1 OBJECT DATA

The main fields inside the object:

=over

=item connect_to

In the case of DBI, this will be the database connection string,
indicating the DBD driver and the database name.

=item owner

A user name, when required to make the connection.

=item password

A password, to go with the user name.

=item attributes

A hash reference of additional attributes to be used by the
storage back-end in any way that seems appropriate.

In the case of DBI, this hash ref might contain something like this:

   { RaiseError => 1, AutoCommit => 1 }

(Though there's no particular point in manipulating AutoCommit with
storage needs this simple).

=item type

The type of the filters being stored (e.g. 'filter', 'transform').
Not to be confused with the data storage format (e.g 'YAML', 'DBI')

=item extra

A catch-all hash reference intended to be used primarily for
internal storage purposes by the subclasses, e.g. in the case of
YAML, this will contain a reference to the contents of an entire
YAML file that has been slurped into memory.  Writing additional
accessors for the data inside of "extra" is strongly advised, to
make it easier to modifiy the internal structure at a later date.

=back

=head1 METHODS

There are two main methods that need to be implemented:

=over

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util qw( lock_keys unlock_keys );

our $VERSION = '0.01';
my $DEBUG = 0;

=item new

Instantiates a new object.

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

Optionally, a plugin may run additional initialization code inside
of an init method that overrides this stub.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  if ($DEBUG) {
    $self->debugging(1);
  }

  # define new attributes
  my $attributes = {
              connect_to     => $args->{ connect_to },
              owner          => $args->{ owner },
              password       => $args->{ password },
              attributes     => $args->{ attributes },
              type           => $args->{ type },       # type of filters to be stored
              extra          => {},        # internal storage, etc. keys not locked.
           };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  lock_keys( %{ $self } );
  return $self;
}



=item define_filter_class

From the type of the stored filters (e.g. 'filter', 'transform'),
determine the appropriate class.

This implements the convention:
List::Filter::<type>, except that for type 'filter' the class is
just "List::Filter".

=cut

sub define_filter_class {
  my $self = shift;
  my $type = $self->type;
  my $class;
  if (not ($type) ) {
    croak "define_filter_class in StorageBase at line " . __LINE__ . ": needs a defined 'type' (e.g. 'filter', 'transform').";
  } elsif ($type eq 'filter') {
    $class = 'List::Filter';
  } else {
    $class = 'List::Filter::' . ucfirst( $type );
  }
  return $class;
}



=back

=head2 main methods (stubs)

=over

=item lookup

Given a name, returns the first filter found with a matching name.

=cut

sub lookup {
  my $self = shift;
  my $name = shift;
  my $class = ref $self;
  carp "The lookup method has not been implemented for this class: $class.";
  return undef;
}


=item save

Given a filter saves it to the storage location indicated by the
"write_storage" setting of the List::Filter::Storage
object, using the name indicated by the "name" field inside of
the filter.

=cut

sub save {
  my $self    = shift;
  my $filter  = shift;
  my $class = ref $self;
  carp "The save method has not been implemented for this class: $class";
  return undef;
}



=item list_filters

Returns a list of all available filters.

=cut

sub list_filters {
  my $self = shift;
  carp "The list_filters method has not been implemented for this class.";
  return undef;
}



=back

=head2 basic accessors

=over

=item connect_to

Getter for object attribute connect_to

=cut

sub connect_to {
  my $self = shift;
  my $connect_to = $self->{ connect_to };
  return $connect_to;
}


=item owner

Getter for object attribute owner

=cut

sub owner {
  my $self = shift;
  my $owner = $self->{ owner };
  return $owner;
}

=item set_owner

Setter for object attribute set_owner

=cut

sub set_owner {
  my $self = shift;
  my $owner = shift;
  $self->{ owner } = $owner;
  return $owner;
}


=item password

Getter for object attribute password

=cut

sub password {
  my $self = shift;
  my $password = $self->{ password };
  return $password;
}

=item set_password

Setter for object attribute set_password

=cut

sub set_password {
  my $self = shift;
  my $password = shift;
  $self->{ password } = $password;
  return $password;
}

=item set_connect_to

Setter for object attribute set_connect_to

=cut

sub set_connect_to {
  my $self = shift;
  my $connect_to = shift;
  $self->{ connect_to } = $connect_to;
  return $connect_to;
}



=item attributes

Getter for object attribute attributes

=cut

sub attributes {
  my $self = shift;
  my $attributes = $self->{ attributes };
  return $attributes;
}

=item set_attributes

Setter for object attribute set_attributes

=cut

sub set_attributes {
  my $self = shift;
  my $attributes = shift;
  $self->{ attributes } = $attributes;
  return $attributes;
}

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

=item extra

Getter for object attribute extra

=cut

sub extra {
  my $self = shift;
  my $extra = $self->{ extra };
  return $extra;
}

=item set_extra

Setter for object attribute set_extra

=cut

sub set_extra {
  my $self = shift;
  my $extra = shift;
  $self->{ extra } = $extra;
  return $extra;
}






1;


=back

=head1 SEE ALSO

L<List::Filter>
L<List::Filter::Storage::YAML>
L<List::Filter::Storage::DBI>

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
