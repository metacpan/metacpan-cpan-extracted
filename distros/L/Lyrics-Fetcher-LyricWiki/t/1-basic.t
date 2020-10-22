#!/usr/bin/perl

#$Id$

# quick dirty testing for Lyrics::Fetcher::LyricWiki
#

# TODO: use Test::MockObject to replace the LWP object being used with one which
# pretends to have fetched lyrics from lyricwiki, so we can test the behaviour
# of this module given expected and unexpected input.  Currently, we're also
# testing whether we can fetch lyrics, which could fail if a network link or the
# LyricWiki site is unavailable, or, now that they've dropped their API, if
# their site changes preventing this from working.

use strict;
use warnings;
use Test::More;
use Lyrics::Fetcher::LyricWiki;


# we have a set of tests, some of which should work, some of which should
# fail.  Each test is a hashref, with the following keys:
#   title   => the song title
#   artist  => the artist
#   lookfor => qr/..../  - the lyrics returned must match this regexp
#   fail    => 1  (optional - if true, then this request should fail)
#   error   => '....'  - if fail is used, then eror gives the error
#               message that we expect to see upon failure

# For each test fetch, we perform two tests and skip two tests, depending upon
# whether it's a test which should fail or not.
plan tests => 1;

    
my $lyrics = Lyrics::Fetcher::LyricWiki->fetch('Spice Girls', 'Goodbye');
is($Lyrics::Fetcher::Error, 'LyricsWiki no longer exists');

