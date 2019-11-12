package LCC::Backend::textfile;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::Backend::textfile::ISA = qw(LCC::Backend);
$LCC::Backend::textfile::VERSION = '0.02';

# Default filename

my $default_file = 'LCC.textfile';

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 (optional) flag, specifying whether to force partial update

sub partial {

# Obtain the object
# Obtain the source filename
# Return now if the file does not exist

  my $self = shift;
  my $source = $self->{'source'} || $default_file;
  return $self unless -e $source;

# Initialize the handle
# If we're reading from a gzipped file
#  Attempt to open the file through a gzip pipe
# Else (just an ordinary file)
#  Attempt to open file for reading normally
# Add error if failed

  my $handle;
  if ($source =~ m#\.gz$#) {
    $handle = IO::File->new( "gzip --stdout $source |" );
  } else {
    $handle = IO::File->new( $source,'<' );
  }
  $self->_add_error( "Could not open file '$source' for reading: $!" )
   unless $handle;

# Initialize the reference to the old hash
# While there are lines to be read
#  Split on the first "real" null byte
#  Add the id to the hash with its value
# Check whether UNS required full action

  my $old = $self->{'old'} ||= {};
  while (<$handle>) {
    my ($key,$list) = m#^(.[^\0]+)\0(.*)$#;
    $key =~ m#^\0# ? ($self->{$key} = $list) : ($old->{$key} = $list);
  }
  $self->_check_uns_complete unless shift || '';
} #partial

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 instantiated object

sub update {

# Obtain the object
# Add error if unclear what kind of update was done
# Return now if there is nothing to do

  my $self = shift;
  $self->_add_error( "Unclear whether 'complete' or 'partial' update" )
   unless exists( $self->{'old'} );
  return unless exists $self->{'new'};

# Create local copy of reference to old hash
# Create local copy of reference to new hash
# For all of the key => value pairs in the new hash
#  Save/Overwrite the new value in the old hash

  my $old = $self->{'old'};
  my $new = $self->{'new'};
  while (my ($key,$value) = each( %{$new} )) {
    $old->{$key} = $value;
  }

# Initialize the handle
# Obtain the name of the source file
# If we're to store to a gzipped file
#  Open a pipe to write to a gzipped file
# Else (a normal file)
#  Create ordinary file to write to
# Add error if failed

  my $handle;
  my $source = $self->{'source'} || $default_file;
  if ($source =~ m#\.gz$#) {
    $handle = IO::File->new( "| gzip --best - >$source.new" );
  } else {
    $handle = IO::File->new( "$source.new",'>' );
  }
  $self->_add_error( "Could not open file '$source.new' for writing: $!" )
   unless $handle;

# For all of the special fields that need to be saved
#  Write a line to the file

  foreach ($self->_additional_fields) {
    print $handle "\0$_\0$self->{$_}\n" if exists $self->{$_};
  }

# While there are keys to be handled from the now old hash
#  Write a line to the file

  while (my ($id,$value) = each %{$old}) {
    print $handle "$id\0$value\n";
  }

# Forget about any changes made
# Move the current file to "old" file
# Move the "new" file to current file

  delete( $self->{'new'} );
  rename( $source,"$source.old" );
  rename( "$source.new",$source );
} #update

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

__END__

=head1 NAME

LCC::Backend::textfile - Backend using a textfile for permanent storage

=head1 SYNOPSIS

 use LCC;
 $lcc = LCC->new( | {method => value} );

 $backend = $lcc->Backend( | {method => value} ); # auto textfile and name
 $backend = $lcc->Backend( filename, | {method => value} ); # auto textfile
 $backend = $lcc->Backend( 'textfile', filename, | {method => value} );

=head1 DESCRIPTION

The Backend object of the Perl support for LCC that uses flat textfiles for
permanent storage.  Do not create directly, but through the Backend method of
the LCC object.

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
