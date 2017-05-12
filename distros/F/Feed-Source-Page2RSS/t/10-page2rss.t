use Test::More;
use Feed::Source::Page2RSS;

plan tests => 8;

my $feed;

$feed = Feed::Source::Page2RSS->new( url => "http://www.google.com" );
my $url = $feed->url_feed();

is( $url,
    "http://page2rss.com/page/rss?url=http%3A%2F%2Fwww.google.com",
    "Test to monitor http://www.google.com",
);

isa_ok($feed, 'Feed::Source::Page2RSS');
can_ok($feed, 'url_feed');
can_ok($feed, 'feed_type');
can_ok($feed, 'atom_feed');
can_ok($feed, 'rss_feed');

eval { $feed = Feed::Source::Page2RSS->new() };
is( $@, '', "Feed::Source::Page2RSS->new()" );

eval {
    $feed = Feed::Source::Page2RSS->new();
    $feed->url_feed();
};
like(
    $@,
    qr/^You must specify an URL to monitor/,
    "You must specify an URL to monitor",
);
