package JSAN::Parse::FileDeps;

=pod

=head1 NAME

JSAN::Parse::FileDeps - Parse file-level dependencies from JSAN modules

=head1 DESCRIPTION

As in Perl, two types of dependencies exist in L<JSAN>. Distribution-level
install-time dependencies, and run-time file-level dependencies.

Because JSAN modules aren't explicitly required to provide the file-level
dependencies, this package was created to provide a single common module
by which to determine what these dependencies are, so that all processes
at all stages of the JSAN module lifecycle will have a common understanding
of the dependencies that a file has, and provide certainty for the
module developer.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp           ();
use File::Spec     ();
use File::Basename ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.00';
}

my $SEPERATOR = qr/__CODE__/;
my $LIB_DEP   = qr/^\s*JSAN\.use\s*\(\s*(?:"([\w\.]+)"|'([\w\.]+)')\s*(?:\,|\))/;






#####################################################################
# JSAN::Parse::FileDeps Static Methods

=pod

=head2 library_deps $file

The C<library_deps> method finds a list of all the libary dependencies for
a given file, where a library is specified in the form C<"Foo.Bar">
(using the pseudo-namespaces common to JSAN).

Returns a list of libraries, or throws an exception on error.

=cut

sub library_deps {
	my $class     = shift;
	my @head      = $class->find_deps_js(@_);
	my %libraries = ();
	foreach my $line ( @head ) {
		if ( $line =~ /$LIB_DEP/ ) {
			my $library = $1 || $2;
			$libraries{$library} = 1;
		}
	}
	return sort keys %libraries;
}

=pod

=head2 file_deps $file

The C<library_deps> method finds a list of all the file dependencies for
a given file, where a file is specified in the form C<"Foo/Bar.js">
(that is, relative to the root of the lib path for the modules).

The list is identical to, and is calculated from, the list of libraries
returned by C<library_deps>.

Returns a list of local filesytem relative paths, or throws an exception
on error.

=cut

sub file_deps {
	my $class     = shift;
	my @libraries = $class->library_deps(shift);
	my @files     = ();
	foreach my $library ( @libraries ) {
		push @files, File::Spec->catfile( split /\./, $library ) . '.js';
	}
	return @files;
}

=pod

=head2 find_deps_js $file

The C<find_deps_js> method is used to extract the header content from a file,
to be searched for dependencies, and potentially written to a C<module_deps.js>
file.

Returns the content as a list of lines, or throws an exception on error.

=cut

sub find_deps_js {
	my $class = shift;
	my $input = defined $_[0] ? shift
		: Carp::croak("No input file provided to ->find_deps_js");

	# Load the file	
	open( INFILE, '<', $input )
		or Carp::croak("Failed to open $input for reading: $!");

	# Isolate the head content
	my @lines = ();
	while ( <INFILE> ) {
		last if /$SEPERATOR/;
		push @lines, $_;
	}
	close INFILE;

	# Return the header lines
	@lines;
}

=pod

=head2 make_deps_js $file

The C<make_deps_js> method takes a JSAN module filename in the form
C<"foo/bar.js"> and extracts the dependency header, writing it to
C<"foo/bar_deps.js">.

Returns true on success, or throws an exception on error.

=cut

sub make_deps_js {
	my $class = shift;

	# Get the header contents
	my $input = shift;
	my @head  = $class->find_deps_js($input);
	
	# Work out what file to write to
	my ($file, $dir, $ext) = File::Basename::fileparse( $input, qr/\..*/ );
	my $output = File::Spec->catfile( $dir, $file . '_deps' . $ext );

	# Write the header to it
	open( OUTFILE, '>', $output )
		or Carp::croak("Failed to open $output for writing: $!");
	foreach my $line ( @head ) {
		print OUTFILE $line
			or Carp::croak("Error writing to $output: $!");
	}
	close OUTFILE;

	1;
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSAN-Parse-FileDeps>

For other issues, contact the maintainer

=head1 AUTHORS

Completed and maintained by Adam Kennedy <cpan@ali.as>, L<http://ali.as/>

Original written by Rob Kinyon <rob.kinyon@iinteractive.com>

=head1 COPYRIGHT

Copyright 2005, 2006 Rob Kinyon and Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
