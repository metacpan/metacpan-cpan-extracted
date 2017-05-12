package File::BLOB;

=pod

=head1 NAME

File::BLOB - A file (with name, and other metadata) you can BLOBify

=head1 SYNOPSIS

  # Create a File::BLOB object from data or a filehandle
  $file = File::BLOB->new( 'data'         ); # Copies
  $file = File::BLOB->new( \$data         ); # Doesn't copy
  $file = File::BLOB->new( $filehandle    );
  
  # Create from an existing file
  $file = File::BLOB->from_file( 'filename.txt' );
  
  # Create from a file uploaded via CGI
  $file = File::BLOB->from_cgi( $CGI, 'param' );
  
  # You can assign arbitrary headers/metadata when creating objects
  $file = File::BLOB->new( 'filename.txt',
  	content_type => 'text/plain',
  	filename     => 'myname.txt',
  	owner        => 'ADAMK',
  	);
  if ( $file->get_header('filename') eq 'filename.txt' ) {
  	$file->set_header( 'filename' => 'yourname.txt' );
  }
  
  # Get or change the content
  if ( $file->get_content =~ /FOO/ ) {
  	my $backup = $file->get_content;
  	$file->set_content( 'data'      );
  	$file->set_content( \$data      );
  	$file->set_content( $filehandle );
  }
  
  # Freeze to and thaw from a BLOB
  my $blob = $file->freeze;
  $file = File::BLOB->thaw( $blob );

=head1 DESCRIPTION

One of the most common types of data found in systems ranging from email to
databases is a "file". And yet there is no simple way to create a store a
file is a chunk of data across all of these systems.

Modules designed for email aren't easily reusable in databases, and while
databases often support "BLOB" data types, they don't keep file names and
encoding types attached so that these files are usable beyond treating
them as mere data.

C<File::BLOB> is an object that represents a file, L<Storable> as a BLOB
in a database or some other system, but retaining metadata such as file
name, type and any other custom headers people want to attach.

The range of tasks it is intented to span include such things as pulling
a file from the database and sending it straight to the browser, saving
an object from CGI to a database, and so on.

In general, for code that needs to span problem domains without losing
the name of the file or other data.

=head2 Storage Format

C<File::BLOB> stores its data in a way that is compatible with both
L<Storable> and HTTP. The stored form looks a lot like a HTTP response,
with a series of newline-seperated header lines followed by two newlines
and then file data.

=head1 METHODS

=cut

use 5.006;
use strict;
use bytes          ();
use Carp           ();
use IO::File       ();
use Storable       2.16 ();
use File::Basename ();
use Params::Util   0.10 ();

# Optional prefork support
SCOPE: {
	local $@;
	eval "use prefork 'File::Type';";
}

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.08';
}





#####################################################################
# Constructor and Accessors

=pod

=head1 new

  $file = File::BLOB->new( $data     );
  $file = File::BLOB->new( \$data    );
  $file = File::BLOB->new( $iohandle );
  $file = File::BLOB->new( $data,
  	header   => 'value',
  	filename => 'file.txt',
  	);

Creates a new C<File::BLOB> object from data.

It takes as its first param the data, in the form of a normal scalar
string (which will be copied), a C<SCALAR> reference (which will
B<not> be copied), or as a filehandle (any subclass of L<IO::Handle>
can be used).

While the C<content_length> header will be set automatically, you
may wish to provide the C<content_type> header yourself if know, to
avoid having to load L<File::Type> to determine the file type.

Returns a C<File::BLOB> object, or dies on error.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	# Create the basic object
	my $self = bless {}, $class;

	# Set the content (don't copy it yet)
	$self->set_content(shift);

	# Set the headers
	while ( @_ ) {
		$self->set_header(shift, shift);
	}

	# Unless we know the MIME type, find it
	$self->{content_type} ||= $self->_mime_type($self->{content});

	$self;
}

=pod

=head2 from_file

  $file = File::BLOB->from_file( "/home/me/some_picture.gif" );
  $file = File::BLOB->from_file( "foo.txt",
  	'content_type' => 'text/plain',
  	'foo'          => 'bar',
  	);

The C<from_file> method provides an alternative constructor that creates
an object directly from a file, using that filename and detecting the
MIME type automatically.

The same rules as for the C<new> constructor apply regarding additional
parameters.

Returns a new C<File::BLOB> object, or dies on error.

=cut

sub from_file {
	my $class  = ref $_[0] ? ref shift : shift;
	my $path   = shift;
	my %params = @_; # Just for use here

	# Basic checks on the filename
	unless ( $path and -e $path ) {
		Carp::croak("Invalid file name or file does not exist");
	}
	unless ( -r _ ) {
		Carp::croak("Insufficient permissions to read file");
	}

	# Find the file name
	my @auto = ();
	unless ( exists $params{filename} ) {
		my $file = File::Basename::basename($path)
			or Carp::croak("Failed to determine file name");
		push @auto, 'filename' => $file;
	}

	# Open the file
	my $handle = IO::File->new($path, "r");
	unless ( $handle ) {
		Carp::croak("Failed to open file: $!");
	}

	$class->new( $handle, @auto, @_ );
}

=pod

=head2 from_cgi

  my $file = File::BLOB->from_cgi( $CGI, 'param' );

The C<from_cgi> constructor allows you to create a C<File::BLOB>
object from a named file upload field in a CGI form.

It takes a L<CGI> object and a CGI param name. Only a single
file upload for the param is supported.

When called in list context, the C<from_cgi> method will return
a list of C<File::BLOB> objects, or the null list of there are
no uploaded files for the param.

When called in scalar context, the C<from_cgi> method return a
single C<File::BLOB> object (if more than one the first), or
false (C<''>) if there are no file uploads.

An exception will be thrown if an error is encountered.

=cut

sub from_cgi {
	my $class = ref $_[0] ? ref shift : shift;
	my $cgi   = Params::Util::_INSTANCE(shift, 'CGI') or Carp::croak(
		'First argument to from_cgi was not a CGI object'
		);
	my $param = shift;
	Params::Util::_SCALAR(\$param) or Carp::croak(
		'Second argument to from_cgi was not a CGI param'
		);

	# Fetch the filehandles
	my @handles = $cgi->upload($param) or return;
	if ( ! wantarray ) {
		# Remove all but the first filehandle
		while ( @handles > 1 ) {
			pop @handles;
		}
	}

	# Convert each of the filehandles to File::BLOB objects,
	# with all headers intact.
	my @objects = ();
	foreach my $fh ( @handles ) {
		my $headers = $cgi->uploadInfo($fh) or Carp::croak(
			"Failed to get headers for upload '$param'"
			);
		my $file = File::BLOB->new( $fh, %$headers ) or Carp::croak(
			"Failed to create File::BLOB for upload '$param'"
			);
		push @objects, $file;
	}

	# Return in either list or scalar context
	wantarray ? @objects : $objects[0];
}





#####################################################################
# Work with the Content

=pod

=head2 get_content

  my $data = $file->get_content;
  my $copy = $$data;

The C<get_content> returns the contents of the file as C<SCALAR> reference.

Please note that the reference returned points to the actual data in the
object, so it should not modified. If you want to modify the contents,
you need to copy it first.

=cut

sub get_content {
	$_[0]->{content};
}

=pod

=head2 set_content

  $file->set_content( $data     );
  $file->set_content( \$data    );
  $file->set_content( $iohandle );

The C<set_content> method sets the contents of the file to a new value.

It takes a single param which should be an ordinary scalar (which will
be copied), a C<SCALAR> reference (which will not be copied), or a
filehandle (any object which is a subclass of L<IO::Handle>).

Because you aren't really meant to use this to add in entirely new
content, any C<content_type> header will not be changed, although the
C<content_length> header will be updated.

So while the modification of content without changing its type is fine,
don't go adding different types of data.

Returns true, or dies on error.

=cut

sub set_content {
	my $self = shift;
	my $data = shift;

	# Ensure the passed data is a scalar reference
	my $content;
	if ( Params::Util::_SCALAR($data) ) {
		$content = $data;
	} elsif ( Params::Util::_INSTANCE($data, 'IO::Handle') ) {
		# Read in as binary data
		local $/ = undef;
		$data->binmode if $data->can('binmode');
		my $data = $data->getline;
		unless ( defined $data and ! ref $data ) {
			Carp::croak("Failed to get content from filehandle");
		}
		$content = \$data;
	} elsif ( defined $data and ! ref $data ) {
		$content = \$data;
	} else {
		Carp::croak("Invalid parameter to File::BLOB::new");
	}

	# Set the content and content_length
	$self->{content}        = $content;
	$self->{content_length} = bytes::length($$content);

	1;
}

=pod

=head2 get_header

  my $name = $file->get_header('filename');

The C<get_header> method gets a named header for the file.

Names are case-insensitive but must be a valid Perl identifier. For things
that have a dash in HTTP (Content-Type:) use an underscore instead.

Returns the header as a string, C<undef> if a header by that name does not
exist, or dies on error.

=cut

sub get_header {
	my $self = shift;
	my $name = $self->_name(shift);
	return $self->{$name};
}

=pod

=head2 set_header

  # Set a header
  $file->set_header('filename', 'foo.txt');
  
  # Delete a header
  $file->set_header('filename', undef    );

The C<set_header> method takes a header name and a value, and sets the
header to that value.

Names are case-insensitive but must be a valid Perl identifier. For things
that have a dash in HTTP (Content-Type:) use an underscore instead.

Values must be a normal string of non-null length. If the value passed is
C<undef>, the header will be deleted. Deleting a non-existant header will
not cause an error.

Returns true if header set or dies on error.

=cut

sub set_header {
	my $self  = shift;
	my $name  = $self->_name(shift);
	@_ or Carp::croak("Did not provide a value for header $name");
	my $value = $self->_value(shift);

	if ( defined $value ) {
		# Set the header
		$self->{$name} = $value;
	} else {
		# Remove the header
		delete $self->{$name};
	}

	1;
}





#####################################################################
# Storable Support

=pod

=head2 freeze

  my $string = $file->freeze;

The C<freeze> method generates string that will be stored in the database.

Returns a normal string.

=cut

sub freeze {
	my $self = shift;

	# Generate the headers
	my $frozen = '';
	foreach my $name ( sort keys %$self ) {
		next if $name eq 'content';
		$frozen .= "$name: $self->{$name}\012";
	}
	$frozen .= "\012";

	# Add the main content and return
	return ( $frozen . ${$self->{content}} );
}

=pod

=head2 thaw

  my $file = File::BLOB->thaw( $string );

The C<thaw> method takes a string previous created by the C<frozen>
method, and creates the C<File::BLOB> object from it.

Returns a C<File::BLOB> object, or dies on error.

=cut

sub thaw {
	my ($class, $serialized) = @_; # Copy to destroy

	# Parse in the data
	my %headers = ();
	while ( $serialized =~ s/^(.*?)\012//s ) {
		my $header = $1;
		if ( bytes::length($header) ) {
			unless ( $header =~ /^(.+?): (.+)\z/s ) {
				Carp::croak("Frozen File::BLOB object is corrupt");
			}
			$headers{lc $1} = $2;
			next;
		}

		# We hit the double-newline. The remainder of
		# the file is the content.
		unless ( defined $headers{content_length} ) {
			Carp::croak("Frozen File::BLOB object is corrupt");
		}
		unless ( $headers{content_length} == bytes::length($serialized) ) {
			Carp::croak("Frozen File::BLOB object is corrupt");
		}

		# Hand off to the constructor
		delete $headers{content_length};
		return $class->new( \$serialized, %headers );
	}

	# This would be bad. It shouldn't happen
	Carp::croak("Frozen File::BLOB object is corrupt");
}





#####################################################################
# File Serialization

sub save {

}

sub read {
	my $class = shift;

	# Check the file
	my $file = shift;
	Carp::croak('You did not specify a file name')          unless $file;
	Carp::croak("File '$file' does not exist")              unless -e $file;
	Carp::croak("'$file' is a directory, not a file")       unless -f _;
	Carp::croak("Insufficient permissions to read '$file'") unless -r _;

	# Open the file and read in the headers
	my %headers = ();
	my $handle  = IO::File->new($file, 'r');
	Carp::croak("Failed to open file $file") unless $handle;
	while ( defined(my $line = $handle->getline) ) {
		chomp($line);
		last if ! length($line);
		unless ( $line =~ /^(\w+):\s*(.+?)\s$/ ) {
			Carp::croak("Illegal header line $line");
		}
		$headers{$1} = $2;
	}

	# Check class
	unless ( $headers{class} eq $class ) {
		Carp::croak("Serialized class mismatch. Expected $class, got $headers{$class}");
	}

	return $class->new( $handle, %headers );
}





#####################################################################
# Support Methods

# Check a name parameter
sub _name {
	my $self  = shift;

	# Check the name is a string
	my $name = shift;
	if ( ! defined $name ) {
		Carp::croak("Header name was an undefined value");
	}
	if ( ref $name ) {
		Carp::croak("Header name cannot be a reference");
	}
	if ( $name eq '' ) {
		Carp::croak("Header name cannot be a null string");
	}

	# The name should be an identifier	
	$name = lc $name;
	unless ( Params::Util::_IDENTIFIER($name) ) {
		Carp::croak("Header name is not in a valid format");
	}
	if ( $name eq 'content' ) { 
		Carp::croak("Header name 'content' is reserved");
	}

	return $name;
}

# Check the value is a string
sub _value {
	my $self  = shift;

	# Check the value is a string
	my $value = shift;
	if ( ! defined $value ) {
		# In this case, it is legal
		return $value;
	}
	if ( ref $value ) {
		Carp::croak("Header value cannot be a reference");
	}
	if ( $value eq '' ) {
		Carp::croak("Header value cannot be a null string");
	}

	# Cannot contain newlines or colons
	if ( $value =~ /\n/s ) {
		Carp::croak("Header value cannot contain newlines");
	}

	return $value;
}

# Takes a SCALAR reference and returns the MIME type
sub _mime_type {
	my $self = shift;
	my $data = Params::Util::_SCALAR(shift) or Carp::croak(
		"Did not provide a SCALAR reference to File::BLOB::_mime_type"
		);
	require File::Type;
	return File::Type->checktype_contents($$data);
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-BLOB>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
