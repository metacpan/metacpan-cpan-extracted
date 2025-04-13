package LCC::Documents::DBI;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::Documents::DBI::ISA = qw(LCC::Documents);
$LCC::Documents::DBI::VERSION = '0.03';

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 class of object
#      2 instantiated LCC object
#      3 DBI statement handle
#      4 method => value pairs to be executed
# OUT: 1 instantiated LCC::Documents::xxx object

sub _new {

# Obtain the class
# Obtain the LCC object
# Obtain the source (a ref to a database handle, table name list)

  my $class = shift;
  my $lcc = shift;
  my $source = shift;

# Add error if the source is not a statement handle

  $lcc->_add_error( "$source is not a DBI statement handle" )
   unless ref($source) eq 'DBI::st';

# Create the object in the right way
# Save the source specification
# Return the object

  my $self = $class->SUPER::_new( $lcc,@_ );
  $self->{'source'} = $source;
  return $self;
} #_new

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 instantiated object
# OUT: 1 id of the next document
#      2 mtime of the next document
#      3 (optional) length of the next document
#      4 (optional) md5 of the next document
#      5 (optional) mimetype of the next document
#      6 (optional) subtype of the next document

sub next_document { shift->{'source'}->fetchrow_array } #next_document

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

__END__

=head1 NAME

LCC::Documents::DBI - Document information stored in a database

=head1 SYNOPSIS

 use DBI;
 my $dbh = DBI->connect( ... );
 my $sth = $dbh->prepare( "SELECT id,mtime... FROM table" );
 $sth->execute;

 use LCC;
 $lcc = LCC->new( | {method => value} );

 $lcc->Documents( $sth, | {method => value} ); # figures out it's DBI
 $lcc->Documents( 'DBI', $sth, | {method => value} ); # forces DBI

=head1 DESCRIPTION

The Documents object of the Perl support for LCC that should be used when
document update information exists as a DBI statement handle.  Do not create
directly, but through the Documents method of the LCC object.

The statement handle is supposed to contain the following elements:

 1 id of a document
 2 mtime of that document
 3 (optional) length of that document
 4 (optional) md5 of that document
 5 (optional) mimetype of that document
 6 (optional) subtype of that document

=head1 METHODS

There are no methods specific to this module.  Also see the methods available
in the LCC::Documents module.

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
