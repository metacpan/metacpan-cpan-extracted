#!/usr/bin/perl
use strict;
use Test::More tests =>
13;
use FindBin;
use Path::Class;

# use Log::Log4perl qw(:easy);
# use Log::Any::Adapter;
# Log::Log4perl->easy_init($DEBUG);
# Log::Any::Adapter->set('Log4perl');
# my $logger = Log::Any->get_logger;
# 
use_ok('Feed::Pipe');

my @feeds = 
( file($FindBin::Bin, 'atom1.atom')->stringify # valid atom feed
, file($FindBin::Bin, 'rss1.xml')->stringify # RSS 1 from delicious
, file($FindBin::Bin, 'rss2wp.xml')->stringify # RSS 2 from Wordpress
);

my $feed = Feed::Pipe->new(title => 'Test Feed')->cat(@feeds);
$feed->title("Test Feed");

my ($first) = $feed->entries;
is $first->published, '2009-06-19T16:50:00Z', 'cat adds entries in original order';
is $feed->count, 10, 'total entries';

$feed->sort;

($first) = $feed->entries;
#is $first->published, '2009-11-14T20:25:01Z', 'sorted most recent first';
is $first->published, '2009-11-18T03:48:04Z', 'sorted most recent first';
# $logger->debug( join "\n", map { $_->updated||$_->published } $feed->entries) if $logger->is_debug;

$feed->tail(7);
($first) = $feed->entries;
is $feed->count, 7, 'tail removes entries';
is $first->published, '2009-11-12T20:47:42Z', 'tail pulls from tail';

$feed->head(6);
($first) = $feed->entries;
is $feed->count, 6, 'head removes entries';
is $first->published, '2009-11-12T20:47:42Z', 'head pulls from head';
diag $first->title if $first->content||$first->summary;

$feed->reverse;
($first) = $feed->entries;
is $first->published, '2009-04-26T21:38:26Z', 'reverse';
# $logger->debug( join "\n", map { $_->updated||$_->published } $feed->entries) if $logger->is_debug;

# Item with date 2009-11-12T20:47:42Z has no content or summary, should
# be filtered out.
$feed->grep;
$first = $feed->_entry_at(-1);
is $first->published, '2009-11-07T10:40:07Z', 'grep removes no-content items by default';
# $logger->debug( join "\n", map { $_->updated||$_->published } $feed->entries) if $logger->is_debug;

my $atom = $feed->as_atom_obj;
isa_ok $atom, 'XML::Atom::Feed', 'as_atom_obj return value';

my $xml = $feed->as_xml;
$atom = XML::Atom::Feed->new(\$xml);
isa_ok($atom, 'XML::Atom::Feed', 'round trip serialization appears to work,');
is $atom->title, 'Test Feed', 'title set and preserved';











