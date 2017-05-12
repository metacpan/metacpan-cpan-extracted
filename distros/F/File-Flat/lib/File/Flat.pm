package File::Flat;

# The File::Flat is a static class that provides a unified interface
# to the filesystem in a way such that directories are abstracted away.

# This should work on non-Unix platforms, but there may be some
# minor remaining bugs.

use 5.005;
use strict;
use Cwd        ();
use File::Spec ();
use IO::File   ();
use prefork    'File::Temp';
use prefork    'File::Copy';
use prefork    'File::Copy::Recursive';
use prefork    'File::Remove';

use vars qw{$VERSION $errstr %modes $AUTO_PRUNE};
BEGIN {
	$VERSION = '1.04';

	# The main error string
	$errstr  = '';

	# Create a map of all file open modes we support,
	# and which ones will create a new file if needed.
	%modes = ( 
		'<'  => 0, 'r'  => 0, # Read
		'+<' => 1, 'r+' => 1, # ReadWrite
		'>'  => 1, 'w'  => 1, # Write
		'+>' => 1, 'w+' => 1, # ReadWrite
		'>>' => 1, 'a'  => 1  # Append
		);

	$AUTO_PRUNE = '';
}





#####################################################################
# Examining the file system

# Does a filesystem entity exist.
sub exists { defined $_[1] and -e $_[1] }

# Is a filesystem object a file.
sub isaFile { defined $_[1] and -f $_[1] }

# Is a filesystem object a directory.
sub isaDirectory { defined $_[1] and -d $_[1] }

# Do we have permission to read a filesystem object.
sub canRead { defined $_[1] and -e $_[1] and -r _ }

# Do we have permission to write to a filesystem object.
# If it doesn't exist, can we create it.
sub canWrite {
	# If it already exists, check normally
	return -w $_[1] if -e $_[1];

	# Can we create it
	my $Object = File::Flat::Object->new( $_[1] ) or return undef;
	$Object->_canCreate;
}

# Can we both read and write to a filesystem object
sub canReadWrite { defined $_[1] and -r $_[1] and -w _ }

# Do we have permission to execute a filesystem object
sub canExecute { defined $_[1] and -x $_[1] }

# Could we open this as a file
sub canOpen { defined $_[1] and -f $_[1] and -r _ }

# Could a file or directory be removed, were we to try
sub canRemove {
	# Pass through to the object class
	my $Object = File::Flat::Object->new( $_[1] ) or return undef;
	$Object->canRemove;
}

# Is the file a text file
sub isText { defined $_[1] and -f $_[1] and -T $_[1] }

# Is a file a binary file.
sub isBinary { defined $_[1] and -f $_[1] and -B $_[1] }

# Stat based methods. 
# I've included only the most usefull one I can think of.
sub fileSize {
	my $class = shift;
	my $file  = shift or return undef;

	# Check the file
	return $class->_error( 'File does not exist' ) unless -e $file;
	return $class->_error( 'Cannot get the file size for a directory' ) unless -f _;

	# A file's size is contained in element 7
	(stat $file)[7];
}





#####################################################################
# Opening Files.

# Note: Files are closed conventionally using the IO::Handle's methods.

# Open a file.
# Takes as arguments either a ">filepath" style file name, or the two argument
# form of "mode", "filename". Supports perl '<' type modes, and fopen 'rw' 
# type modes. Pipes and more advanced things are not supported.
# Both the 1 and 2 argument modes are supported.
# Returns an IO::File for the filesystem object.
sub open {
	my $class = shift;

	# One or two argument form
	my ($file, $mode) = ();
	if ( @_ == 1 ) {
		$file = shift;

		# Read by default
		$mode = $file =~ s/^([<>+]{1,2})\s*// ? $1 : '<';

	} elsif ( @_ == 2 ) {
		$mode = shift;
		$file = shift;

	} else {
		return $class->_error( "Invalid argument count to ->open" );
	}

	# Check the mode
	unless ( exists $modes{$mode} ) {
		return $class->_error( "Unknown or unsupported mode '$mode'" );
	}

	# Ensure the directory exists for those that need it
	my $remove_on_fail = '';
	if ( $modes{$mode} and ! -e $file ) {
		$remove_on_fail = $class->_makePath( $file );
		return undef unless defined $remove_on_fail;
	}

	# Try to get the IO::File
	IO::File->new( $file, $mode )
		or $class->_andRemove( $remove_on_fail );
}

# Provide creation mode specific methods
sub getReadHandle      { $_[0]->open( '<',  $_[1] ) }
sub getWriteHandle     { $_[0]->open( '>',  $_[1] ) }
sub getAppendHandle    { $_[0]->open( '>>', $_[1] ) }
sub getReadWriteHandle { $_[0]->open( '+<', $_[1] ) }





#####################################################################
# Quick File Methods

# Slurp quickly reads in an entire file in a memory efficient manner.
# Reads and file and returns a reference to a scalar containing the file.
# Returns 0 if the file does not exist.
# Returns undef on error.
sub slurp {
	my $class = shift;
	my $file  = shift or return undef;

	# Check the file
	$class->canOpen( $file )
		or return $class->_error( "Unable to open file '$file'" );

	# Use idiomatic slurp instead of File::Slurp
	_slurp($file) or $class->_error( "Error opening file '$file'", $! );
}

# Provide a simple _slurp implementation
sub _slurp {
	my $file = shift;
	local $/ = undef;
	local *SLURP;
	CORE::open( SLURP, "<$file" ) or return undef;
	my $source = <SLURP>;
	CORE::close( SLURP ) or return undef;
	\$source;
}

# read reads in an entire file, returning it as an array or a reference to it.
# depending on the calling context. Returns undef or () on error, depending on
# the calling context.
sub read {
	my $class = shift;
	my $file  = shift or return;

	# Check the file
	unless ( $class->canOpen( $file ) ) {
		$class->_error( "Unable to open file '$file'" );
		return;
	}

	# Load the file
	unless ( CORE::open(FILE, $file) ) {
		$class->_error( "Unable to open file '$file'" );
		return;
	}
	my @content = <FILE>;
	chomp @content;
	CORE::close(FILE);

	wantarray ? @content : \@content;
}

# writeFile writes a file to the filesystem, replacing the existing file
# if needed. Existing files will be clobbered before starting to write to
# the file, as per a typical write file handle.
sub write {
	my $class = shift;
	my $file = shift or return undef;
	unless ( defined $_[0] ) {
		return $class->_error( "Did not pass anything to write to file" );
	}

	# Get a ref to the contents.
	# This looks messy, but it avoids copying potentially large amounts
	# of data in memory, bloating the RAM usage.
	# This also makes sure the stuff we are going to write is ok.
	my $contents;
	if ( ref $_[0] ) {
		unless ( UNIVERSAL::isa($_[0], 'SCALAR') or UNIVERSAL::isa($_[0], 'ARRAY') ) {
			return $class->_error( "Unknown or invalid argument to ->write" );
		}

		$contents = $_[0];
	} else {
		$contents = \$_[0];
	}

	# Get an opened write file handle if we weren't passed a handle already.
	# When this falls out of context, it will close itself.
	# Since there are many things that act like file handles, don't check
	# specifically for IO::Handle or anything, just for a reference.
	my $dontclose = 0;
	if ( ref $file ) {
		# Don't close is someone passes us a handle.
		# They might want to write other things.
		$dontclose = 1;
	} else {
		$file = $class->getWriteHandle( $file ) or return undef;
	}

	# Write the contents to the handle
	if ( UNIVERSAL::isa($contents, 'SCALAR') ) {
		$file->print( $$contents ) or return undef;
	} else {
		foreach ( @$contents ) {
			# When printing the lines to the file, 
			# fix any possible newline problems.
			chomp $_;
			$file->print( $_ . "\n" ) or return undef;
		}
	}

	# Close the file if needed
	$file->close unless $dontclose;

	1;
}

# overwrite() writes a file to the filesystem, replacing the existing file
# if needed. Existing files will be clobbered at the end of writing the file,
# essentially allowing you to write the file to disk atomically.
sub overwrite {
	my $class = shift;
	my $file = shift or return undef;
	return undef unless defined $_[0];

	# Make sure we will be able to write over the file
	unless ( $class->canWrite($file) ) {
		return $class->_error( "Will not be able to create the file '$file'" );
	}

	# Load in the two libraries we need.
	# It's a fair chunk of overhead, so we do it here instead of up
	# the top so it only loads in if we need to do overwriting.
	# Not as good as Class::Autouse, but these arn't OO modules.
	require File::Temp;
	require File::Copy;

	# Get a temp file
	my ($handle, $tempfile) = File::Temp::tempfile( SUFFIX => '.tmp', UNLINK => 0 );

	# Write the content to it.
	# Pass the argument by reference if it isn't already,
	# to avoid copying large scalars.
	unless ( $class->write( $handle, ref $_[0] ? $_[0] : \$_[0] ) ) {
		# Clean up and return an error
		$handle->close;
		unlink $tempfile;
		return $class->_error( "Error while writing file" );
	}

	# We are finished with the handle
	$handle->close;

	# Now move the finished file to the final location
	unless ( File::Copy::move( $tempfile, $file ) ) {
		# Clean up the tempfile and return an error
		unlink $tempfile;
		return $class->_error( "Failed to copy file into final location" );
	}

	1;
}

# appendFile writes content to the end of an existing file, or creating the
# file if needed.
sub append {
	my $class = shift;
	my $file = shift or return undef;
	return undef unless defined $_[0];

	# Get the appending handle, and write to it
	my $handle = $class->getAppendHandle( $file ) or return undef;
	unless ( $class->write( $handle, ref $_[0] ? $_[0] : \$_[0] ) ) {
		# Clean up and return an error
		$handle->close;
		return $class->_error( "Error while writing file" );
	}
	$handle->close;

	1;
}

# Copy a file or directory from one place to another.
# We apply our own copy semantics.
sub copy {
	my $class = shift;
	return undef unless defined($_[0]) && defined($_[1]);
	my $source = File::Spec->canonpath( shift ) or return undef;
	my $target = File::Spec->canonpath( shift ) or return undef;

	# Check the source and target
	return $class->_error( "No such file or directory '$source'" ) unless -e $source;
	if ( -e $target ) {
		unless ( -f $source and -f $target ) {
			return $class->_error( "Won't overwrite " 
				. (-f $target ? 'file' : 'directory')
				. " '$target' with "
				. (-f $source ? 'file' : 'directory')
				. " '$source'" );
		}
	}
	unless ( $class->canWrite( $target ) ) {
		return $class->_error( "Insufficient permissions to create '$target'" );
	}

	# Make sure the directory for the target exists
	my $remove_on_fail = $class->_makePath( $target );
	return undef unless defined $remove_on_fail;

	if ( -f $source ) {
		# Copy a file to the new location
		require File::Copy;
		return File::Copy::copy( $source, $target ) ? 1 
			: $class->_andRemove( $remove_on_fail );
	}

	# Create the target directory
	my $tocopy = File::Spec->catfile( $source, '*' ) or return undef;
	unless ( mkdir $target, 0755 ) {
		return $class->_andRemove( $remove_on_fail, 
			"Failed to create directory '$target'" );
	}

	# Hand off to File::Copy::Recursive
	require File::Copy::Recursive;
	my $rv = File::Copy::Recursive::dircopy( $tocopy, $target );
	defined $rv ? $rv : $class->_andRemove( $remove_on_fail );
}

# Move a file from one place to another.
sub move {
	my $class = shift;
	my $source = shift or return undef;
	my $target = shift or return undef;

	# Check the source and target
	return $class->_error( "Copy source '$source' does not exist" ) unless -e $source;
	if ( -d $source and -f $target ) {
		return $class->_error( "Cannot overwrite non-directory '$source' with directory '$target'" );
	}

	# Check permissions
	unless ( $class->canWrite( $target ) ) {
		return $class->_error( "Insufficient permissions to write to '$target'" );
	}

	# Make sure the directory for the target exists
	my $remove_on_fail = $class->_makePath( $target );
	return undef unless defined $remove_on_fail;

	# Do the file move
	require File::Copy;
	my $rv = File::Copy::move( $source, $target );
	unless ( $rv ) {
		# Clean up after ourselves
		File::Flat->remove( $remove_on_fail ) if $remove_on_fail;
		return $class->_error( "Error moveing '$source' to '$target'" );
	}

	1;
}

# Remove a file or directory ( safely )
sub remove {
	my $class = shift;
	my $file = shift or return undef;

	# Does the file exist
	unless ( -e $file ) {
		return $class->_error( "File or directory does not exist" );
	}

	# Use File::Remove to remove it
	require File::Remove;
	File::Remove::remove( \1, $file ) or return undef;
	($AUTO_PRUNE or $_[0]) ? $class->prune( $file ) : 1; # Optionally prune
}

# For a given path, remove any empty directories left behind
sub prune {
	my $Object = File::Flat::Object->new( $_[1] ) or return undef;
	$Object->prune;
}

# Truncate a file. That is, leave the file in place, 
# but reduce its size to a certain size, default 0.
sub truncate {
	my $class = shift;
	my $file = shift or return undef;
	my $bytes = defined $_[0] ? shift : 0; # Beginning unless otherwise specified

	# Check the file
	return $class->_error( "Cannot truncate a directory" ) if -d $file;
	unless ( $class->canWrite( $file ) ) {
		return $class->_error( "Insufficient permissions to truncate file" );
	}

	# Get a handle to the file and truncate it
	my $handle = $class->open( '>', $file )
		or return $class->_error( 'Failed to open write file handle' );
	$handle->truncate( $bytes )
		or return $class->_error( "Failed to truncate file handle: $!" );
	$handle->close;

	1;
}





#####################################################################
# Directory Methods

# Pass these through to the object version. It should be
# better at this sort of thing.

# Create a directory. 
# Returns true on success, undef on error.
sub makeDirectory {
	my $Object = File::Flat::Object->new( $_[1] ) or return undef;
	$Object->makeDirectory;
}

# Make sure that everything above our path exists
sub _makePath {
	my $Object = File::Flat::Object->new( $_[1] ) or return undef;
	$Object->_makePath;
}

# Legacy, kept around for CVS Monitor
*_ensureDirectory = *_makePath;




#####################################################################
# Error handling

sub errstr { $errstr }
sub _error { $errstr = $_[1]; undef }
sub _andRemove {
	my $self = shift;
	my $to_remove = shift;
	if ( length $to_remove ) {
		require File::Remove;
		File::Remove::remove( $to_remove );
	}

	@_ ? $self->_error(@_) : undef;
}

1;








package File::Flat::Object;

# Instantiatable version of File::Flat.
# 
# The methods are the same as for File::Flat, where applicable.

use strict;
use File::Spec ();

sub new {
	my $class    = shift;
	my $filename = shift or return undef;

	bless {
		type        => undef,
		original    => $filename,
		absolute    => undef,
		volume      => undef,
		directories => undef,
		file        => undef,
		}, $class;
}

sub _init {
	my $self = shift;

	# Get the current working directory.
	# If we don't pass it ourselves to File::Spec->rel2abs, 
	# it might use a backtick `pwd`, which is horribly slow.
	my $base = Cwd::getcwd();

	# Populate the other properties
	$self->{absolute}    = File::Spec->rel2abs( $self->{original}, $base );
	my ($v, $d, $f)      = File::Spec->splitpath( $self->{absolute} );
	my @dirs             = File::Spec->splitdir( $d );
	$self->{volume}      = $v;
	$self->{directories} = \@dirs;
	$self->{file}        = $f;
	$self->{type}        = $self->{file} eq '' ? 'directory' : 'file';

	1;
}

# Define the basics
sub exists       { -e $_[0]->{original} }
sub isaFile      { -f $_[0]->{original} }
sub isaDirectory { -d $_[0]->{original} }
sub canRead      { -e $_[0]->{original} and -r _ }
sub canWrite     { -e $_[0]->{original} and -w _ }
sub canReadWrite { -e $_[0]->{original} and -r _ and -w _ }
sub canExecute   { -e $_[0]->{original} and -x _ }
sub canOpen      { -f $_[0]->{original} and -r _ }
sub fileSize     { File::Flat->fileSize( $_[0]->{original} ) }

# Can we create this file/directory, if it doesn't exist.
# Returns 2 if yes, but we need to create directories
# Returns 1 if yes, and we won't need to create any directories.
# Returns 0 if no.
sub _canCreate {
	my $self = shift;
	$self->_init unless defined $self->{type};

	# It it already exists, check for writable instead
	return $self->canWrite if -e $self->{original};
 
	# Go up the directories and find the last one that exists
	my $dir_known   = '';
	my $dir_unknown = '';
	my @dirs = @{$self->{directories}};
	pop @dirs if $self->{file} eq '';
	while ( defined( my $dir = shift @dirs ) ) {
		$dir_unknown = File::Spec->catdir( $dir_known, $dir );

		# Does the filesystem object exist.
		# We use '' for the file part, because not specifying it at
		# all throws a warning.
		my $fullpath = File::Spec->catpath( $self->{volume}, $dir_unknown, '' );
		last unless -e $fullpath;

		# This should be a directory
		if ( -d $fullpath ) {
			$dir_known = $dir_unknown;
			next;
		}

		# A file is where we think a directory should be
		0;
	}

	# $dir_known now contains the last directory that exists.
	# Can we create filesystem objects under this?
	return 0 unless -w $dir_known;

	# If @dirs is empty, we don't need to create
	# any directories when we create the file
	@dirs ? 2 : 1;
}

### FIXME - Implement this.
# Should check the we can delete the file.
# If it's a directory, should check that we can
# recursively delete everything in it.
sub canRemove { die "The ->canRemove method has not been implemented yet" }

# Is the file a text file.
sub isText { -e $_[0]->{original} and -f _ and -T $_[0]->{original} }

# Is a file a binary file.
sub isBinary { -e $_[0]->{original} and -f _ and -B $_[0]->{original} }





#####################################################################
# Opening File

# Pass these down to the static methods

sub open { 
	my $self = shift;
	defined $_[0]
		? File::Flat->open( $self->{original}, $_[0] ) 
		: File::Flat->open( $self->{original} )
}

sub getReadHandle      { File::Flat->open( '<',  $_[0]->{original} ) }
sub getWriteHandle     { File::Flat->open( '>',  $_[0]->{original} ) }
sub getAppendHandle    { File::Flat->open( '>>', $_[0]->{original} ) }
sub getReadWriteHandle { File::Flat->open( '+<', $_[0]->{original} ) }





#####################################################################
# Quick File Methods

sub slurp     { File::Flat->slurp(     $_[0]->{original} ) }
sub read      { File::Flat->read(      $_[0]->{original} ) }
sub write     { File::Flat->write(     $_[0]->{original} ) }
sub overwrite { File::Flat->overwrite( $_[0]->{original} ) }
sub append    { File::Flat->append(    $_[0]->{original} ) }
sub copy      { File::Flat->copy(      $_[0]->{original}, $_[1] ) }

sub move { 
	my $self = shift;
	my $moveTo = shift;
	File::Flat->move( $self->{original}, $moveTo ) or return undef;

	# Since the file is moving, once we actually
	# move the file, update the object information so
	# it refers to the new location.
	$self->{original} = $moveTo;

	# Re-initialise if we have already
	$self->init if $self->{type};

	1;
}

sub remove {
	File::Flat->remove( $_[0]->{original} );
}

# For a given path, remove all empty files that were left behind
# by previously deleting it.
sub prune {
	my $self = shift;
	$self->_init unless defined $self->{type};

	# We don't actually delete anything that currently exists
	if ( -e $self->{original} ) {
		return $self->_error('Bad use of ->prune, to try to delete a file');
	}

	# Get the list of directories, fully resolved
	### TO DO - Might be able to do this smaller or more efficiently
	###         by using List::Util::reduce
	my @dirs = @{$self->{directories}};
	my @potential = (
		File::Spec->catpath( $self->{volume}, shift(@dirs), '' )
		);
	while ( @dirs ) {
		push @potential, File::Spec->catdir( $potential[-1], shift(@dirs), '' );
	}

	# Go backwards though this list
	foreach my $dir ( reverse @potential ) {
		# Not existing is good... it fulfils the intent
		next unless -e $dir;

		# This should also definately be a file
		unless ( -d $dir ) {
			return $self->_error('Found file where a directory was expected while pruning');
		}

		# Does it contain anything, other that (possibly) curdir and updir entries
		opendir( PRUNEDIR, $dir )
			or return $self->_error("opendir failed while pruning: $!");
		my @files = readdir PRUNEDIR;
		closedir PRUNEDIR;
		foreach ( @files ) {
			next if $_ eq File::Spec->curdir;
			next if $_ eq File::Spec->updir;

			# Found something, we don't need to prune this,
			# or anything else for that matter.
			return 1;
		}

		# Nothing in the directory, we can delete it
		File::Flat->remove( $dir ) or return undef;
	}

	1;
}

sub truncate {
	File::Flat->truncate( $_[0]->{original} );
}





#####################################################################
# Directory methods

# Create a directory. 
# Returns true on success, undef on error.
sub makeDirectory {
	my $self = shift;
	my $mode = shift || 0755;
	if ( -e $self->{original} ) {
		return 1 if -d $self->{original};
		return $self->_error( "'$self->{original}' already exists, and is a file" );
	}
	$self->_init unless defined $self->{type};

	# Ensure the directory below ours exists
	my $remove_on_fail = $self->_makePath( $mode );
	return undef unless defined $remove_on_fail;

	# Create the directory
	unless ( mkdir $self->{original}, $mode ) {
		return $self->_andRemove( $remove_on_fail, 
			"Failed to create directory '$self->{original}': $!" );
	}

	1;
}

# Make sure the directory that this file/directory is in exists.
# Returns the root of the creation dirs if created.
# Returns '' if nothing required.
# Returns undef on error.
sub _makePath {
	my $self = shift;
	my $mode = shift || 0755;
	return '' if -e $self->{original};
	$self->_init unless defined $self->{type};

	# Go up the directories and find the last one that exists
	my $dir_known     = '';
	my $dir_unknown   = '';
	my $creation_root = '';
	my @dirs = @{$self->{directories}};
	pop @dirs if $self->{file} eq '';
	while ( defined( my $dir = shift @dirs ) ) {
		$dir_unknown = File::Spec->catdir( $dir_known, $dir );

		# Does the filesystem object exist
		# We use '' for the file part, because not specifying it at
		# all throws a warning.
		my $fullpath = File::Spec->catpath( $self->{volume}, $dir_unknown, '' );
		if ( -e $fullpath ) {
			# This should be a directory
			return undef unless -d $fullpath;
		} else {
			# Try to create the directory
			unless ( mkdir $dir_unknown, $mode ) {
				return $self->_error( $! );
			}

			# Set the base of our creations to return
			$creation_root = $dir_unknown unless $creation_root;
		}

		$dir_known = $dir_unknown;
	}

	$creation_root;
}

# Legacy, kept around for CVS Monitor
*_ensureDirectory = *_makePath;





#####################################################################
# Error handling

sub errstr { $File::Flat::errstr }
sub _error { $File::Flat::errstr = $_[1]; undef }
sub _andRemove { shift; File::Flat->_andRemove(@_) }

1;

__END__

=pod

=head1 NAME

File::Flat - Implements a flat filesystem

=head1 SYNOPSIS

=head1 DESCRIPTION

File::Flat implements a flat filesystem. A flat filesystem is a filesystem in
which directories do not exist. It provides an abstraction over any normal
filesystem which makes it appear as if directories do not exist. In effect,
it will automatically create directories as needed. This is create for things
like install scripts and such, as you never need to worry about the existance
of directories, just write to a file, no matter where it is.

=head2 Comprehensive Implementation

The implementation of File::Flat is extremely comprehensive in scope. It has
methods for all stardard file interaction taks, the -X series of tests, and
some other things, such as slurp.

All methods are statically called, for example, to write some stuff to a file.

  use File::Flat;
  File::Flat->write( 'filename', 'file contents' );

=head2 Use of other modules

File::Flat tries to use more task orientated modules wherever possible. This
includes the use of L<File::Copy>, L<File::Copy::Recursive>, L<File::Remove>
and others. These are mostly loaded on-demand.

=head2 Pruning and $AUTO_PRUNE

"Pruning" is a technique where empty directories are assumed to be useless,
and thus empty removed whenever one is created. Thus, when some other task
has the potential to leave an empty directory, it is checked and deleted if
it is empty.

By default File::Flat does not prune, and pruning must be done explicitly,
via either the L<File::Flat/prune> method, or by setting the second
argument to the L<File::Flat/remove> method to be true.

However by setting the global C<$AUTO_PRUNE> variable to true, File::Flat
will automatically prune directories at all times. You should generally use
this locally, such as in the following example.

  #!/usr/bin/perl
  
  use strict;
  use File::Flat;
  
  delete_files(@ARGV);
  exit();
  
  # Recursively delete and prune all files provided on the command line
  sub delete_files {
  	local $File::Flat::AUTO_PRUNE = 1;
  	foreach my $file ( @_ ) {
  		File::Flat->remove( $file ) or die "Failed to delete $file";
  	}
  }

=head2 Non-Unix platforms

As of version 0.97 File::Flat should work correctly on Win32. Other
platforms (such as VMS) are believed to work, but require confirmation.

=head1 METHODS

=head2 exists $filename 

Tests for the existance of the file.
This is an exact duplicate of the -e function.

=head2 isaFile $filename

Tests whether C<filename> is a file.
This is an exact duplicate of the -f function.

=head2 isaDirectory $filename

Test whether C<filename> is a directory.
This is an exact duplicate of the -d function.

=head2 canRead $filename

Does the file or directory exist, and can we read from it.

=head2 canWrite $filename

Does the file or directory exist, and can we write to it 
B<OR> can we create the file or directory.

=head2 canReadWrite $filename

Does a file or directory exist, and can we both read and write it.

=head2 canExecute $filename

Does a file or directory exist, and can we execute it.

=head2 canOpen $filename

Is this something we can open a filehandle to. Returns true if filename
exists, is a file, and we can read from it.

=head2 canRemove $filename

Can we remove the file or directory.

=head2 isaText $filename

Does the file C<filename> exist, and is it a text file.

=head2 isaBinary $filename

Does the file C<filename> exist, and is it a binary file.

=head2 fileSize $filename

If the file exists, returns its size in bytes.
Returns undef if the file does not exist.

=head2 open [ $mode, ] $filename

Rough analogue of the open function, but creates directories on demand
as needed. Supports most of the normal options to the normal open function.

In the single argument form, it takes modes in the form [mode]filename. For
example, all the following are valid.

  File::Flat->open( 'filename' );
  File::Flat->open( '<filename' );
  File::Flat->open( '>filename' );
  File::Flat->open( '>>filename' );
  File::Flat->open( '+<filename' );

In the two argument form, it takes the following

  File::Flat->open( '<', 'filename' );
  File::Flat->open( '>', 'filename' );
  File::Flat->open( '>>', 'filename' );
  File::Flat->open( '+<', 'filename' );

It does not support the more esoteric forms of open, such us opening to a pipe
or other such things.

On successfully opening the file, it returns it as an IO::File object.
Returns undef on error.

=head2 getReadHandle $filename

The same as File::Flat->open( '<', 'filename' )

=head2 getWriteHandle $filename

The same as File::Flat->open( '>', 'filename' )

=head2 getAppendHandle $filename

The same as File::Flat->open( '>>', 'filename' )

=head2 getReadWriteHandle $filename

The same as File::Flat->open( '+<', 'filename' )

=head2 read $filename

Opens and reads in an entire file, chomping as needed.

In array context, it returns an array containing each line of the file.
In scalar context, it returns a reference to an array containing each line of
the file. It returns undef on error.

=head2 slurp $filename

The C<slurp> method 'slurps' a file in. That is it attempts to read the entire
file into a variable in as quick and memory efficient method as possible.

On success, returns a reference to a scalar, containing the entire file.
Returns undef on error.

=head2 write $filename, ( $content | \$content | \@content )

The C<write> method is the main method for writing content to a file.
It takes two arguments, the location to write to, and the content to write, 
in several forms.

If the file already exists, it will be clobered before writing starts.
If the file doesn't exists, the file and any directories will be created as
needed.

Content can be provided in three forms. The contents of a scalar argument will
be written directly to the file. You can optionally pass a reference to the 
scalar. This is recommended when the file size is bigger than a few thousand
characters, is it does not duplicate the file contents in memory.
Alternatively, you can pass the content as a reference to an array containing
the contents. To ensure uniformity, C<write> will add a newline to each line,
replacing any existing newline as needed.

Returns true on success, and undef on error.

=head2 append $filename, ( $content | \$content | \@content )

This method is the same as C<write>, except that it appends to the end of 
an existing file ( or creates the file as needed ).

This is the method you should be using to write to log files, etc.

=head2 overwrite $filename, ( $content | \$content | \@content )

Performs an atomic write over a file. It does this by writing to a temporary
file, and moving the completed file over the top of the existing file ( or
creating a new file as needed ). When writing to a file that is on the same
partition as /tmp, this should always be atomic. 

This method otherwise acts the same as C<write>.

=head2 copy $source, $target

The C<copy> method attempts to copy a file or directory from the source to
the target. New directories to contain the target will be created as needed.

For example C<<File::Flat->( './this', './a/b/c/d/that' );>> will create the
directory structure required as needed. 

In the file copy case, if the target already exists, and is a writable file,
we replace the existing file, retaining file mode and owners. If the target
is a directory, we do NOT copy into that directory, unlike with the 'cp'
unix command. And error is instead returned.

C<copy> will also do limited recursive copying or directories. If source
is a directory, and target does not exists, a recursive copy of source will
be made to target. If target already exists ( file or directory ), C<copy>
will returns with an error.

=head2 move $source, $target

The C<move> method follows the conventions of the 'mv' command, with the 
exception that the directories containing target will of course be created
on demand.

=head2 remove $filename [, $prune ]

The C<remove> method will remove a file, or recursively remove a directory.

If a second (true) argument is provided, then once the file or directory
has been deleted, the method will the automatically work its way upwards
pruning (deleting) empty and thus assumably useless directories.

Returns true if the deletion (and pruning if requested) was a success, or
C<undef> otherwise.

=head2 prune $filename

For a file that has already been delete, C<prune> will work upwards,
removing any empty directories it finds.

For anyone familiar with CVS, it is similar to the C<update -P> flag.

Returns true, or C<undef> on error.

=head2 truncate $filename [, $size ]

The C<truncate> method will truncate an existing file to partular size.
A size of 0 ( zero ) is used if no size is provided. If the file does not
exists, it will be created, and set to 0. Attempting to truncate a 
directory will fail.

Returns true on success, or undef on error.

=head2 makeDirectory $directory [, mode ]

In the case where you do actually have to create a directory only, the
C<makeDirectory> method can be used to create a directory or any depth.

An optional file mode ( default 0755 ) can be provided.

Returns true on success, returns undef on error.

=head1 TO DO

Function interface to be written, like
L<File::Spec::Functions>, to provide importable functions.

There's something bigger here too, I'm not exactly sure what it is,
but I think there might be the beginings of a unified filesystem
interface here... FSI.pm

=head1 SUPPORT

Bugs should be filed at via the CPAN bug tracker at:

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Flat>

For other issues or comments, contact the author

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<File::Spec>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2002 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
