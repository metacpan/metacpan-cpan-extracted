package LCC::Backend::DBI::mysql;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::Backend::DBI::mysql::ISA = qw(LCC::Backend::DBI);
$LCC::Backend::DBI::mysql::VERSION = '0.02';

# Use the internal modules that we always need

use LCC::Backend::DBI ();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 instantiated object

sub create {

# Obtain the object
# Obtain the database handle and the table name

  my $self = shift;
  my ($dbh,$table) = $self->_dbh_table;

# Return the result of creation of the table

  return $dbh->do( <<EOD );
CREATE TABLE IF NOT EXISTS $table (
 id VARCHAR(255) NOT NULL,
 value VARCHAR(255) NOT NULL,
 UNIQUE id (id)
)
EOD
} #create

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
# Make sure table is empty if we did a complete update
# Create statement handle for updating
  
  my ($dbh,$table) = $self->_dbh_table;
  my $old = $self->{'old'};
  $dbh->do( "DELETE FROM $table" ) unless each( %{$old} );
  my $sth = $dbh->prepare( "REPLACE INTO $table (id,value) VALUES (?,?)");

# For all of the special keys
#  Save the key, prefixed by a null byte to mark as special, and its value

  foreach ($self->_additional_fields) {
    $sth->execute( "\0$_","$self->{$_}" ); # value in quotes needed!
  } # because the first value encountered determines quoting

# Create local copy of reference to new hash
# For all of the key => value pairs in the new hash
#  Update the database table
#  Save/Overwrite the new value in the old hash, expand list if necessary
# Forget about any changes made

  my $new = $self->{'new'};
  while (my ($id,$value) = each( %{$new} )) {
    $sth->execute( $id,$value );
    $old->{$id} = $value;
  }
  delete( $self->{'new'} );
} #update

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

# Internal subroutines

#------------------------------------------------------------------------

__END__

=head1 NAME

LCC::Backend::DBI::mysql - Backend using mysql for permanent storage

=head1 SYNOPSIS

 use LCC;
 $lcc = LCC->new( | {method => value} );

 $backend = $lcc->Backend( $dbh, | {method => value} ); # auto check for DBI
 $backend = $lcc->Backend( 'DBI', $dbh, | {method => value} ); # force DBI

=head1 DESCRIPTION

The Backend object of the Perl support for LCC that uses the DBI.pm module
with a mysql database engine.  Do not create directly, but through the Backend
method of the LCC object.

=head1 METHODS

See the methods available in the LCC::Backend module.

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
