#!/usr/bin/perl
use strict;
use warnings;
use v5.12;

use Config::Tiny;
use Data::Dumper qw(Dumper);
use XML::Feed;

use Dwimmer::Feed::DB;


my ($config_file, $store) = @ARGV;

if (not $store) {
	die "Usage: $0  path/to/planet/config.ini  path/to/feed.db\n";
}

my $cfg = Config::Tiny->read($config_file);

my $db = Dwimmer::Feed::DB->new( store => $store );
$db->connect;

foreach my $section (keys %$cfg) {
	say $section;
	if ($section eq 'Planet') {
	} elsif ($section =~ m{^http://}) {
		my %data;
		$data{title} = $cfg->{$section}{name};
		$data{feed}  = $section;

		my $feed = XML::Feed->parse(URI->new($section));
		if ($feed) {
			#say $feed->title;
			#say $feed->base;
			$data{url} = $feed->link;
			#say $feed->tagline;
			#say $feed->author;
			$data{twitter} = '';
			$data{status}  = 'enabled';
			$data{comment} = '';
			#say Dumper \%data;
			my $id = $db->add_source(\%data);
			if ($id) {
				say 'added';
			} else {
				say 'failed to add';
			}
		} else {
			say 'feed not found';
		}
	} else {
		say "Unhandled section '$section'";
	}
}




