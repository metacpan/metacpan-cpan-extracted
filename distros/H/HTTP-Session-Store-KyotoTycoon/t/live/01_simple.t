use strict;
use warnings;
use Test::More;
use HTTP::Session::Store::KyotoTycoon;
use HTTP::Session::State::Null;
use Test::Requires 'File::Which', 'Test::TCP';

my $ktserver = File::Which::which('ktserver');
plan skip_all => 'missing ktserver' unless $ktserver;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        my $store = HTTP::Session::Store::KyotoTycoon->new(
            port    => $port,
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
    },
    server => sub {
        my $port = shift;
        exec $ktserver, '-port', $port;
        die "cannot spawn $ktserver";
    },
);

done_testing;
