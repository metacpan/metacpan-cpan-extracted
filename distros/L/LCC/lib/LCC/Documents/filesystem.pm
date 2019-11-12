package LCC::Documents::filesystem;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::Documents::filesystem::ISA = qw(LCC::Documents);
$LCC::Documents::filesystem::VERSION = '0.01';

# Use the external modules that we need

use File::Find ();

# Attempt to load Digest::MD5 module if not already loaded
# Initialize MD5 object

eval 'use Digest::MD5 ()' unless defined( $Digest::MD5::VERSION );
my $md5 = defined( $Digest::MD5::VERSION ) ? Digest::MD5->new : '';

# Create the default mimetype conversion

my %default_mimetype = (
 doc	=> 'application/msword',
 htm	=> 'text/html',
 html	=> 'text/html',
 pdf	=> 'application/pdf',
 php	=> 'text/html',
 phtml	=> 'text/html',
 shtml	=> 'text/html',
 text	=> 'text/plain',
 txt	=> 'text/plain',
 xls	=> 'application/excel',
 xml	=> 'text/xml',
 xsl	=> 'text/xml',
);

# Create the default wanted files (of which we know the mimetype)

my $default_wanted = join( '|',sort keys %default_mimetype );

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 class of object
#      2 instantiated LCC object
#      3 directory specification (default: current)
#      4 method => value pairs to be executed
# OUT: 1 instantiated LCC::Documents::xxx object

sub _new {

# Obtain the class
# Obtain the LCC object
# Obtain the source (a directory)
# Add trailing slash if there is none yet

  my $class = shift;
  my $LCC = shift;
  my $source = shift || '.';
  $source .= '/' unless $source =~ m#/$#;

# Add error if the source is not a directory
# Add error if the directory can not be read

  $LCC->_add_error( "'$source' is not a directory" ) unless -d $source;
  $LCC->_add_error( "'$source' cannot be read" ) unless -r _;

# Create the object in the right way
# Save the source specification
# Obtain the wanted subroutine reference, default if we don't have one already

  my $self = $class->SUPER::_new( $LCC,@_ );
  $self->{'source'} = $source;
  my $wanted = $self->{'wanted'} || \&_default_wanted;

# Initialize the list of files
# Initialize the reference to the options hash
# Set the File::Find "wanted" subroutine reference
# Look for all of the files from the indicated directory

  my @list;
  my $options = $self->{'file_find_options'} || {};
  $options->{'wanted'} = sub {
   push( @list,$File::Find::name ) if $wanted->( $File::Find::name );
  };
  File::Find::find( $options,$source );

# Save the list in the object
# Return the object

  $self->{'_list'} = \@list;
  return $self;
} #_new

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 (optional) new reference to hash with File::Find options
# OUT: 1 new/current reference to hash with File::Find options

sub file_find_options {
 shift->_variable( 'file_find_options',@_ )
} #file_find_options

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 (optional) new subroutine reference for mimetype routine
# OUT: 1 current/old subroutine reference for mimetype routine

sub mimetype { shift->_variable( 'mimetype',@_ ) } #mimetype

#------------------------------------------------------------------------

sub next_document {

# Obtain the object
# Obtain the index
# Return now if index is out of range

  my $self = shift;
  my $index = $self->{'_list_index'} || 0;
  return unless exists $self->{'_list'}->[$index];

# Obtain the filename, incrementing index on the fly
# Obtain the size and modification time of the file
# Convert modification time to timestamp

  my $filename = $self->{'_list'}->[$self->{'_list_index'}++];
  my ($size,$mtime) = (stat($filename))[7,9];
  $mtime = _timestamp( $mtime );

# Initialize the MD5 digest of the file
# If we have support for MD5
#  If successful in opening the file
#   Read the file and calculate the digest

  my $hexdigest = '';
  if ($md5) {
    if (my $handle = IO::File->new( $filename,'<' )) {
      $hexdigest = $md5->addfile( $handle )->hexdigest;
    }
  }

# Obtain the mimetype
# Obtain the subtype
# Adapt the filename to make it an id
# Return what is needed

  my $mimetype = &{$self->{'mimetype'} || \&_default_mimetype}( $filename );
  my $subtype = &{$self->{'subtype'} || \&_default_subtype}( $filename );
  $filename =~ s#^$self->{'source'}##;
  return ($filename,$mtime,$size,$hexdigest,$mimetype,$subtype);
} #next_document

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 servername to be used (default: `hostname`)

sub server {

# Obtain the object
# Obtain the hostname, make sure it's clean

  my $self = shift;
  chomp( my $server = shift || `hostname` );

# Set default browse_url subroutine
# Set default conceptual_url subroutine
# Set fetch_url subroutine

  $self->browse_url( $self->_browse_url );
  $self->conceptual_url( $self->_conceptual_url );
  $self->fetch_url( sub {"http://$server/$_[0]"} );
} #server

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 (optional) new subroutine reference for subtype routine
# OUT: 1 current/old subroutine reference for subtype routine

sub subtype { shift->_variable( 'subtype',@_ ) } #subtype

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 (optional) new subroutine reference for wanted routine
# OUT: 1 current/old subroutine reference for wanted routine

sub wanted { shift->_variable( 'wanted',@_ ) } #wanted

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

# Internal subroutines

#------------------------------------------------------------------------

#  IN: 1 filename
# OUT: 1 mimetype to be associated with name or empty string

sub _default_mimetype {

# Obtain the extension
# Check for lowercase version's mimetype and return that if possible

  shift =~ m#\.(\w+)$#;
  $default_mimetype{lc($1)} || '';
} #_default_mimetype

#------------------------------------------------------------------------

#  IN: 1 filename
# OUT: 1 subtype associated with filename

sub _default_subtype {''} #_default_subtype

#------------------------------------------------------------------------

#  IN: 1 filename
# OUT: 1 flag: whether filename should be included

sub _default_wanted { $_[0] =~ m#\.(?:$default_wanted)$#io } #_default_wanted

#------------------------------------------------------------------------

sub _timestamp {

# Obtain constituent parts of time value
# Convert to timestamp and return

  my ($sec,$min,$hour,$mday,$mon,$year) = gmtime( shift );
  sprintf( '%04d%02d%02d%02d%02d%02d',1900+$year,1+$mon,$mday,$hour,$min,$sec );
} #_timestamp

#------------------------------------------------------------------------

__END__

=head1 NAME

LCC::Documents::filesystem - Documents stored on a filesystem

=head1 SYNOPSIS

 use LCC;
 $lcc = LCC->new( | {method => value} );
 $lcc->Documents( '/dir', | {method => value} ); # figures out it's filesystem
 $lcc->Documents( 'filesystem','/dir', | {method => value} ); # force filesystem

=head1 DESCRIPTION

The Documents object of the Perl support for LCC that should be used when
documents are stored as files on a filesystem.  Do not create directly, but
through the Documents method of the LCC object.

Uses the File::Find module to create a list of files.

=head1 METHODS

Apart from the methods documented here, see the methods available in the
LCC::Documents module.

=head2 file_find_options

 $lcc->Documents( '/dir', {file_find_options => {bydepth => 1}} );

Specify (and/or return) the reference to the hash that is passed as the
first parameter to File::Find::find.  For more information, check the
documentation of the File::Find module.

=head2 mimetype

 $lcc->Documents( '/dir', {mimetype => \&mymimetype} );

Specify (and/or return) the reference of the subroutine that will be called
to find out the MIME-type of each file that is being checked.  Is expected to
accept a single parameter, the absolute filename of the file being checked.
Is expected to return the MIME-type to be associated with the file, or undef.

A default "mimetype" routine will be assumed that will return the correct
MIME-type for all of the filetypes that are accepted by the default L<wanted>
subroutine.

=head2 subtype

 $lcc->Documents( '/dir', {subtype => \&mysubtype} );

Specify (and/or return) the reference of the subroutine that will be called
to find out the subtype of each file that is being checked.  Is expected to
accept a single parameter, the absolute filename of the file being checked.
Is expected to return the subtype to be associated with the file, or undef.

A default "subtype" routine will be assumed that will always return an empty
string.

=head2 wanted

 $lcc->Documents( '/dir', {wanted => \&mywanted} );

Specify (and/or return) the reference of the subroutine that will be called
for B<each> file encountered.  Is expected to accept a single parameter, the
absolute filename of the file being checked.  Is also expected to return a
true value if the file should be included in the check.

A default "wanted" subroutine will be assumed if this method is never called.
This subroutine checks whether the file as any of the following extensions:

 .doc
 .htm
 .html
 .pdf
 .php
 .phtml
 .shtml
 .text
 .txt
 .xls
 .xml
 .xsl

and returns true (to indicate the file should be included in the check) if
the extension matches.

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
