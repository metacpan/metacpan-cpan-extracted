package JavaScript::Librarian;

=pod

=head1 NAME

JavaScript::Librarian - Load and use libraries of JavaScript packages

=head1 DESCRIPTION

C<JavaScript::Librarian> is a package for loading and using "libraries"
of JavaScript packages, managing dependencies between the files, and
generating fragments of HTML with the E<lt>scriptE<gt> tags to load them
in the correct order.

=head1 STATUS

This is an early release, and while it implements the core object and
logic, this package does not yet come with any
L<Library|JavaScript::Librarian::Library> sub-classes capable of loading
the required metadata from anything.

This will be dealth with in a seperate package, or in a future version
of this one. For the moment consider it something you can use to build
your own modules. See the source code for more documentation.

=cut

use strict;
use URI                            ();
use Clone                          ();
use File::Spec::Unix               ();
use Algorithm::Dependency::Ordered ();
use JavaScript::Librarian::Book    ();
use JavaScript::Librarian::Library ();
use Params::Coerce '_URI'     => 'URI';
use Params::Coerce '_Library' => 'JavaScript::Librarian::Library';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.00';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class    = ref $_[0] ? ref shift : shift;
	my %args     = @_;
	my $base     = $class->_URI($args{base})        or return undef;
	my $library  = $class->_Library($args{library}) or return undef;

	# Create the dependency resolver
	my $resolver = Algorithm::Dependency::Ordered->new(
		source         => $library,
		ignore_orphans => 1,
		) or return undef;

	# Create the basic object
	my $self = bless {
		base     => $base,
		library  => $library,
		resolver => $resolver,
		selected => {},
		}, $class;

	# Add any packages to select passed to the constructor
	if ( ref $args{select} eq 'ARRAY' ) {
		foreach my $book ( @{$args{select}} ) {
			$self->select( $_ ) or return undef;
		}
	}

	$self;
}

sub base {
	Clone::clone $_[0]->{base};
}

sub library {
	$_[0]->{library};
}

sub resolver {
	$_[0]->{resolver};
}






#####################################################################
# Main Methods

# Select a package we need
sub add {
	my $self = shift;
	my $book = $self->library->item($_[0]) ? shift : return undef;
	$self->{selected}->{$book} = 1;
}

# Find the schedule for the currently selected items
sub schedule {
	my $self = shift;
	$self->resolver->schedule( sort keys %{$self->{selected}} );
}

# Get the list of paths of JavaScript files to load
sub paths {
	my $self     = shift;
	my $schedule = $self->schedule or return undef;
	my $library  = $self->library;

	# Map to file names
	my @paths = map { $library->item($_)->path } @$schedule;

	# Move them under the base URI
	@paths = map { $self->_path_URI($_) } @paths;

	\@paths;
}

# Generate a URI relative to the base, but without the assumption that
# the base URI is absolute.
sub _path_URI {
	my $self = shift;
	my $URI  = $self->base;
	my $path = File::Spec::Unix->catfile( $URI->path, @_ );
	$URI->path( $path );
	$URI;
}

# Generates a string of HTML to load the books
sub html {
	my $self  = shift;
	my $paths = $self->paths or return undef;
	join "\n", map {
		qq~<script language="JavaScript" src="$_" type="text/javascript"></script>~
		} @$paths;
}

# XHTML version of the above...?
sub xhtml {
	''; ### FIXME - Finish this
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JavaScript-Librarian>

For other issues, contact the maintainer

=head1 AUTHORS

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
