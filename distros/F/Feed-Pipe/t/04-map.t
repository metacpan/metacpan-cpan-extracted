#!/usr/bin/perl
use strict;
use Test::More tests =>
15;
use FindBin;
use Path::Class;
# use Log::Any::Adapter;
# use Log::Any::Adapter::Test::Memory;
# Log::Any::Adapter->set('Test::Memory');
# my $logger = Log::Any->get_logger(category => 'Feed::Pipe');

use_ok('Feed::Pipe');

my @feeds = 
( file($FindBin::Bin, 'atom1.atom')->stringify # valid atom feed
, file($FindBin::Bin, 'rss1.xml')->stringify # RSS 1 from delicious
, file($FindBin::Bin, 'rss2wp.xml')->stringify # RSS 2 from Wordpress
);

sub duplicate {($_,$_)}
sub nullify{}
sub truncate_title {
    my $entry = $_;
    if (length($entry->title) > 10) {
        $entry->title(substr($entry->title,0,10));
    }
    return $entry;
}

my $feed = Feed::Pipe
    ->cat(@feeds)
    ->map(\&truncate_title)
    ;

is $feed->count, 10, 'correct number of entries in result';
for my $entry ($feed->entries) {
    is length($entry->title), 10, 'filtered';
}
#diag join "\n", map { $_->title } $feed->entries;
# diag $feed->as_xml;

my $gotit = eval {require Test::Warn};
SKIP: { skip 'Test::Warn not installed', 1 if $@;
    Test::Warn::warning_like(sub{$feed->map}, qr/Ignoring map/, 'map warns when no coderef passed');
#    like $logger->{msgs}[-1]{text}, qr/Ignoring map/, 'map logs warning when no coderef passed';
}

$feed->map(\&duplicate);
is $feed->count, 20, 'map function can return multiple results';

$feed->map(\&nullify);
is $feed->count, 0, 'map function can return no results';





