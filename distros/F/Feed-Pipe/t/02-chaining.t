#!/usr/bin/perl
use strict;
use Test::More tests =>
4;
use FindBin;
use Path::Class;
# use Log::Log4perl qw(:easy);
# use Log::Any::Adapter;
# Log::Log4perl->easy_init($WARN);
# Log::Any::Adapter->set('Log4perl');
# my $logger = Log::Any->get_logger;

use_ok('Feed::Pipe');

my @feeds = 
( file($FindBin::Bin, 'atom1.atom')->stringify # valid atom feed
, file($FindBin::Bin, 'rss1.xml')->stringify # RSS 1 from delicious
, file($FindBin::Bin, 'rss2wp.xml')->stringify # RSS 2 from Wordpress
);

my $feed = Feed::Pipe
    ->cat(@feeds)
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

# $logger->debug( join "\n", map { $_->updated||$_->published } $feed->entries) if $logger->is_debug;











