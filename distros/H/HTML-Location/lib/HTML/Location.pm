package HTML::Location;

=pod

=head1 NAME

HTML::Location - Working with disk to URI file mappings (deprecated: see URI::ToDisk)

=head1 STATUS

As correctly noted by several users, C<HTML::Location> is a really stupid
name for this module. I apologise, I was new to the whole CPAN game at the
time I first wrote it.

B<This module has been relocated> to L<URI::ToDisk>. This module will
remain indefinately for back-compatibility, but should otherwise be
B<considered deprecated>.

Please convert your code to the otherwise identical L<URI::ToDisk> at
your leisure.

=head1 SYNOPSIS

  # We have a directory on disk that is accessible via a web server
  my $authors = HTML::Location->new( '/var/www/AUTHORS', 'http://ali.as/AUTHORS' );
  
  # We know where a particular generated file needs to go
  my $about = $authors->catfile( 'A', 'AD', 'ADAMK', 'about.html' );
  
  # Save the file to disk
  my $file = $about->path;
  open( FILE, ">$file" ) or die "open: $!";
  print FILE, $content;
  close FILE;
  
  # Show the user where to see the file
  my $uri = $about->uri;
  print "Author information is at $uri\n";

=head1 DESCRIPTION

In several process relating to working with the web, we may need to keep
track of an area of disk that maps to a particular URL. From this location,
we should be able to derived both a filesystem path and URL for any given
directory or file under this location that we might need to work with.

=head2 Implementation

Internally each C<HTML::Location> object contains both a filesystem path, 
which is altered using L<File::Spec>, and a L<URI> object. When making a 
change, the path section of the URI is altered using <File::Spec::Unix>.

=head2 Method Calling Conventions

The main functional methods, such as C<catdir> and C<catfile>, do B<not>
modify the original object, instead returning a new object containing the
new location.

This means that it should be used in a somewhat similar way to L<File::Spec>.

  # The File::Spec way
  my $path = '/some/path';
  $path = File::Spec->catfile( $path, 'some', 'file.txt' );
  
  # The HTML::Location way
  my $location = HTML::Location->new( '/some/path', 'http://foo.com/blah' );
  $location = $location->catfile( 'some', 'file.txt' );

OK, well it's not exactly THAT close, but you get the idea. It also allows you
to do method chaining, which is basically

  HTML::Location->new( '/foo', 'http://foo.com/' )->catfile( 'bar.txt' )->uri

Which may seem a little trivial now, but I expect it to get more useful later.
It also means you can do things like this.

  my $base = HTML::Location->new( '/my/cache', 'http://foo.com/' );
  foreach my $path ( @some_files ) {
  	my $file = $base->catfile( $path );
  	print $file->path . ': ' . $file->uri . "\n";
  }

In the above example, you don't have to be continuously cloning the location,
because all that stuff happens internally as needed.

=head1 METHODS

=cut

use strict;
use Clone            ();
use URI              ();
use File::Spec       ();
use File::Spec::Unix ();

# Overload stringification to the string form of the URL.
use overload 'bool' => sub () { 1 };
use overload '""'   => 'uri';
use overload 'eq'   => '__eq';

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.03';
	@ISA     = 'Clone';
}





#####################################################################
# Constructors

=pod

=head2 new $path, $http_url

The C<new> constructor takes as argument a filesystem path and a http(s) 
URL. Both are required, and the method will return C<undef> is either is 
illegal. The URL is not required to have protocol, host or port sections,
and as such allows for host-relative URL to be used.

Returns a new C<HTML::Location> object on success, or C<undef> on failure.

=cut

sub new {
	my $class = shift;

	# Get the base file system path
	my $path = File::Spec->canonpath(shift) or return undef;

	# Get the base URI. We only accept HTTP(s) URLs
	return undef unless defined $_[0] and ! ref $_[0];
	my $URI = URI->new( shift, 'http' ) or return undef;
	$URI->path( '/' ) unless length $URI->path;

	# Create the object
	bless { path => $path, URI => $URI }, $class;
}

=pod

=head2 param $various

C<param> is provided as a mechanism for higher order modules to flexibly
accept HTML::Location's as parameters. In this case, it accepts either
an existing HTML::Location object, two arguments ($path, $http_url), or
a reference to an array containing the same two arguments.

Returns a HTML::Location if possible, or C<undef> if one cannot be provided.

=cut

sub param {
	my $class = shift;
	return shift if UNIVERSAL::isa(ref $_[0], 'HTML::Location');
	return HTML::Location->new(@_) if @_ == 2;
	if ( ref $_[0] eq 'ARRAY' and @{$_[0]} ) {
		return HTML::Location->new(@{$_[0]});
	}
	undef;	
}





#####################################################################
# Accessors

=pod

=head2 uri

The C<uri> method gets and returns the current URI of the location, in 
string form.

=cut

sub uri {
	$_[0]->{URI}->as_string;
}

=pod

=head2 URI

The capitalised C<URI> method gets and returns a copy of the raw L<URI>,
held internally by the location. Note that only a copy is returned, and
as such as safe to further modify yourself without effecting the location.

=cut

sub URI {
	Clone::clone $_[0]->{URI};
}

=pod

=head2 path

The C<path> method returns the filesystem path componant of the location.

=cut

sub path { $_[0]->{path} }





#####################################################################
# Manipulate Locations

=pod

=head2 catdir 'dir', 'dir', ...

A L<File::Spec> workalike, the C<catdir> method acts in the same way as for
L<File::Spec>, modifying both componants of the location. The C<catdir> method
returns a B<new> HTML::Location object representing the new location, or
C<undef> on error.

=cut

sub catdir {
	my $self = shift;
	my @args = @_;

	# Alter the URI and local paths
	my $new_uri  = File::Spec::Unix->catdir( $self->{URI}->path, @args ) or return undef;
	my $new_path = File::Spec->catdir( $self->{path}, @args )            or return undef;

	# Clone and set the new values
	my $changed = $self->clone;
	$changed->{URI}->path( $new_uri );
	$changed->{path} = $new_path;

	$changed;
}

=pod

=head2 catfile [ 'dir', ..., ] $file

Like C<catdir>, the C<catfile> method acts in the same was as for 
L<File::Spec>, and returns a new HTML::Location object representing 
the file, or C<undef> on error.

=cut

sub catfile {
	my $self = shift;
	my @args = @_;

	# Alter the URI and local paths
	my $uri = File::Spec::Unix->catfile( $self->{URI}->path, @args ) or return undef;
	my $fs  = File::Spec->catfile( $self->{path}, @args )            or return undef;

	# Set both and return
	my $changed = $self->clone;
	$changed->{URI}->path( $uri );
	$changed->{path} = $fs;

	$changed;
}





#####################################################################
# Additional Overload Methods

sub __eq {
	my $left  = UNIVERSAL::isa(ref $_[0], 'HTML::Location') ? shift : return '';
	my $right = UNIVERSAL::isa(ref $_[0], 'HTML::Location') ? shift : return '';
	($left->path eq $right->path) and ($left->uri eq $right->uri);
}





#####################################################################
# Coercion Support

sub __as_URI { shift->URI }

1;

=pod

=head1 TO DO

Add more File::Spec-y methods as needed. Ask if you need one.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Location>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
