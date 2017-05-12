use strict;
use warnings;

use Test::More;
use Test::TCP qw(test_tcp empty_port wait_port);
use Test::Skip::UnlessExistsExecutable;

use Cache::Memcached::Fast;
use File::Which qw(which);
use Proc::Guard;
use KeyedMutex::Memcached;

skip_all_unless_exists 'memcached';

sub run_memcached_server {
    my $port = shift;
    my $proc = proc_guard( scalar which('memcached'), '-p', $port, '-U', 0 );
    wait_port($port);
    return $proc;
}

sub create_memcached_client {
    my $port = shift;
    return Cache::Memcached::Fast->new(
        +{ servers => [ 'localhost:' . $port ] } );
}

{
    my $port  = empty_port;
    my $proc  = run_memcached_server($port);
    my $cache = create_memcached_client($port);

    subtest 'basic lock and unlock' => sub {
        my $mutex =
          KeyedMutex::Memcached->new( cache => $cache, timeout => 5, );
        is( $mutex->lock('foo'),   1,     'got lock' );
        is( $cache->get('km:foo'), 1,     'exists lock data' );
        is( $mutex->release,       1,     'release lock' );
        is( $cache->get('km:foo'), undef, 'not exists lock data' );
        done_testing;
    };

    subtest 'use raii' => sub {
        my $mutex =
          KeyedMutex::Memcached->new( cache => $cache, timeout => 5, );
        {
            if ( my $lock = $mutex->lock( 'baz', 1 ) ) {
                is( $cache->get('km:baz'), 1, 'exists lock data' );
            }
        };
        is( $cache->get('km:baz'), undef, 'not exists lock data' );
    };

    subtest 'lock timeout' => sub {
        my $mutex =
          KeyedMutex::Memcached->new( cache => $cache, timeout => 5, );
        is( $mutex->lock('foo'),   1, 'got lock' );
        is( $cache->get('km:foo'), 1, 'exists lock data' );
        sleep 6;
        is( $cache->get('km:foo'), undef, 'not exists lock data' );
        done_testing;
    };

    subtest 'two client' => sub {
        my $mutex1 =
          KeyedMutex::Memcached->new( cache => $cache, timeout => 5, );
        my $mutex2 =
          KeyedMutex::Memcached->new( cache => $cache, timeout => 5, );

        is( $mutex1->lock('foo'), 1, 'mutex1 got lock' );
        local $SIG{ALRM} = sub {
            note time;
            is( $mutex1->release, 1, 'mutex1 released lock' );
        };
        alarm 2;
        is( $mutex2->lock('foo'), 1,
            'mutex2 got lock after mutex1 released lock' );
        alarm 0;
        is( $mutex2->release, 1, 'mutex2 released lock' );
        done_testing;
    };

    subtest 'trial limitation' => sub {
        my $mutex1 = KeyedMutex::Memcached->new(
            cache   => $cache,
            timeout => 5,
            trial   => 1,
        );
        my $mutex2 = KeyedMutex::Memcached->new(
            cache   => $cache,
            timeout => 5,
            trial   => 1,
        );

        is( $mutex1->lock('foo'), 1, 'mutex1 got lock' );
        is( $mutex2->lock('foo'), 0, 'mutex2 could not get lock' );
        sleep 6;
        is( $mutex2->lock('foo'), 1, 'mutex2 got lock' );
        is( $mutex2->release,     1, 'mutex2 released lock' );
        done_testing;
    };
};

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
