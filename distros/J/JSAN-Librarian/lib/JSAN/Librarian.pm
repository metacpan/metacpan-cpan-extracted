package JSAN::Librarian;

=pod

=head1 NAME

JSAN::Librarian - JavaScript::Librarian adapter for a JSAN installation

=head1 DESCRIPTION

L<JavaScript::Librarian> works on the concept of "libraries" of JavaScript
files each of which may depend on other files to be loaded before them.

C<JSAN::Librarian> provides a mechanism for detecting and indexing a
L<JavaScript::Librarian::Library> object for a L<JSAN> installation.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp                     ();
use File::Spec               ();
use File::Path               ();
use Config::Tiny             ();
use Params::Util             qw{ _STRING };
use File::Basename           ();
use File::Find::Rule         ();
use JSAN::Parse::FileDeps    ();
use JSAN::Librarian::Book    ();
use JSAN::Librarian::Library ();

use vars qw{$VERSION $VERBOSE @DEFAULT};
BEGIN {
	$VERSION = '0.03';

	# Silent by default
	$VERBOSE ||= 0;

	# Look for the index at existing places.
	# If none found, assume the first.
	@DEFAULT = qw{
		openjsan.deps
		.openjsan.deps
	};
}





#####################################################################
# Constructor

=pod

=head2 new $path, $index

The C<new> constructor creates a new C<JSAN::Librarian> object for a
JSAN installation library/prefix located at a local directory.

Because a JSAN installation library does not have a definitive method
by which its existance can be verified, at this time the only check
actually made is that the directory exists.

An optional second parameter can be provided, which will be taken to
be the location of the index file. Relative paths will be interpreted
as being relative to the root path passed as the first param.

Note: As long as the root path exists, a new C<JSAN::Librarian> object
will be created whether index file exists or not.

Returns a new C<JSAN::Librarian> object, or undef if the directory
does not exist.

=cut

sub new {
	my $class      = shift;
	my $root       = (defined _STRING($_[0]) and -d $_[0]) ? shift : return undef;

	# Create the object
	my $self = bless {
		root => $root,
	}, $class;

	# Check passed index file or use a default
	$self->{index_file} = @_
		? $self->_new_param(shift)
		: $self->_new_default
		or return undef;

	return $self;
}

# Check index file param
sub _new_param {
	my $self  = shift;
	my $param = shift or return undef;
	return "$param";
}

# Determine default
sub _new_default {
	my $self = shift;
	my $root = $self->root;

	# Does it have an existing index
	foreach my $file ( @DEFAULT ) {
		my $path = File::Spec->catfile( $root, $file );
		next unless -f $path;
		$self->_print("Found index at $path");
		return $file;
	}

	# It doesn't exist, but use the primary default
	my $path = File::Spec->catfile( $root, $DEFAULT[0] );
	$self->_print("Using default path $DEFAULT[0]");
	return $DEFAULT[0];
}

=pod

=head2 root

The C<root> accessor returns the root path of the installed JSAN library.

=cut

sub root {
	$_[0]->{root};
}

=pod

=head2 index_file

The C<index_file> accessor returns the location of index file, as
provided to the constructor (or the default), which may be a path
relative to the root.

=cut

sub index_file {
	$_[0]->{index_file};
}





#####################################################################
# JSAN::Librarian Methods

=pod

=head2 index_path

The C<index_path> method returns the path to the index file,
with relative file locations converted to the full path
relative to the root.

=cut

sub index_path {
	my $self = shift;
	my $file = $self->index_file;
	return File::Spec->file_name_is_absolute($file)
		? $file
		: File::Spec->catfile( $self->root, $file );
}

=pod

=head2 index_exists

The C<index_exists> method checks to see if the index file exists.

Returns true if the index file exists, or false if not.

=cut

sub index_exists {
	return -f $_[0]->index_path;
}

=pod

=head2 build_index $lib

The C<build_index> method scans the library to find all perl-file
dependencies and builds them into an index object.

Returns a L<Config::Tiny> object, or throws an exception on error.

=cut

sub build_index {
	my $self   = shift;
	my $config = Config::Tiny->new;
	my $root   = $self->root;

	# Find all the files
	$self->_print("Searching $root for .js files...");
	my @files = File::Find::Rule->name('*.js')
	                            ->not_name(qr/_deps\.js$/)
	                            ->file
                                    ->relative
	                            ->in( $root );
	foreach my $js ( @files ) {
		$config->{$js} = {};
		my $path = File::Spec->catfile( $root, $js );
		$self->_print("Scanning $js");
		my @deps = JSAN::Parse::FileDeps->file_deps( $path );
		foreach ( @deps ) {
			$config->{$js}->{$_} = 1;
		}
	}

	return $config;
}

=pod

=head2 make_index

The C<make_index> static method scans the installed L<JSAN> tree and
creates an index file (written from a L<Config::Tiny> object) containing
the file-level dependency information.

Returns true on success, or throws an exception on error.

=cut

sub make_index {
	my $self = shift;
	my $path = $self->index_path;

	# Make sure the output path exists
	if ( -e $path ) {
		-w $path or Carp::croak(
			"Insufficient permissions to change index file '$path'"
			);
	} else {
		my $dir = File::Basename::dirname( $path );
		unless ( -d $dir ) {
			eval { File::Path::mkpath( $dir, $VERBOSE ); };
			Carp::croak("$!: Failed to mkdir '$dir' for JSAN::Librarian index file") if $@;
		}
	}

	# Generate the Config::Tiny object
	my $config = $self->build_index( $self->root );

	# Save the index file
	$self->_print("Saving $path");
	$config->write( $path ) or Carp::croak(
		"Failed to write JSAN::Librarian index file '$path'"
	);
}

=pod

=head2 library

The C<library> method creates and returns a L<JSAN::Librarian::Library>
for the installed L<JSAN> library.

If an index file exists, the pre-built index in the file will be used.

If there is no index file, the installed JSAN library will be scanned
and an index built in-memory as needed.

Returns a new L<JSAN::Librarian::Library>, or throws an exception
on error.

=cut

sub library {
	my $self = shift;
	my $from = $self->index_exists
		? $self->index_path
		: $self->build_index;
	return JSAN::Librarian::Library->new( $from );
}





#####################################################################
# Coercion Support

sub __as_JSAN_Librarian_Library       { shift->library }
sub __as_JavaScript_Librarian_Library { shift->library }
sub __as_Algorithm_Dependency_Source  { shift->library }





#####################################################################
# Support Methods

sub _print {
	my $msg = shift;
	$msg =~ s/\n*/\n/g;
	print $msg if $VERBOSE;
	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSAN-Librarian>

For other issues, contact the maintainer.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
