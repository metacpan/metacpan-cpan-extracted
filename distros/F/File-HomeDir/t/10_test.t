#!/usr/bin/perl

# Testing for the test driver

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use File::Spec::Functions ':ALL';
use Test::More tests => 30;
use File::HomeDir::Test;
use File::HomeDir;

# Is the test driver enabled?
is( $File::HomeDir::Test::ENABLED, 1, 'File::HomeDir::Test is enabled' );
is( $File::HomeDir::IMPLEMENTED_BY, 'File::HomeDir::Test', 'IMPLEMENTED_BY is correct' );

# Was everything hijacked correctly?
foreach my $method ( qw{
	my_home
	my_desktop
	my_documents
	my_data
	my_music
	my_pictures
	my_videos
} ) {
	my $dir = File::HomeDir->$method();
	ok( $dir, "$method: Got a directory" );
	ok( -d $dir, "$method: Directory exists at $dir" );
	ok( -r $dir, "$method: Directory is readable" );
	ok( -w $dir, "$method: Directory is writeable" );
}
