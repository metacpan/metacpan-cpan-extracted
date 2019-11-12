package LCC::Backend::Storable;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::Backend::Storable::ISA = qw(LCC::Backend);
$LCC::Backend::Storable::VERSION = '0.02';

# Use the modules that we always need

use Storable ();

# Default filename

my $default_file = 'LCC.storable';

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

# Initialize the newly obtained hash reference
# If we're storing in a gzipped file
#  Attempt to open the file through a gzip pipe
#  Add error if failed
#  Obtain the hash ref to the hash in the file
# Else (just an ordinary file)
#  Retrieve the hash from the file just like that

  my $hash;
  if ($source =~ m#\.gz$#) {
    my $handle = IO::File->new( "gzip --stdout $source |" );
    $self->_add_error( "Could not open file '$source' for reading: $!" )
     unless $handle;
    $hash = Storable::fd_retrieve( $handle );
  } else {
    $hash = Storable::retrieve( $source );
  }

# For all of the fields in the hash
#  Copy from the temp hash to the object
# Check whether UNS required full action

  foreach (('old',$self->_additional_fields)) {
    $self->{$_} = $hash->{$_};
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

# Initialize reference to a new hash
# For all of the keys that need to be saved
#  Copy the value to the temporary hash if there is one

  my $hash = {};
  foreach (('old',$self->_additional_fields)) {
    $hash->{$_} = $self->{$_} if exists $self->{$_};
  }

# Obtain the name of the source file
# If we're to store to a gzipped file
#  Open a pipe to write to a gzipped file
#  Add error if failed
#  Store the hash in the gzipped file
# Else (a normal file)
#  Store the file directly

  my $source = $self->{'source'} || $default_file;
  if ($source =~ m#\.gz$#) {
    my $handle = IO::File->new( "| gzip --best - >$source.new" );
    $self->_add_error( "Could not open file '$source.new' for writing: $!" )
     unless $handle;
    Storable::nstore_fd( $hash,$handle );
  } else {
    Storable::nstore( $hash,"$source.new" );
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

LCC::Backend::Storable - Backend using Storable for permanent storage

=head1 SYNOPSIS

 use LCC;
 $lcc = LCC->new( | {method => value} );

 $backend = $lcc->Backend( filename, | {method => value} ); # auto type
 $backend = $lcc->Backend( 'Storable', filename, | {method => value} );

=head1 DESCRIPTION

The Backend object of the Perl support for LCC that uses the Storable.pm
module for permanent storage.  Do not create directly, but through the Backend
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
