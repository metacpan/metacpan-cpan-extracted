#!/usr/bin/perl
use strict;
use Test::More tests =>
3;
use FindBin;
use Path::Class;
# use Log::Log4perl qw(:easy);
# use Log::Any::Adapter;
# Log::Log4perl->easy_init($DEBUG);
# Log::Any::Adapter->set('Log4perl');
# my $logger = Log::Any->get_logger;

use Feed::Pipe;
use XML::Atom::Feed;
use XML::Feed;

my $atom = XML::Atom::Feed->new(file($FindBin::Bin, 'atom1.atom')->stringify);
my $xml_feed = XML::Feed->parse(file($FindBin::Bin, 'rss1.xml')->stringify);
my $text = file($FindBin::Bin, 'rss2wp.xml')->slurp;

my $feed = Feed::Pipe
    ->cat($atom, $xml_feed, \$text)
    ->sort
    ->tail(7)
    ->head(6)
    ->reverse
    ->grep
    ;

is $feed->count, 5, 'correct number of entries in result';

my ($first) = $feed->entries;
is $first->published, '2009-04-26T21:38:26Z', 'correct date on first entry';

($first) = $feed->_entry_at(-1);
is $first->published, '2009-11-07T10:40:07Z', 'correct date on last entry';

# $logger->debug( $feed->as_xml ) if $logger->is_debug;











