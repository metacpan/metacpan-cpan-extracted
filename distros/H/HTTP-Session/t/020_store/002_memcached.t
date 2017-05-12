use strict;
use warnings;
use Test::More;
use t::Exception;
plan skip_all => 'please set $ENV{TEST_MEMD}' unless $ENV{TEST_MEMD};
plan tests => 17;
use HTTP::Session;
use CGI;
require HTTP::Session::Store::Memcached;
use HTTP::Session::State::Null;
require Cache::Memcached::Fast;

my $store = HTTP::Session::Store::Memcached->new(
    memd => Cache::Memcached::Fast->new(
        {
        servers => ['127.0.0.1:11211'],
        }
    ),
    expires => 60,
);

my $key = "jklj352krtsfskfjlafkjl235j1" . rand();
is $store->select($key), undef;
$store->insert($key, {foo => 'bar'});
is $store->select($key)->{foo}, 'bar';
$store->update($key, {foo => 'replaced'});
is $store->select($key)->{foo}, 'replaced';
$store->delete($key);
is $store->select($key), undef;
ok $store;

sub injection (&);

my $injection_key = "x"x1024 . rand();;
injection { $store->select($injection_key); };
injection { $store->insert($injection_key, {foo => 'bar'}); };
injection { $store->select($injection_key)->{foo}; };

$injection_key = "x\r\nstats\r\n" . rand();;
injection { $store->select($injection_key); };
injection { $store->insert($injection_key, {foo => 'bar'}); };
injection { $store->select($injection_key)->{foo}, 'bar'; };

$injection_key = "m e m c a c h e d" . rand();;
injection { $store->select($injection_key); };
injection { $store->insert($injection_key, {foo => 'bar'}); };
injection { $store->select($injection_key)->{foo}, 'bar'; };

$injection_key = qq!\x{3042}!x100;
injection { $store->select($injection_key); };
injection { $store->insert($injection_key, {foo => 'bar'}); };
injection { $store->select($injection_key)->{foo}, 'bar'; };

sub injection (&) {
    eval { $_[0]->() };
    like $@, qr/injection/;
}
