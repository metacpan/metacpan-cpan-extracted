package LCC::Backend::DBI;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::Backend::DBI::ISA = qw(LCC::Backend);
$LCC::Backend::DBI::VERSION = '0.03';

# Make sure we have the external modules that we always need

use DBI ();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 class of object
#      2 instantiated LCC object
#      3 source specification
#      4 method => value pairs to be executed
# OUT: 1 instantiated LCC::Backend::xxx object

sub _new {

# Obtain the class
# Obtain the LCC object
# Obtain the source (a ref to a database handle, table name list)

  my $class = shift;
  my $lcc = shift;
  my $source = shift;

# Obtain the database handle
# Obtain the driver name
# Add error if driver not found

  my ($dbh) = __PACKAGE__->_dbh_table( $source );
  my $driver = $dbh->{'Driver'}->{'Name'} || '';
  $lcc->_add_error( "Unable to determine which DBI driver to use" )
   unless $driver;

# Create the module name
# Make sure that we have the right driver module if not loaded yet
# Reset to original class if there is no specific support for this driver
# Create the object, blessed with the database driver specific class

  my $module = $class.'::'.$driver;
  eval "use $module" unless defined( ${$module.'::VERSION'} );
  $module = $class unless defined( ${$module.'::VERSION'} );
  my $self = $module->SUPER::_new( $lcc,@_ );

# Save the source specification
# Make sure that the table exists
# Return the object

  $self->{'source'} = $source;
  $self->create;
  return $self;
} #_new

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 instantiated object

sub create {

# Obtain the object
# Obtain the database handle and the table name
# Create of the table, wrapped in eval to catch errors

  my $self = shift;
  my ($dbh,$table) = $self->_dbh_table;
  eval {$dbh->do( "CREATE TABLE $table (id CHAR(255), value CHAR(255))" )};
} #create

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 (optional) flag, specifying whether to force partial update

sub partial {

# Obtain the object
# Obtain database handle and table name
# Perform the selection

  my $self = shift;
  my ($dbh,$table) = $self->_dbh_table;
  my $sth = $dbh->prepare( "SELECT id,value FROM $table" );
  $sth->execute;

# Create the reference to the hash to be filled
# While there are records to be fetched
#  Save the value in the hash, special keys start with null byte
# Check whether UNS required full action

  my $old = $self->{'old'} = {};
  while (my ($key,$list) = $sth->fetchrow_array) {
    $key =~ s#^\0## ? $self->{$key} = $list : $old->{$key} = $list;
  }
  $self->_check_uns_complete unless shift || '';
} #partial

#------------------------------------------------------------------------

#  IN: 1 instantiated object

sub update {

# Obtain the object
# Add error if we haven't got anything to compare with
# Return now if there is nothing to do

  my $self = shift;
  $self->_add_error( "Unclear whether 'complete' or 'partial' update" )
   unless exists( $self->{'old'} );
  return unless exists $self->{'new'};

# Obtain the database handle and table name
# Create local copy of reference to old hash
# Initialize the statement handle for removing entries

  my ($dbh,$table) = $self->_dbh_table;
  my $old = $self->{'old'} || {};
  my $delete;

# If we are doing a partial update
#  Remove the special fields
#  Set the statement handle for removing
# Else (we're starting with a clean slate)
#  Make sure table is empty

  if (keys %{$old} ) {
    $dbh->do( "DELETE FROM $table WHERE id LIKE '\0%'" );
    $delete = $dbh->prepare( "DELETE FROM $table WHERE id=?" );
  } else {
    $dbh->do( "DELETE FROM $table" );
  }

# Create statement handle for updating
# For all of the special keys
#  Save the key, prefixed by a null byte to mark as special, and its value

  my $insert = $dbh->prepare( "INSERT INTO $table (id,value) VALUES (?,?)");
  foreach ($self->_additional_fields) {
    $insert->execute( "\0$_","$self->{$_}" ); # value in quotes needed!
  } # because the first value encountered determines quoting

# Create local copy of reference to new hash
# For all of the key => value pairs in the new hash
#  Remove the entry if we need to remove
#  Add the entry
#  Save/Overwrite the new value in the old hash, expand list if necessary
# Forget about any changes made

  my $new = $self->{'new'};
  while (my ($id,$value) = each( %{$new} )) {
    $delete->execute( $id ) if $delete;
    $insert->execute( $id,$value );
    $old->{$id} = $value;
  }
  delete( $self->{'new'} );
} #update

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

# Internal subroutines

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 the source specification (default: of the object itself)
# OUT: 1 database handle
#      2 table name to be used

sub _dbh_table {

# Obtain the object
# Obtain the source
# Return the database handle and table name

  my $self = shift;
  my $source = shift || $self->{'source'};
  return ref($source) eq 'ARRAY' ? @{$source} : ($source,'LCC') ;
} #_dbh_table 

#------------------------------------------------------------------------

__END__

=head1 NAME

LCC::Backend::DBI - Backend using DBI for permanent storage

=head1 SYNOPSIS

 use LCC;
 $lcc = LCC->new( | {method => value} );

 $backend = $lcc->Backend( $dbh, | {method => value} ); # auto check for DBI
 $backend = $lcc->Backend( 'DBI', $dbh, | {method => value} ); # force DBI

=head1 DESCRIPTION

The Backend object of the Perl support for LCC that uses the DBI.pm, and
thus transparently supports any database engine that is supported by the DBI.pm
module, for permanent storage.  Do not create directly, but through the Backend
method of the LCC object.

=head1 METHODS

There are a few specific methods to this modules.  Also see the methods
available in the LCC::Backend module.

=head2 create

 $backend->create;

Create the table that is needed to store the status.  Should do nothing if the
table already exists.  Is called automatically when the backend object is
created.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://lococa.sourceforge.net, the LCC.pm and the other LCC::xxx modules.

=cut
