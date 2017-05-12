package File::PathList;

=pod

=head1 NAME

File::PathList - Find a file within a set of paths (like @INC or Java classpaths)

=head1 SYNOPSIS

  # Create a basic pathset
  my $inc  = File::PathList->new( \@INC );
  
  # Again, but with more explicit params
  my $inc2 = File::PathList->new(
  	paths => \@INC,
  	cache => 1,
  	);
  
  # Get the full (localised) path for a unix-style relative path
  my $file = "foo/bar/baz.txt";
  my $path = $inc->find_file( $file );
  
  if ( $path ) {
      print "Found '$file' at '$path'\n";
  } else {
      print "Failed to find '$file'\n";
  }

=head1 DESCRIPTION

Many systems that map generic relative paths to absolute paths do so with a
set of base paths.

For example, perl itself when loading classes first turn a C<Class::Name>
into a path like C<Class/Name.pm>, and thens looks through each element of
C<@INC> to find the actual file.

To aid in portability, all relative paths are provided as unix-style
relative paths, and converted to the localised version in the process of
looking up the path.

=head1 EXTENDING

The recommended method for extending C<File::PathList> is to add additional
topic-specific find methods.

For example, a subclass that was attempting to duplicate the functionality
of perl's C<@INC> and module location may wish to add a C<find_module>
method.

=head1 METHODS

=cut

use 5.005;
use strict;
use File::Spec       ();
use File::Spec::Unix ();
use Params::Util     qw{_ARRAY _CODE};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.04';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new \@path | param => $value, ...

The C<new> constructor creates a new C<File::PathList>.

It takes the following options as key/value pairs.

=over 4

=item paths

The compulsory C<paths> param should be a reference to an C<ARRAY> of local
filesystem paths.

=item cache

If the optional C<cache> param is set to true, the object will internally
cache the results of the file lookups. (false by default)

=back

If the C<new> contructor is provided only a single param, this will be
take to mean C<paths => $param>.

Returns a new C<File::PathList> object, or C<undef> if a valid path set
was not provided.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	# Handle the one argument shorthand case
	my %params = (@_ == 1)
		? (paths => shift)
		: @_;

	# Check the paths
	_ARRAY($params{paths}) or return undef;

	# Create the basic object
	my $self = bless {
		paths => [ @{$params{paths}} ],
		# code  => !! $params{code},
		$params{cache}
			? ( cache => {} )
			: (),
		}, $class;

	# Make sure there are no CODE refs if we can't have them
	# unless ( $self->code ) {
		if ( grep { _CODE($_[0]) } $self->paths ) {
			return undef;
		}
	# }

	$self;
}

=pod

=head2 paths

The C<paths> accessor returns the list of paths use to create the
C<File::PathList> object.

Returns a list of localised path strings.

=cut

sub paths { @{$_[0]->{paths}} }

=pod

=head2 cache

The C<cache> accessor indicates whether or not the C<File::PathList> object
is caching the results of the file lookups.

=cut

sub cache { exists $_[0]->{cache} }





#####################################################################
# File::PathList Methods

=pod

=head2 find_file $unix_path

The C<find_file> method takes a unix-style relative file path, and
iterates through the list of paths, checking for the file in it.

Returns the full path to the file, the false null string C<''> if the file
could not be found, or C<undef> if passed a bad file name.

=cut

sub find_file {
	my ($self, $rel) = @_;

	# Check the file name is valid
	defined $rel and ! ref $rel and length $rel    or return undef;
	File::Spec::Unix->no_upwards($rel)             or return undef;
	File::Spec::Unix->file_name_is_absolute($rel) and return undef;

	# Is it in the cache?
	if ( $self->{cache} and exists $self->{cache}->{$rel} ) {
		return $self->{cache}->{$rel};
	}

	# Split up the filename into parts
	my (undef, $dir, $file) = File::Spec::Unix->splitpath($rel);
	my @parts = ( File::Spec::Unix->splitdir( $dir ), $file );

	# File name cannot contain upwards parts
	if ( @parts != File::Spec::Unix->no_upwards(@parts) ) {
		return undef;
	}

	# Attempt to locate the file in each path
	foreach my $inc ( $self->paths ) {
		my $path = File::Spec->catfile( $inc, @parts );
		next unless -f $path;

		# Cache if needed
		if ( $self->{cache} ) {
			$self->{cache}->{$rel} = $path;
		}

		return $path;
	}

	# File not found
	'';
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-PathList>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the open sourcing and release of this distribution.

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
