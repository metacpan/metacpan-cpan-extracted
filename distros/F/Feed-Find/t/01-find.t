use strict;
use Test::More tests => 4;
use Feed::Find;
use LWP::UserAgent;

use constant BASE => 'https://davecross.co.uk/';

my(@feeds);

@feeds = Feed::Find->find(BASE . '2020-vision/');
is(scalar @feeds, 1);
is($feeds[0], BASE . '2020-vision/feed.atom');

my $ua = LWP::UserAgent->new;
$ua->env_proxy;
my $req = HTTP::Request->new(GET => BASE . '2020-vision/');
my $res = $ua->request($req);
@feeds = Feed::Find->find_in_html(\$res->content, BASE . '2020-vision/');
is(scalar @feeds, 1);
is($feeds[0], BASE . '2020-vision/feed.atom');
