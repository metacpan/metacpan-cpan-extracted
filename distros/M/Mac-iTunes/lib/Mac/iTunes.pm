package Mac::iTunes;
use strict;
use warnings;

use base qw(Exporter);
use vars qw($VERSION);

use Carp qw(carp);
use Mac::iTunes::Item;
use Mac::iTunes::Playlist;

require Exporter;

$VERSION = '1.23';

=head1 NAME

Mac::iTunes - interact with and control iTunes

=head1 SYNOPSIS

	use Mac::iTunes;

	# if you have Mac::iTunes::AppleScript
	my $controller = Mac::iTunes->controller();

	my $library = Mac::iTunes->new( $library_path );

=head1 DESCRIPTION

**This module is unmaintained**

=head2 METHODS

=over 4

=item new()

Creates a new, empty Mac::iTunes object.  If you want to read a
current library, use read().

Returns false on failure.

=cut

sub new
	{
	my $class = shift;

	my $self = {
		_playlists => {},
		};

	bless $self, $class;

	return $self;
	}

=item controller()

Creates a new Mac::iTunes controller object.  See L<Mac::iTunes::AppleScript>
for methods.  This method is not available on non-Mac systems.

=cut

sub controller
	{
	my $class = shift;

	my $self = {};

	eval "use Mac::iTunes::AppleScript";

	if( $@ )
		{
		carp "You need Mac::iTunes::AppleScript to use an iTunes controller";
		return;
		}

	return Mac::iTunes::AppleScript->new();
	}

=item preferences( [ FILENAME ] )

Read the iTunes preferences from the given FILENAME, or the file
~/Library/Preferences/com.apple.iTunes.plist .

=cut

sub preferences
	{
	my $class    = shift;
	my $filename = shift;

	$filename = "$ENV{HOME}/Library/Preferences/com.apple.iTunes.plist"
		unless defined $filename;

	require Mac::iTunes::Preferences;

	Mac::iTunes::Preferences->parse_file( $filename );
	}

=item playlists

In list context, returns a list of the titles of the playlists.
In scalar context, returns the number of playlists.

=cut

sub playlists
	{
	my $self = shift;

	my @playlists = keys %{ $self->{_playlists} };

	return wantarray ? @playlists : scalar @playlists;
	}

=item get_playlist( PLAYLIST )

Takes a playlist title argument.

Extracts a Mac::Playlist object from the music library.  Returns
undef if the playlist does not exist.

=cut

sub get_playlist
	{
	my $self = shift;
	my $name = shift;

	return unless $self->playlist_exists($name);

	my $playlist = $self->{_playlists}{$name};

	return $playlist;
	}

=item add_playlist( PLAYLIST_OBJECT )

Takes a Mac::iTunes::Playlist object as its only argument.

Adds the playlist to the music library and returns a true
value.  If it cannot add the playlist object, perhaps because
it is not a playlist object, it returns undef.

=cut

sub add_playlist
	{
	my $self     = shift;
	my $playlist = shift;

	return unless defined $playlist;

	return unless(
		ref $playlist and $playlist->isa( 'Mac::iTunes::Playlist' ) );

	my $title = $playlist->title;

	return if $self->playlist_exists( $title );

	$self->{_playlists}{$title} = $playlist;

	return 1;
	}

=item delete_playlist( PLAYLIST | OBJECT )

Takes a playlist title or Mac::iTunes::Playlist object as
an argument.

Removes the playlist from the music library.

=cut

sub delete_playlist
	{
	my $self  = shift;
	my $title = shift;

	return unless $self->playlist_exists( $title );

	if( ref $title )
		{
		return unless $title->isa( 'Mac::iTunes::Playlist' );

		$title = $title->title;
		}

	delete ${ $self->{_playlists} }{$title};
	}

=item playlist_exists( PLAYLIST | OBJECT )

Takes a playlist title or Mac::iTunes::Playlist object as
an argument.

Returns true if the playlist exists in the music library, and false
otherwise.

The playlist exists if the music library has a playlist with
the same title, or if the object matches another object in
the music library.  See Mac::iTunes::Playlist to see how
one playlist object may match another.

NOTE:  at the moment, if you use an object argument, the
function extracts the title of the playlist and sees if that
title is in the library.  this is just a placeholder until i
come up with something better.

=cut

sub playlist_exists
	{
	my $self  = shift;
	my $title = shift;

	if( ref $title )
		{
		return unless $title->isa('Mac::iTunes::Playlist');

		# XXX: this is a start - just grab the title
		$title = $title->title;
		}

	return exists ${ $self->{_playlists} }{ $title };
	}

=item read( FILENAME )

*** NOTE: This does not work for iTunes 4.6 and later, which has
a different file format. Can anyone help me figure out what that
format is? ***

Reads the named iTunes Music Library file and uses it to form the
music library object, replacing any other data already in the
object.

=cut

sub read
	{
	my $self = shift;
	my $file = shift;

	return unless open my( $fh ), $file;

	require Mac::iTunes::Library::Parse;

	Mac::iTunes::Library::Parse->parse( $fh );
	}

=item merge( FILENAME | OBJECT )

UNIMPLEMENTED!

Merges the current music library with the one in the named file
or Mac::iTunes object.  Does not affect the object argument.

=cut

sub merge
	{
	my $self = shift;

	$self->_not_implemented;
	}

=item write

UNIMPLEMENTED!  Just dumps it with Data::Dumper.

Returns the music library as a string suitable for an iTunes
Music Object file.

=cut

sub write
	{
	my $self = shift;

	require Data::Dumper;

	Data::Dumper::Dumper( $self );
	}

sub _not_implemented
	{
	require Carp;

	my $function = (caller(1))[3];

	Carp::croak( "$function is unimplemented" );
	}

=back

=head1 TO DO

* everything - the list of things already done is much shorter.

* speed everything up 100 times with Mac::Glue when it works on
Mac OS X

* Figure out the new file format for the binary library file

=head1 BUGS

* plenty

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/CPAN-Adopt-Me/MacOSX-iTunes.git

=head1 AUTHOR

brian d foy,  C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2008 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

"See why 1984 won't be like 1984";
