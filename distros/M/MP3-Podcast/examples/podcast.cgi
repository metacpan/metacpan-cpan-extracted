#!/usr/bin/perl

#Chage this to wherever is the lib, or just comment it if it's in the standard place
use lib "../lib";
use MP3::Podcast;
use CGI qw(:standard);

require "podcast.conf"; #includes site-wide definitions

#Generates a podcast from basedirs in conf file and dirname 
#extracted from the URI;
my $request_uri = $ENV{REQUEST_URI};
my ($dir) = ($request_uri =~ m{cgi/(.*)\.rss});

require("$dirbase/$dir/.podcast"); 

my $pod = MP3::Podcast->new($dirbase,$urlbase);
my $rss = $pod->podcast( $dir, $channelTitle, $creator, $descr );

print header( -content_type => 'text/plain',
	      -encoding => 'iso-8859-1'),  $rss->as_string;
