#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More;
use File::HomeDir;

if (
	$File::HomeDir::IMPLEMENTED_BY->isa('File::HomeDir::Darwin')
	and
	eval "require Mac::SystemDirectory; 1"
 ) {
        # Force Cocoa if you have Mac::SystemDirectory
        require File::HomeDir::Darwin::Cocoa;
        $File::HomeDir::IMPLEMENTED_BY = 'File::HomeDir::Darwin::Cocoa';
	plan( tests => 5 );
} else {
	plan( skip_all => "Not running on Darwin with Cocoa API using Mac::SystemDirectory" );
	exit(0);
}

SKIP: {
	my $user;
	foreach ( 0 .. 9 ) {
		my $temp = sprintf 'fubar%04d', rand(10000);
		getpwnam $temp and next;
		$user = $temp;
		last;
	}
	$user or skip("Unable to find non-existent user", 1);
	$@ = undef;
	my $home = eval { File::HomeDir->users_home($user) };
	$@ and skip("Unable to execute File::HomeDir->users_home('$user')", 1);
	ok (!defined $home, "Home of non-existent user should be undef");
}

SCOPE: {
	# Reality Check
	my $music    = File::HomeDir->my_music;
	my $video    = File::HomeDir->my_videos;
	my $pictures = File::HomeDir->my_pictures;
	SKIP: {
		skip( "No music directory", 1 ) unless defined $music;
		like( File::HomeDir->my_music, qr/Music/ );
	}
	SKIP: {
		skip( "No videos directory", 1 ) unless defined $video;
		like( File::HomeDir->my_videos, qr/Movies/ );
	}
	SKIP: {
		skip( "No pictures directory", 1 ) unless defined $pictures;
		like( File::HomeDir->my_pictures, qr/Pictures/ );
	}

	SKIP: {
		my $data = File::HomeDir->my_data;
		skip( "No application support directory", 1 ) unless defined $data;
		like( $data, qr/Application Support/ );
	}
}
