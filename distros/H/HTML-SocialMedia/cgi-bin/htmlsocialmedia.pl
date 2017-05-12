#!/usr/bin/env perl

use strict;
use warnings;
use HTML::SocialMedia;
use CGI::Buffer;

CGI::Buffer::set_options(optimise_content => 1);

print "Content-type: text/html\n\n";

my $sm = HTML::SocialMedia->new(twitter => 'nigelhorne');

print '<!DOCTYPE HTML>',
	'<HTML><HEAD><TITLE>SocialMedia Test</TITLE>',
	"<style>.right {\n",
	"position: absolute;\n",
	"width: 10%;\n",
	"right: 0px;\n",
	"}\n",
	'</style></HEAD><BODY>',
	'<div class="right">',
	$sm->as_string(
		twitter_follow_button => 1,
		twitter_tweet_button => 1,
		facebook_like_button => 1,
		facebook_share_button => 1,
		linkedin_share_button => 1,
		google_plusone => 1,
		reddit_button => 1,
	),
	"</div></BODY></HTML>\n";
