use strict;
use Test::More tests => 3;
BEGIN { use_ok('LWP::UserAgent::Cache::Memcached') };

$LWP::UserAgent::Cache::Memcached::FAST = 0;
my $ua = LWP::UserAgent::Cache::Memcached->new;
ok($ua->cacher eq 'Cache::Memcached', 'Flag');

$LWP::UserAgent::Cache::Memcached::FAST = 1;
my $check = 0;
if ($ua->cacher eq 'Cache::Memcached::Fast' or $ua->cacher eq 'Cache::Memcached') {
	$check = 1;
}
is($check,1,'Cacher is '.$ua->cacher);

