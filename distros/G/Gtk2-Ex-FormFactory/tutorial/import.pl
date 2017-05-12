#!/usr/bin/perl

$Id: import.pl,v 1.2 2005/07/11 15:53:40 joern Exp $

use strict;

use MP3::Info;
use Ogg::Vorbis::Header;
use File::Find;
use Encode;

require "config.pm";

my $USAGE = <<__EOU;
Usage: import_from_files.pl directory

Description:
    Scans the given directory recursively for .mp3 and .ogg files,
    read their tags and adds corresponding entries to the music
    database of this Gtk2::Ex::FormFactory tutorial.

__EOU

main: {
	my $dir = shift @ARGV;
	
	if ( !$dir or @ARGV ) {
		print $USAGE;
		exit 1;
	}
	
	my $config = Music::Config->new;
	$config->test_db_connection;
	die "Start music.pl first, for database configuration"
		unless $config->get_db_connection_ok;

	scan_directory($dir);
}

sub scan_directory {
	my ($dir) = @_;
	
	my $genre = Music::Genre->find_or_create({ name => "Unknown" });
	
	my (%artists, %albums);
	
	find ( sub {
		return unless /\.(ogg|mp3)$/i;
		my $filename = $File::Find::name;
		my ($artist, $album, $song, $nr);
		if ( $filename =~ /ogg$/i ) {
			my $header = Ogg::Vorbis::Header->new($filename)
				or return;
			$artist = ($header->comment('artist'))[0];
			$album  = ($header->comment('album'))[0];
			$song   = ($header->comment('title'))[0];
			$nr     = ($header->comment('tracknumber'))[0];
			Encode::from_to($_,"utf8","latin1") for ($artist, $album, $song);
		} else {
			my $tag = get_mp3tag($filename) or return;
			$artist = $tag->{ARTIST};
			$album  = $tag->{ALBUM};
			$song   = $tag->{TITLE};
			$nr     = $tag->{TRACKNUM};
		}

		print "Found: $artist / $album / $nr - $song\n";

		my $artist_obj =
			$artists{$artist} ||
			Music::Artist->find_or_create({ name => $artist });
		$artists{$artist} ||= $artist_obj;

		my $album_obj = $albums{"$artist:$album"} ||
			(Music::Album->search ( { artist => $artist_obj, title => $album } ))[0] ||
			$artist_obj->add_to_albums({
		    		title  => $album,
				genre  => $genre,
			});
		$albums{"$artist:$album"} ||= $album_obj;
		
		my $song_obj =
			Music::Song->search ( { album => $album_obj, title => $song } ) ||
			$album_obj->add_to_songs ({
				nr	=> $nr,
				title	=> $song,
			});
	}, $dir );
}
