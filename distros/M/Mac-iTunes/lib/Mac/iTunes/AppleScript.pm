package Mac::iTunes::AppleScript;
use strict;
use warnings;

use base qw(Exporter);
use vars qw($AUTOLOAD @EXPORT_OK %EXPORT_TAGS $VERSION);

use Carp qw(carp);
use File::Spec;
use Mac::AppleScript qw(RunAppleScript);
use Mac::Path::Util;

$VERSION = '1.23';

my $Singleton = undef;
@EXPORT_OK = qw(TRUE FALSE PLAYING STOPPED PAUSED SMALL MEDIUM LARGE);
%EXPORT_TAGS = (
	boolean => [ qw(TRUE FALSE) ],
	state   => [ qw(PLAYING STOPPED PAUSED) ],
	size    => [ qw(SMALL MEDIUM LARGE) ],
	);

use constant STOPPED          => 'stopped';
use constant PLAYING          => 'playing';
#use constant PAUSED           => 'paused';
use constant PAUSED           => 'stopped';
use constant FAST_FORWARDING  => 'fast forwarding';
use constant REWINDING        => 'rewinding';

=head1 NAME

Mac::iTunes::AppleScript - control iTunes from Perl

=head1 SYNOPSIS

	use Mac::iTunes;

	my $itunes = Mac::iTunes->controller;

	$itunes->activate;
	$itunes->play;
	$itunes->quit;

=head1 DESCRIPTION

**This module is unmaintained**

=head2 Methods

=over 4

=cut

# %Tell holds simple methods for AUTOLOAD
my %Tell = (
	map( { $_, $_ }
		qw(activate run play pause quit playpause resume rewind stop) ),
	map( { my $x = $_; $x =~ tr/_/ /; ( $_, $x ) }
		qw(fast_forward back_track next_track previous_track) )
		);
@Tell{ qw(next previous redo) } =
	@Tell{ qw(next_track previous_track back_track) };

my %Properties = (
	map( { $_, $_ }
		qw(mute version volume) ),
	map( { my $x = $_; $x =~ tr/_/ /; ( $_, $x ) }
		qw(sound_volume player_state player_position
		EQ_enabled fixed_indexing current_visual
		visuals_enabled visual_size full_screen
		current_encoder frontmost) )
		);

@Properties{ qw(volume state position) } =
	@Properties{ qw(sound_volume player_state player_position) };

my %Track_properties = ( map( { $_, 1 } qw( album artist comment composer
	duration genre rating year compilation enabled EQ finish
	kind size start time name) ),
	map( { my $x = $_; $x =~ tr/_/ /; ( $_, $x ) }
		qw(bit_rate database_ID date_added disc_count disc_number
		modification date played_count played_date rating sample_rate
		track_count track_number volume_adjustment) )
		);

my %Which_track = map { $_, 1 } qw( current );

use constant TRUE   => 'true';
use constant FALSE  => 'false';
use constant SMALL  => 'small';
use constant MEDIUM => 'medium';
use constant LARGE  => 'large';

my %Boolean = map { $_, 1 } qw(mute EQ_enabled fixed_indexing
	visuals_enabled full_screen front_most);

my %Validate = (
	boolean      => \&_validate_boolean,
	volume       => \&_validate_volume,
	sound_volume => \&_validate_volume,
	);

sub _validate_boolean { ( $_[0] and $_[0] ne FALSE ) ? TRUE : FALSE }
sub _validate_volume
	{
	# for some reason iTunes sets the volume to
	# one less
	my $volume = do {
		   if( $_[0] > 100 ) { 101       }
		elsif( $_[0] <=  0 ) {   1       }
		else                 { $_[0] + 1 }
		};
	}

sub AUTOLOAD
	{
	my $self   = shift;
	my $value  = shift;

	my $method = $AUTOLOAD;

	$method =~ s/.*:://g;

	if( exists $Tell{ $method } )
		{
		$self->tell( $Tell{ $method } );
		}
	elsif( exists $Properties{ $method } and defined $value )
		{
		my $valid_value = do {
			if( exists $Boolean{$method} )
				{
				$Validate{'boolean'}->($value);
				}
			elsif( exists $Validate{$method} )
				{
				$Validate{$method}->($value);
				}
			else { $value }
			};

		$self->_set_value( $Properties{ $method }, $valid_value );
		}
	elsif( exists $Properties{ $method } )
		{
		$self->_get_value( $Properties{ $method } );
		}
	elsif( $method =~ m/(.*?)_track_(.*)/ and
		exists $Track_properties{ $2 } and exists $Which_track{ $1 } )
		{
		$self->_track( $2, $1 );
		}
	else
		{
		carp "I didn't know what to do with [$method] [$1] [$2]";
		return;
		}

	}

=item new()

Returns a singleton object that can control iTunes.

=cut

sub new
	{
	my $class = shift;

	unless( defined $Singleton )
		{
		$Singleton = bless {}, $class;
		}

	return $Singleton;
	}

=item play

Start playing the current selection

=item pause

Pause playback.

=item playpause

Toggle the play-pause button.  If it's on play, it will pause, and
if it's on pause, it will play.

=item next, next_track

Skip to the next track

=item previous, previous_track

Skip to the previous track

=item redo, back_track

Go back to the start of the current track

=item stop

Stop playback.

=item fast_forward

Fast forward through the current selection.

=item rewind

Rewind through the current selection.

=item resume

Start playing after fast forward or rewind

=item quit

Quit iTunes

=item open_url( URL )

Open an item from the given URL

=cut

sub open_url
	{
	my $self = shift;
	my $url  = shift;

	$self->tell( qq|open location "$url"| );
	}

=back

=head2 Methods for tracks

=over

=cut

sub _track
	{
	my $self  = shift;
	my $name  = shift;
	my $which = shift;

	my $result = $self->tell( "return $name of $which track" );

	# the current track means the one playing, so if one isn't
	# playing, the applescript command succeeds and tell() returns
	# 1, but there is no data.
	return if( $result eq '1' and $self->state eq STOPPED );

	# print STDERR "Result is $result";

	$result;
	}

=item current_track_name

=cut

=item add_track( FILE, PLAYLIST_NAME )

Add the unix style path FILE to the user playlist with
name PLAYLIST_NAME.  Relative paths are resolved according
to the current working directory.

	add_track( 'mp3/song.mp3', 'Favorites' )

This function will create the playlist if it does not exist.

This function does not check if the track already exists in
the playlist.  If it does, you end up with duplicates.

=cut

sub _get_mac_path
	{
	my $self = shift;
	my $file = shift;

	my $path = File::Spec->rel2abs( $file );
	return unless -e $path;

	my $util = Mac::Path::Util->new( $path );
	#$util->use_applescript(1); XXX: what is this?

	my $mac_path = $util->mac_path;

	return $mac_path;
	}

sub add_track($$$)
	{
	my $self     = shift;
	my $file     = shift;
	my $playlist = shift;

	my $mac_path = $self->_get_mac_path( $file );
	return unless defined $mac_path;

	my $exists = $self->playlist_exists( $playlist );
	#print STDERR "Playlist exists is [$exists]";

	$self->add_playlist( $playlist ) unless $exists;

	$mac_path = $self->_escape_quotes( $mac_path );
	$playlist = $self->_escape_quotes( $playlist );

	my $script =<<"SCRIPT";
	set myName to alias "$mac_path"
	add myName to playlist "$playlist"
SCRIPT

	my $result = $self->tell( $script );
	}

=item track_file_exists

BROKEN!

Returns true if the file is already in the iTunes library.

The library actually stores aliases to the real files, so
I can't simply check the file names---very frustrating.

=cut

sub track_file_exists
	{
	my $self     = shift;
	my $file     = shift;

	my $mac_path = $self->_get_mac_path( $file );
	return unless defined $mac_path;
	}

=item get_track_at_position( POSITION [, PLAYLIST ] )

=cut

sub get_track_at_position($$;$)
	{
	my $self     = shift;
	my $position = shift;
	my $playlist = shift || $self->{_playlist};

	$playlist = $self->_escape_quotes( $playlist );

	my $script =<<"SCRIPT";
	return name of track $position of playlist "$playlist"
SCRIPT

	my $name = $self->tell( $script );
	}

=item play_track( POSITION, [, PLAYLIST ] )

=cut

sub play_track($$;$)
	{
	my $self     = shift;
	my $position = shift;
	my $playlist = shift || $self->{_playlist};

	$playlist = $self->_escape_quotes( $playlist );

	my $script =<<"SCRIPT";
	play track $position of playlist "$playlist"
SCRIPT

	my $name = $self->tell( $script );
	}

=item get_track_names_in_playlist( [ PLAYLIST ] )

Return an anonymous array of the names of the tracks in
playlist PLAYLIST.

Uses the currently set playlist if you don't specify
one.

=cut

sub get_track_names_in_playlist
	{
	my $self     = shift;
	my $playlist = shift || $self->{_playlist};

	$playlist = $self->_escape_quotes( $playlist );

	my $script =<<"SCRIPT";
	set myPlaylist to "$playlist"
	set myString to ""
	repeat with i from 1 to count of tracks in playlist myPlaylist
		set thisName to name of track i in playlist myPlaylist
		set myString to myString & thisName & return
	end repeat
	return myString
SCRIPT

	my $result = $self->tell( $script );

	my @list = split /\015/, $result;

	#local $" = " <-> ";
	#print STDERR "Found " . @list . " items [@list]\n";
	return \@list;
	}

=back

=head2 Methods for playlists

=over 4

=item get_playlists

Return an anonymous array of the names of the playlists.

=cut

sub get_playlists
	{
	my $self = shift;

	my $script =<<'SCRIPT';
	set myString to ""
	set myList to playlists
	repeat with i from 1 to count of myList
		set thisName to name of item i of myList
		set myString to myString & thisName & return
	end repeat
	return myString
SCRIPT

	my $result = $self->tell( $script );
#	print STDERR "Result is $result\n";

	my @list = split /\015/, $result;
#	local $" = " <-> ";
#	print STDERR "Found " . @list . " items [@list]\n";
	return \@list;
	}

=item set_playlist( NAME )

Set the current controller playlist.

Returns true if it succeeds, and false otherwise (for instance,
if the playlist does not exist.

=cut

sub set_playlist($$)
	{
	my $self = shift;
	my $name = shift;

	return unless $self->playlist_exists( $name );

	$self->{_playlist} = $name;
	}

=item add_playlist( NAME )

Add a playlist with the name NAME.  Any double-quotes
in NAME become single quotes.

=cut

sub add_playlist
	{
	my $self = shift;
	my $name = shift;

	$name = $self->_escape_quotes( $name );

	my $script =<<"SCRIPT";
	set myList to make new playlist
	set name of myList to "$name"
SCRIPT

	$self->tell( $script );
	}

=item delete_playlist( NAME )

Delete all playlists with the name NAME.

=cut

sub delete_playlist
	{
	my $self = shift;
	my $name = shift;

	$name = $self->_escape_quotes( $name );

	# we have to go backwards because iTunes renumbers playlists
	# as we delete them.  we can't delete multiple playlists
	# atomically.
	my $script =<<"SCRIPT";
	repeat with i from (the count of the playlists) to 1 by -1
		set this_playlist to playlist i
		try
			if the name of this_playlist is "$name" then
				delete playlist i
			end if
		end try
	end repeat
SCRIPT

	$self->tell( $script );
	}

=item playlist_exists( NAME )

Returns the number of playlists with name NAME.

=cut

sub playlist_exists
	{
	my $self = shift;
	my $name = shift;

	$name = $self->_escape_quotes( $name );

	my $script =<<"SCRIPT";
	set myCount to 0
	repeat with i from 1 to (the count of the playlists)
		set this_playlist to playlist i
		try
			if the name of this_playlist is "$name" then
				set myCount to myCount + 1
			end if
		end try
	end repeat

	return myCount
SCRIPT

	my $exists = $self->tell( $script );

	return $exists eq '1' ? 1 : 0;
	}

=back

=head2 Methods for windows

=over 4

=item browser_window_visible( [TRUE|FALSE] )

=item eq_window_visible( [TRUE|FALSE] )

Returns the value of the visible property of the window. A
window is visible if it is not minimized.

=cut

sub browser_window_visible
	{
	my $self   = shift;
	my $state  = shift;

	$self->_window_visible( 'browser window 1', $state );
	}

sub eq_window_visible
	{
	my $self   = shift;
	my $state  = shift;

	$self->_window_visible( 'EQ window 1', $state );
	}

sub _window_visible
	{
	my $self   = shift;
	my $window = shift;
	my $state  = shift;

	if( defined $state )
		{
		$state = $state ? TRUE : FALSE;
		$self->tell( "set visible of $window to $state" );
		}

	$self->tell( "return visible of $window" );
	}

=back

=head2 General AppleScript methods

=over

=item tell( COMMAND )

The tell() method runs a simple applescript.

If the ITUNES_TELL environment variable is set to a true value,
it prints the script to SDTERR before it runs it.

=cut

sub tell
	{
	my $self    = shift;
	my $command = shift;

	my $script = qq(tell application "iTunes"\n$command\nend tell);
	print STDERR "\n", "-" x 50, "\n", $script, "\n", "-" x 50, "\n"
		if $ENV{ITUNES_TELL};

	my $result = RunAppleScript( $script );

	if( $@ )
		{
		carp $@;
		return;
		}

	return 1 if( defined $result and $result eq '' );

	$result =~ s/^"|"$//g;

	return $result;
	}

sub _osascript
	{
	my $script = shift;

	print STDERR "Script is $script\n" if $ENV{ITUNES_DEBUG} > 1;
	require IPC::Open2;

	my( $read, $write );
	my $pid = IPC::Open2::open2( $read, $write, 'osascript' );

	print $write qq(tell application "iTunes"\n), $script,
		qq(\nend tell\n);
	close $write;

	my $data = do { local $/; <$read> };

	return $data;
	}

sub _get_value
	{
	my $self     = shift;
	my $property = shift;

	my $value = $self->tell( "return( $property )" );

	chomp $value;

	$value;
	}

sub _set_value
	{
	my $self     = shift;
	my $property = shift;
	my $value    = shift;

	$self->tell( "set $property to $value\n" );

	return $self->_get_value( $property );
	}

sub _escape_quotes
	{
	my $self   = shift;
	my $string = shift;
	$string =~ s/"/\\"/g;

	$string;
	}

sub DESTROY { 1 };

=item state

Returns the state of the iTunes application, represented by one of
the following symbolic constants:

	STOPPED
	PLAYING
	PAUSED
	FAST_FORWARDING
	REWINDING

=cut

=back

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/CPAN-Adopt-Me/MacOSX-iTunes.git

=head1 AUTHOR

brian d foy,  C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2007 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

"See why 1984 won't be like 1984";
