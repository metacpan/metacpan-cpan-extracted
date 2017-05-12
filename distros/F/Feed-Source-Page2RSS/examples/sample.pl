#!/usr/bin/perl -w

use strict;
use warnings;

use lib "./lib";
use Feed::Source::Page2RSS;
use Getopt::Long;

my $config = {};

GetOptions($config, "url|u=s", "feed|f=s");

if (exists $config->{url}) {
  my $feed = Feed::Source::Page2RSS->new( url => $config->{url} );
  $feed->feed_type($config->{feed}) if $config->{feed};
  print "Feed URL: " . $feed->url_feed() . "\n";
} else {
  die "$0 --url url --feed feed_type\n";
}
