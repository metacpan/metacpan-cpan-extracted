#!/usr/bin/perl
use strict;
use Test::More tests => 4;
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

my $xml_feed = XML::Feed->parse(file($FindBin::Bin, 'rss2wp.xml')->stringify);
my $text = file($FindBin::Bin, 'rss1.xml')->slurp;
# diag "SELF: ".$xml_feed->as_xml;

my $feed = Feed::Pipe
    ->cat($xml_feed, \$text)
    ->sort
    ->grep
    ;

is $feed->count, 5, 'correct number of entries in result';

my ($first) = $feed->entries;
is $first->published, '2009-11-18T03:48:04Z', 'correct date on first entry';
my $source = $first->source;
isa_ok($source, 'XML::Atom::Feed', 'source');
# my ($self_link) = grep {$_->rel eq 'self'} $source->links;
# isa_ok $self_link, 'XML::Atom::Link', 'self link';

my ($last) = $feed->_entry_at(-1);
is $last->published, '2009-11-05T21:11:50Z', 'correct date on last entry';

#$logger->debug( $feed->as_xml ) if $logger->is_debug;











