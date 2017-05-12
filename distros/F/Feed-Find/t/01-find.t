use strict;
use Test::More tests => 4;
use Feed::Find;
use LWP::UserAgent;

use constant BASE => 'http://stupidfool.org/perl/feeds/';

my(@feeds);

@feeds = Feed::Find->find(BASE . 'anchors-only.html');
is(scalar @feeds, 1);
is($feeds[0], BASE . 'ok.xml');

my $ua = LWP::UserAgent->new;
$ua->env_proxy;
my $req = HTTP::Request->new(GET => BASE . 'anchors-only.html');
my $res = $ua->request($req);
@feeds = Feed::Find->find_in_html(\$res->content, BASE . 'anchors-only.html');
is(scalar @feeds, 1);
is($feeds[0], BASE . 'ok.xml');
