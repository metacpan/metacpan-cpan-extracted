package List::Filter::Storage::DBI;
use base qw( List::Filter::StorageBase );

=head1 NAME

List::Filter::Storage::DBI - filter storage via DBI

=head1 SYNOPSIS

   # This is a plugin, not intended for direct use.
   # See: List:Filter:Storage

   use List::Filter::Storage::DBI;
   my $lfps_dbi = List::Filter::Storage::DBI->new(
         type       => 'filter',
         connect_to => $connect_to,
         owner      => $owner,
         password   => $password,
   );

=head1 DESCRIPTION

This is a general, database-neutral (or so I hope) storage plugin
that should allow for reading and writing List::Filter filters
from any database with a DBI driver.

Note that in the event that database-specific code is needed,
A specific plugin that inherits from this one can be written:
the List::Filter system should find it automatically, if it's
named in the standard way (ala DBD::*).  E.g. a postgresql
driver would be

  List::Filter::Storage::DBI::Pg

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

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes.

With no arguments, the newly created filter will be empty.

=cut

# Note: new is inherited from Class::Base.
# It calls the following "init" routine automatically.

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

  # Ensure that filter table exists in the database
  $self->create_filter_table;

  lock_keys( %{ $self } );
  return $self;
}


=item create_filter_table

Creates the standard storage tables for this object's type.

=cut

sub create_filter_table {
  my $self = shift;
  my $table = $self->type;

  my $sql =<<"ENDSKULL";
CREATE TABLE $table (
       id             INTEGER PRIMARY KEY,
       name           TEXT UNIQUE,
       terms          TEXT,  --  more portable than "BLOB"?
       method         TEXT,
       description    TEXT,
       modifiers      TEXT
);
ENDSKULL

  $sql .= 'CREATE INDEX idx_' . $table . "_name ON $table (name)\n";

  $self->create_table( $sql );

  return $self;
}


=item create_table

Takes a block of sql as an argument, which is expected to contain a
CREATE TABLE statement.  Tries to run the sql, but does not object if
the table already exists already.  However, this method "croaks" on
any other error.

Note: It tries to create the table, and traps the error if it
exists already.  This is more portable -- to my knowledge --
than trying to get a listing of existing tables.

=cut

sub create_table {
  my $self       = shift;
  my $create_sql = shift;

  $self->debug("sql: \n$create_sql");

  my $dbh = $self->dbh;


  { # switch off RaiseError setting temporarily
    local $dbh->{RaiseError};
    local $dbh->{PrintError};

    # attempt to create table, ignoring error if it exists already.
    eval {
      $dbh->do( $create_sql )
    };
    if ( ($@) or (my $err = $dbh->err) ) {  # note, with RaiseError off, "err" is tripped, but not $@
      my $errstr = $dbh->errstr;

      # Expected values:
      # err code: 1
      # errstr:   table filter already exists(1)  [...]

      my $mess = "create_filter_table: err code: $err  errstr: $errstr";

      # ignore only the expected error message
      if ( not( (
                 ( $err eq 1 ) &&
                 ( $errstr =~ m{ table \s+ (.*?) \s+ already \s+ exists }x )
                )
              )          ) {
        croak "Error: $mess";

        $self->debug( "Warning: $mess" );
      }
    }
  }
  return $self;
}

=item init_dbh

Initializes database connection.

=cut

sub init_dbh {
  my $self = shift;

  my $connect_to   = $self->connect_to;
  my $owner        = $self->owner;
  my $password     = $self->password;
  my $attributes    = $self->attributes;

  my $dbh = DBI->connect($connect_to, $owner, $password, $attributes)
    or croak "Database connection failed: $connect_to";

  $self->set_dbh( $dbh );
  return $dbh;
}

=head2 main methods

=over

=item lookup

=cut

sub lookup {
  my $self = shift;
  my $name = shift;

  my $table = $self->type;
  my $sql = "SELECT terms, method, description, modifiers FROM $table WHERE name = ?";
  my $dbh = $self->dbh;
  my $sth = $dbh->prepare($sql);
  $sth->execute( $name );
  my $row = $sth->fetchrow_arrayref;

  my $terms_serialized = $row->[0];
  my $method      = $row->[1];
  my $description = $row->[2];
  my $modifiers   = $row->[3];

  # Unpacking aref serialized with Data::Dumper->Dump
  my $terms;
  eval $terms_serialized;

  # create a filter object
  my $filter_class = $self->define_filter_class;
  my $filter = $filter_class->new(
     { name         => $name,
       terms        => $terms,
       method       => $method,
       description  => $description,
       modifiers    => $modifiers,
     } );

   return $filter;
}

=item save

Saves the given filter object to the database.

Refuses to save filters named with a leading underscore.

Returns the filter on success, otherwise undef.

=cut

sub save {
  my $self    = shift;
  my $filter  = shift;

  my $dbh = $self->dbh;

  my $name         = $filter->name;

  if ($name =~ m{^_}x) {
    return;
  } else {
    $self->debug("Refusing to save filter named with leading underscore: $name");
  }

  my $method       = $filter->method;
  my $description  = $filter->description;
  my $modifiers    = $filter->modifiers;
  my $terms        = $filter->terms;

  my $terms_serialized
    = Data::Dumper->Dump( [$terms], ['terms'] );

  my $table = $self->type;

  my $sql =
    "INSERT INTO $table (name, terms, method, description, modifiers)
     VALUES (?, ?, ?, ?, ?)";

  my $sth = $dbh->prepare( $sql );
  $sth->execute( $name,
                 $terms_serialized,
                 $method,
                 $description,
                 $modifiers );

  if ($dbh->err) {
    my $errstr = $dbh->errstr;
    carp "save: problem on INSERT: $errstr "
  }

  return $filter;
}


=item list_filters

Returns a list of all avaliable named filters.

=cut

sub list_filters {
  my $self = shift;

  my $table = $self->type;
  my $sql = "SELECT name FROM $table";
  my $dbh = $self->dbh;
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my $row = $sth->fetchrow_arrayref;

  return $row;
}



=back

=head2 special accessors (access the "extra" namespace)

=over

=item dbh

Getter for object attribute dbh

When called for the first time, initiates database connection.

=cut

sub dbh {
  my $self = shift;
  my $dbh = $self->extra->{ dbh };

  if ( not( $dbh ) ) {
    $dbh = $self->init_dbh;
  }

  return $dbh;
}

=item set_dbh

Setter for object attribute set_dbh

=cut

sub set_dbh {
  my $self = shift;
  my $dbh = shift;
  $self->extra->{ dbh } = $dbh;
  return $dbh;
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

=head2 Design Notes

This single table schema isn't an efficient use of an RDMS,
but the needs here are relatively simple, and this should
be fairly portable.

The primary simplification used here is to serialize the array
of terms and store it in a single text field.

Data::Dumper has been used for serialization (in preference to
Storable) to improve the readability of the database.

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
