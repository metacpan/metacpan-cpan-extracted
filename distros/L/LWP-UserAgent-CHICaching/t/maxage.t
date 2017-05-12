use strict;
use warnings;

use Test::More;
use LWP::Protocol::PSGI;
use CHI;
use Plack::Request;

use_ok('LWP::UserAgent::CHICaching');

my %counter;
$counter{'DAHUT'} = 0;

my $app = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $query = $req->param('query');
	$counter{$query}++;
	my $content = "Hello $query\nCounter: $counter{$query}";
	return [ 200, [ 'Cache-Control' => 'max-age=4', 'Content-Type' => 'text/plain'], [ $content] ] 
};

LWP::Protocol::PSGI->register($app);

my $cache = CHI->new( driver => 'Memory', global => 1 );
my $ua = LWP::UserAgent::CHICaching->new(cache => $cache);

my $res1 = $ua->get("http://localhost:3000/?query=DAHUT");
isa_ok($res1, 'HTTP::Response');
like($res1->content, qr/Hello DAHUT/, 'First request, got the right shout');
like($res1->content, qr/Counter: 1$/, 'First request, correct count');
is($res1->freshness_lifetime, 4, 'Freshness lifetime is 4 secs');
is($ua->cache_vary($res1), 1, 'Vary header not present, so we can cache');


my $cres = $cache->get("http://localhost:3000/?query=DAHUT");
isa_ok($cres, 'HTTP::Response');

note "Sleep 2 secs to see Age";
sleep 2;

my $res2 = $ua->get("http://localhost:3000/?query=DAHUT");
like($res2->content, qr/Hello DAHUT/, 'Second request, got the right shout');
like($res2->content, qr/Counter: 1$/, 'Second request, the count is the same');
unlike($res2->content, qr/Counter: 2/, 'Second request, the count is not 2');
like($res2->header('Age'), qr/^2|3$/, 'The Age of resource is 2 secs');
is($ua->cache_vary($res2), 1, 'Vary header not present, so we can cache');

note "Sleep 3 secs to expire cache";
sleep 3;

my $res3 = $ua->get("http://localhost:3000/?query=DAHUT");
like($res3->content, qr/Hello DAHUT/, 'Third request, got the right shout');
like($res3->content, qr/Counter: 2$/, 'Third request, the count is 2');
unlike($res3->content, qr/Counter: 3/, 'Third request, the count is not 3');



done_testing;
