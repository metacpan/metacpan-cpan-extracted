package FileMetadata::Store::DBI;

our $VERSION = '0.1';

=head1 NAME

FileMetadata::Store::DBI

=cut

use DBI;
use DBI qw(:sql_types);
use strict;

=head1 DESCRIPTION

This modules implements a store for the FileMetadata framework using a
Perl DBI supported database. Such a database should be available and a
table must be designed to hold the required data. This module does not
implement any methods to retrieve the information from the database
- except for the has() method.

=head1 METHODS

=head2 new

See L<FileMetadata::Store>

The new method validates the config hash passed to it. It also connects to
the database and prepares a statement used for inserting values into
the database by store when all columns are available. This method will
call 'die' if any errors occur with the config hash or while performing
database operations.

The format for the config hash is as follows

  {

    database =&gt; 'DBI:mysql:test',

    username =&gt; 'user',

    password =&gt; 'pass',

    table =&gt; 'table',

    column =&gt; [{name =&gt; 'id_column',

                   property =&gt; 'ID',

                   type =&gt; 'SQL_STRING'},

                  {name =&gt; 'timestamp_column',

                   property =&gt; 'TIMESTAMP',

                   type =&gt; 'SQL_INTEGER'},

                  {name =&gt; 'FileMetadata::Miner::HTML::author',

                   default =&gt; 'Jules Verne'}]

  }

database, username and password are used to make a connection to the
SQL database. See L<DBI/"connect"> for the correct format for these
keys. The column key defines association of column names to property names.
The name key and the property key are required. Optionally the SQL type
of the value can be specified using 'type'. See L<DBI> for more information on 
possible values. The 'default' key specifies values to be used if no
information is available for the corresponding attribute.

This XML is parsed into the above hash by XML::Simple::XMLin($xml, 
keyattr =&gt; [])

=cut

sub new {

  my $self = {};
  bless $self, shift;
  my $config = shift;
  die "Config hash was not supplied" unless defined $config;

  # Construct columns array from config hash

  die "config/column not present"
    unless defined $config->{'column'};
  die "config/column is incorrect"
    unless (ref ($config->{'column'}) == 'HASH');
  die "config/table not present"
    unless defined $config->{'table'};

  my @columns = @{$config->{'column'}};

  $self->{'columns'} = $config->{'column'};
  $self->{'table'} = $config->{'table'};

  #
  # Construct database handle and the default prepared statement
  #

  $self->{'dbh'} = DBI->connect ($config->{'database'},
				 $config->{'username'},
				 $config->{'password'})
    or die DBI->errstr;

  my $sql = "INSERT into $config->{'table'} (";
  my $sql_vals = "";

  foreach (@columns) {

    die "config/column/name is needed" unless defined $_->{'name'};
    die "config/column/property is needed" unless defined $_->{'property'};

    $sql .= "$_->{'name'},";
    $sql_vals .= "?,";

    # Record coulmn names for ID and TIMESTAMP. Used by other methods

    if ($_->{'property'} eq "ID") {
      $self->{'index_col'} = $_->{'name'};
    } elsif ($_->{'property'} eq "TIMESTAMP") {
      $self->{'timestamp_col'} = $_->{'name'};
    }

  }

  die "config/column/name='ID' needs to be defined"
    unless defined $self->{'index_col'};

  die "config/column/name='TIMESTAMP' needs to be defined"
    unless defined $self->{'timestamp_col'};

  # Delete trailing commas

  $sql =~ s/\,$//;
  $sql_vals =~ s/\,$//;

  $sql .= ") VALUES (" . $sql_vals . ")";

  #
  # This prepared statement is used by the store() method when all columns
  # are available
  #

  $self->{'sth'} = $self->{'dbh'}->prepare ($sql) or die DBI->errstr;
  return $self;
}

=head2 store

See L<FileMetadata::Store/"store">

The store performs an INSERT into the database. Only properties specified in 
the config hash passed to the new() method are inserted.

=cut

sub store {

  my ($self, $meta) = @_;
  my @columns = @{$self->{'columns'}};
  my $use_prepared = 1; # USe to flag if any columns are missing
  my $i = 0; # Index while looping through the columns

  #
  # The following variables are used to construct a new SQL statemrnt
  # in case the prepared statement cannot be used.
  #

  my $sql = "INSERT into $self->{'table'} (";
  my $sql_vals = "";

  foreach (@columns) {

    $i++;

    my ($item, $value);
    $item = $_->{'property'};

    # See if the item is in the hash

    if (defined ($meta->{$item})) {
      $value = $meta->{$item};
    } else {
      $value = $_->{'default'};
    }

    if (defined $value) {
      $sql .= "$_->{'name'},";
      $sql_vals .= $self->{'dbh'}->quote($value) . ",";
      $self->{'sth'}->bind_param ($i, 
				  $value,
				  eval ($_->{'type'}));
    } else {
      $use_prepared = 0;
    }
  }

  # Remove any items with the same id
  $self->remove ($meta->{'ID'});

  # Do the insert

  if ($use_prepared) {
    $self->{'sth'}->execute() or die DBI->errstr;
  } else {
    $sql =~ s/\,$//;
    $sql_vals =~ s/\,$//;
    $sql .= ") VALUES (" . $sql_vals . ")";

    $self->{'dbh'}->do ($sql) or die DBI->errstr;
  }
}

=head2 remove

See L<FileMetadata::Store/"remove">

The store performs a DELETE on the database.

=cut

sub remove {

  my ($self, $id) = @_;
  $id = $self->{'dbh'}->quote($id), "\n";

  $self->{'dbh'}->do ("DELETE from $self->{'table'}"
    . " WHERE $self->{'index_col'}=$id")
    or die DBI->errstr;
}

=head2 clear

See L<FileMetadata::Store/"clear">

The store performs a DELETE on the database.

=cut

sub clear {

  my $self = shift;

  $self->{'dbh'}->do ("DELETE from $self->{'table'}")
    or die DBI->errstr;

}

=head2 has

See L<FileMetadata::Store/"has">

The has method queries the database for the row containing a 'ID' or equivalent
column value of the requested identifier. The column name for the 'ID' property
is identified from the config has passed to the constructor. The insertion
time of this row is identified from the timestamp column specified in the
config hash passed to the new() method.

=cut

sub has {

  my ($self, $id) = @_;

  $id = $self->{'dbh'}->quote($id);
  my $list_st = $self->{'dbh'}->prepare (
    "SELECT $self->{'timestamp_col'} "
    . "FROM $self->{'table'}"
    . " WHERE $self->{'index_col'}=$id");
  $list_st->execute();
  my $results = $list_st->fetchall_arrayref();

  # Return true only if one result will be returned
  if ($#{$results} == 0) {
    return @{@{$results}[0]}[0];
  } else {
    return undef;
  }
}

=head2 list

See L<FileMetadata::Store/"has">

The list method queries the database for the 'ID' or equivalent column of
all rows and returns an aray reference to a list of these values. The column 
name for the 'ID' property is identified from the config has passed to the 
new () method.

=cut

sub list {

  my $self = shift;
  my $list_st =
    $self->{'dbh'}->prepare (
      "SELECT $self->{'index_col'} FROM $self->{'table'}");
  $list_st->execute();
  my $results = $list_st->fetchall_arrayref();

  # Make a list from the two dimensional array references

  my @list = ();
  foreach (@{$results}) {
    push @list, $$_[0];
  }

  return \@list;
}

=head2 finish

This method releases the prepared statement and disconnects from the
database.

=cut

sub finish {

  my $self = shift;

  # Free up database resources explicitly
  $self->{'sth'}->finish();
  $self->{'dbh'}->disconnect();

}

1;

=head1 VERSION

0.1 - This is the first release

=head1 REQUIRES

DBI

=head1 AUTHOR

Midh Mulpuri midh@enjine.com

=head1 LICENSE

This software can be used under the terms of any Open Source Initiative
approved license. A list of these licenses are available at the OSI site -
http://www.opensource.org/licenses/

=cut
