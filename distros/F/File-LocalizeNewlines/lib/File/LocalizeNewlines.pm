package File::LocalizeNewlines;

=pod

=head1 NAME

File::LocalizeNewlines - Localize the newlines for one or more files

=head1 DESCRIPTION

For people that routinely work with a mixture of different platforms
that have conflicting newline formats (mainly *NIX and Win32) there
are a number of different situations that can result in files having
their newlines get corrupted.

File::LocalizeNewlines provides a mechanism for one off or bulk
detection and conversion of these files to the newline style for the
local platform.

The module implements the conversion using a standard "universal line
seperator" regex, which ensures that files with any of the different
newlines, plus a couple of common "broken" newlines, including
multiple different types mixed in the same file, are all converted to
the local platform's newline style.

=head1 METHODS

=cut

use 5.005;
use strict;
use File::Spec       0.80 ();
use File::Find::Rule 0.20 ();
use File::Slurp   9999.04 ();
use Class::Default    1.0 ();
use FileHandle          0 ();
use Params::Util     0.10 '_INSTANCE';

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.12';
	@ISA     = 'Class::Default';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new param => value, ...

The C<new> constructor creates a new conversion object.

By default, the conversion object will process all files and convert
them to the local platform's newline format.

Takes some optional parameters

=over

=item filter =E<gt> File::Find::Rule

The C<filter> param allows you to provide an instantiate
L<File::Find::Rule> object, that will used to determine the list of
files to check or process.

=item newline =E<gt> $newline

The C<newline> option allows you to provide an alternative newline
format to the local one. The newline format should be provided as a
literal string.

For example, to force Win32 newlines, you would use 

  my $Object = File::LocalizeNewlines->new( newline => "\015\012" );

=item verbose =E<gt> 1

The C<verbose> option will cause the C<File::LocalizeNewlines> object to
print status information to C<STDOUT> as it runs.

=back

Returns a new C<File::LocalizeNewlines> object.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my %args  = @_;

	# Create the basic object
	my $self = bless { }, $class;

	# Check the file filter
	if ( _INSTANCE($args{filter}, 'File::Find::Rule') ) {
		$self->{Find} = $args{filter};
		$self->{Find}->file->relative;
	}

	# Allow for a custom platform
	$self->{newline} = $args{newline} if $args{newline};

	# Check the verbose mode
	if ( _CAN($args{verbose}, 'print') ) {
		$self->{verbose} = $args{verbose};
	} elsif ( $args{verbose} ) {
		$self->{verbose} = 1;
	}

	$self;
}

=pod

=head2 Find

The C<Find> accessor returns the L<File::Find::Rule> object that will be
used for the file search.

=cut

sub Find {
	my $self = $_[0]->_self;
	$self->{Find} or File::Find::Rule->file->relative;
}

=pod

=head2 newline

The C<newline> accessor returns the newline format that will be used in
the localisation process.

=cut

sub newline {
	$_[0]->_self->{newline} or "\n";
}





#####################################################################
# Methods

=pod

=head2 localized $file

The C<localized> method takes an argument of a single file name or
file handle and tests it to see it is localized correctly.

Returns true if localized correctly, false if not, or C<undef> on error.

=cut

sub localized {
	my $self      = shift->_self;
	my $file      = (defined $_[0] and ref $_[0]) ? shift
	              : (defined $_[0] and  -f $_[0]) ? shift
	              : return undef;
	my $newline   = $self->newline;
	my $content   = File::Slurp::read_file( $file );

	# Create the localized version of the file
	my $localized = $content;
	$localized =~ s/(?:\015{1,2}\012|\015|\012)/$newline/sg;

	$localized eq $content;
}

=pod

=head2 find $dir

The C<find> method takes the path for a dir (or file) and returns a list
of relative files names for all of the files that do B<not> have their
newlines correctly localized.

Returns a list of file names, or the null list if there are no files,
or if an incorrect path was provided.

=cut

sub find {
	my $self = shift->_self;
	my $path = _DIRECTORY(shift) or return ();

	# Find all the files to test
	my @files = $self->Find->in( $path );
	@files = grep {
		! $self->localized(
			File::Spec->catfile( $path, $_ )
			)
		} @files;

	@files;
}

=pod

=head2 localize $file | $dir

The C<localize> method takes a file, file handle or directory as argument 
and localizes the newlines of the file, or all files within the directory 
(that match the filter if one was provided).

Returns the number of files that were localized, zero if no files needed to
be localized, or C<undef> on error.

=cut

sub localize {
	my $self = shift->_self;
	my $path = (defined $_[0] and ref $_[0]) ? shift
	         : (defined $_[0] and  -e $_[0]) ? shift
	         : return undef;

	# Switch on file or dir
	(-f $path or ref $_[0])
		? $self->_localize_file( $path )
		: $self->_localize_dir( $path );
}

sub _localize_dir {
	my $self = shift->_self;
	my $path = _DIRECTORY(shift) or return undef;

	# Find the files to localise
	my @files = $self->Find->in( $path );

	# Localize the files
	my $count   = 0;
	my $newline = $self->newline;
	foreach ( @files ) {
		my $file      = File::Spec->catfile( $path, $_ );
		my $content   = File::Slurp::read_file( $file );
		my $localized = $content;
		$localized =~ s/(?:\015{1,2}\012|\015|\012)/$newline/sg;
		next if $localized eq $content;
		File::Slurp::write_file( $file, $localized ) or return undef;
		$self->_message( "Localized $file\n" );
		$count++;
	}

	$count;
}

sub _localize_file {
	my $self = shift->_self;
	my $file = (defined $_[0] and ref $_[0]) ? shift
	         : (defined $_[0] and  -f $_[0]) ? shift
	         : return undef;

	# Does the file need to be localised
	my $newline   = $self->newline;
	my $content   = File::Slurp::read_file( $file );
	my $localized = $content;
	$localized =~ s/(?:\015{1,2}\012|\015|\012)/$newline/sg;
	return 0 if $content eq $localized;

	# Save the localised version
	File::Slurp::write_file( $file, $localized ) or return undef;
	$self->_message( "Localized $file\n" ) unless ref $file;

	1;
}

sub _message {
	my $self = shift;
	return 1 unless defined $self->{verbose};
	my $message = shift;
	$message .= "\n" unless $message =~ /\n$/;
	if ( _CAN( $self->{verbose}, 'print' ) ) {
		$self->{verbose}->print( $message );
	} else {
		print STDOUT $message;
	}
}

sub _CAN {
	(_INSTANCE($_[0], 'UNIVERSAL') and $_[0]->can($_[1])) ? shift : undef;
}

sub _DIRECTORY {
	(defined $_[0] and -d $_[0]) ? shift : undef;
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-LocalizeNewlines>

For other issues, contact the maintainer.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the open sourcing and release of this distribution.

L<FileHandle> support added by David Dick E<lt>ddick@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
