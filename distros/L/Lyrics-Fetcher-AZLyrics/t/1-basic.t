#!/usr/bin/perl

#$Id$

# quick dirty testing for Lyrics::Fetcher::AZLyrics
#

# TODO: use Test::MockObject to replace the LWP object being used with one which
# pretends to have fetched lyrics from lyricwiki, so we can test the behaviour
# of this module given expected and unexpected input.  Currently, we're also
# testing whether we can fetch lyrics, which could fail if a network link or the
# AZLyrics site is unavailable, or, their site changes preventing this from working.

use strict;
use warnings;
use Test::More;
use Lyrics::Fetcher::AZLyrics;


# we have a set of tests, some of which should work, some of which should
# fail.  Each test is a hashref, with the following keys:
#   title   => the song title
#   artist  => the artist
#   lookfor => qr/..../  - the lyrics returned must match this regexp
#   fail    => 1  (optional - if true, then this request should fail)
#   error   => '....'  - if fail is used, then eror gives the error
#               message that we expect to see upon failure
my @tests = (

   {
        title   => 'Heavy Fuel',
        artist  => 'Dire Straits',
        lookfor => qr/Last time I was sober, man I felt bad/i,
    },
    {
        title   => 'Turn Up The Sun',
        artist  => 'Oasis',
        lookfor => qr/Come on, Turn up the sun/i,
    },
    {
        title   => 'This Song Does Not Exist',
        artist  => 'Nobody In Particular',
        fail    => 1,
        error   => 'Lyrics not found',
    },
);

# For each test fetch, we perform two tests and skip two tests, depending upon
# whether it's a test which should fail or not.
plan tests => scalar @tests * 4;


TEST: for my $test (@tests) {
    
    my $lyrics = Lyrics::Fetcher::AZLyrics->fetch(@$test{ qw(artist title) })
        || ''; # save errors trying to match regexes against uninitalised value
    my $title = $test->{title};
    SKIP: {
        skip "We expect this to work, so skip the failure checks", 2
            unless $test->{fail};
        # We want to see a failure attempting to fetch lyrics for this one; if
        # we get something, we're accidentally interpreting failure as success
        ok(!$lyrics, "Got no lyrics for $title");
        is($Lyrics::Fetcher::Error, $test->{error},
            "Got expected error message");
    }

    SKIP: {
        skip "We expect this to fail, so skip success checks", 2
            if $test->{fail};
        # This is a test that ought to succeed:
        like($lyrics, $test->{lookfor}, 
            "Lyrics look acceptable for $test->{title} by $test->{artist}");
        is($Lyrics::Fetcher::Error, 'OK',
            '$Lyrics::Fetcher::Error is \'OK\'');
    }
   
}
