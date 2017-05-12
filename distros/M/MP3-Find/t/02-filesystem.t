#!/usr/bin/perl -w
use strict;

use Test::More tests => 6;
BEGIN { use_ok('MP3::Find::Filesystem') };

my $SEARCH_DIR = 't/mp3s';
my $EXCLUDE_DIR = 't/mp3s/dont_look_here';
my $MP3_COUNT = 1;
my $EXCLUDED_MP3_COUNT = 1;

# exercise the object

my $finder = MP3::Find::Filesystem->new;
isa_ok($finder, 'MP3::Find::Filesystem');

# a most basic search:
my @res = $finder->find_mp3s(dir => $SEARCH_DIR);
is(scalar(@res), $MP3_COUNT, 'dir as scalar');

@res = $finder->find_mp3s(dir => [$SEARCH_DIR]);
is(scalar(@res), $MP3_COUNT, 'dir as ARRAY ref');

# exclude
@res = $finder->find_mp3s(dir => $SEARCH_DIR, exclude_path => $EXCLUDE_DIR);
is(scalar(@res), $MP3_COUNT - $EXCLUDED_MP3_COUNT, 'excluded directory');

@res = $finder->find_mp3s(dir => $SEARCH_DIR, exclude_path => [$EXCLUDE_DIR]);
is(scalar(@res), $MP3_COUNT - $EXCLUDED_MP3_COUNT, 'excluded directory as array');

#TODO: get some test mp3s
