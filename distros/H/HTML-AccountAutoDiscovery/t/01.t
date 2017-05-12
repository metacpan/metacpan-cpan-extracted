#$Id: 01.t,v 1.1 2005/07/28 01:38:25 naoya Exp $

use Test::More tests => 7;
BEGIN { use_ok('HTML::AccountAutoDiscovery') };

my (@users);
my $testurl = 'http://www.hatena.ne.jp/info/perl/autodiscovery/test';

@users = HTML::AccountAutoDiscovery->find($testurl);
is(scalar @users, 1);
is($users[0]->{account}, 'hatena');
is($users[0]->{service}, 'http://www.hatena.ne.jp/');

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(GET => $testurl);
my $res = $ua->request($req);
@users = HTML::AccountAutoDiscovery->find_in_html(\$res->content);
is(scalar @users, 1);
is($users[0]->{account}, 'hatena');
is($users[0]->{service}, 'http://www.hatena.ne.jp/');