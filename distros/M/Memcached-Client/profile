#!/usr/bin/perl

use strict;
use warnings;
use lib qw{lib};
use Memcached::Client qw{};
use Storable qw{dclone freeze thaw};
use t::Memcached::Manager qw{};

my @tests = (['connect', 1,
              '->connect'],

             ['version',
              'Checking for version on all servers'],

             ['set',
              '->set without a key'],
             ['set', 'foo',
              '->set without a value'],
             ['set', 'foo', 'bar',
              '->set with a value'],
             ['set', ['37', 'llama'], 'bar',
              '->set with a pre-hashed key'],
             ['set_multi', ['teatime', 3], ['bagman', 'ludo'],
              '->set_multi with various keys'],

             ['add',
              '->add without a key'],
             ['add', 'foo',
              '->add without a value'],
             ['add', 'bar', 'baz',
              '->add with a value'],
             ['add', 'bar', 'foo',
              '->add with an existing value'],
             ['add_multi', ['teatime', 3], ['bagman', 'ludo'],
              '->set_multi with various pre-existing keys'],
             ['add_multi', ['porridge', 'salty'], ['complex', 'simple'], ['bagman', 'horace'],
              '->set_multi with various keys'],

             ['set', ['19', 'ding-dong'], 'bar',
              '->add with a pre-hashed key'],

             ['get',
              '->get without a key'],
             ['get', 'bang',
              '->get a non-existant value'],
             ['get', 'bar',
              '->get an existing value'],

             ['get', ['19', 'ding-dong'],
              '->get a value with a pre-hashed key'],

             ['get_multi',
              '->get_multi without a list'],
             ['get_multi', 'bar', 'foo', 'porridge',
              '->get with all keys set so far'],

             ['get_multi', ['37', 'llama'], 'bar', 'foo',
              '->get with all keys set so far'],

             ['replace',
              '->replace without a key'],
             ['replace', 'foo',
              '->replace without a value'],
             ['replace', 'baz', 'gorp',
              '->replace with a non-existent value'],
             ['replace', 'bar', 'gondola',
              '->replace with an existing value'],
             ['replace_multi', ['porridge', 'sweet'], ['complex', 'NP'], ['ludo', 'panopticon'],
              '->replace_multi with various keys'],

             ['get', 'bar',
              '->get to verify replacement'],

             ['get', 'a' x 256,
              '->get a key that is too large and does not exist'],

             ['set', 'b' x 256, 'lurch',
              '->set a key that is too large and does not exist'],

             ['replace', ['18', 'ding-dong'], 'bar',
              '->replace with a pre-hashed key and non-existent value'],
             ['replace', ['19', 'ding-dong'], 'baz',
              '->replace with a pre-hashed key and an existing value'],
             ['get', ['19', 'ding-dong'],
              '->get a value with a pre-hashed key'],

             ['append',
              '->append without a key'],
             ['append', 'foo',
              '->append without a value'],
             ['append', 'baz', 'gorp',
              '->append with a non-existent value'],
             ['append', 'bar', 'gorp',
              '->append with an existing value'],
             ['append_multi', ['porridge', ' and salty'], ['complex', ' != P'],
              '->append_multi with various keys'],

             ['get', 'bar',
              '->get to verify ->append'],

             ['append', ['18', 'ding-dong'], 'flagon',
              '->append with a pre-hashed key and non-existent value'],
             ['append', ['19', 'ding-dong'], 'flagged',
              '->append with a pre-hashed key and an existing value'],
             ['get', ['19', 'ding-dong'],
              '->get a value with a pre-hashed key'],

             ['prepend',
              '->prepend without a key'],
             ['prepend', 'foo',
              '->prepend without a value'],
             ['prepend', 'baz', 'gorp',
              '->prepend with a non-existent value'],
             ['prepend', 'foo', 'gorp',
              '->prepend with an existing value'],
             ['prepend_multi', ['porridge', 'We love '],
              '->prepend_multi with various keys'],


             ['get', 'foo',
              '->get to verify ->prepend'],

             ['delete',
              '->delete without a key'],
             ['delete', 'bang',
              '->delete with a non-existent key'],
             ['delete', 'foo',
              '->delete with an existing key'],
             ['delete_multi', 'complex', 'panopticon',
              '->delete_multi with various keys'],

             ['get', 'foo',
              '->get to verify ->delete'],

             ['add', 'foo', '1',
              '->add with a value'],
             ['get', 'foo',
              '->get to verify ->add'],

             ['incr',
              '->incr without a key'],
             ['incr', 'bang',
              '->incr with a non-existent key'],
             ['incr', 'foo',
              '->incr with an existing key'],
             ['incr', 'foo', '72',
              '->incr with an existing key and an amount'],
             ['get', 'foo',
              '->get to verify ->incr'],

             ['decr',
              '->decr without a key'],
             ['decr', 'bang',
              '->decr with a non-existent key'],
             ['decr', 'foo',
              '->decr with an existing key'],
             ['decr', 'foo', 18,
              '->decr with an existing key'],
             ['get', 'foo',
              '->get to verify ->decr'],

             ['get_multi', 'bar', 'foo',
              '->get with all keys set so far'],

             ['incr_multi', 'foo',
              '->incr_multi with various keys'],

             ['incr_multi', ['braga', 1, 17], ['foo', 7],
              '->incr_multi with various keys'],

             ['decr_multi', ['braga', 3], ['bartinate', 7, 33],
              '->decr_multi with various keys'],

             ['flush_all',
              '->flush_all to clear servers'],

             ['get_multi', 'bar', 'foo',
              '->get with all keys set so far']);

die 'No memcached found' unless my $memcached = find_memcached ();

my $servers = ['127.0.0.1:10001',
               '127.0.0.1:10002',
               '127.0.0.1:10003',
               '127.0.0.1:10004'];

my $manager = t::Memcached::Manager->new (memcached => $memcached, servers => $servers);

for my $runner (\&sync, \&async) {
    for my $protocol qw(Text Binary) {
        for my $selector qw(Traditional) {
            printf "running %s/%s %s\n", $selector, $protocol, $runner;
            my $namespace = join ('.', time, $$, '');
            my $client = Memcached::Client->new (namespace => $namespace, protocol => $protocol, selector => $selector, servers => $servers);
            $runner->($selector, $protocol, $client, freeze \@tests);
            printf "Done with %s/%s %s\n", $selector, $protocol, $runner;
        }
    }
}

sub async {
    my ($selector, $protocol, $client, $tests) = @_;
    printf "T: running %s/%s async\n", $selector, $protocol;
    my @tests = @{thaw $tests};
    my $cv = AE::cv;
    DB::enable_profile() if defined $ENV{NYTPROF};
    my $test; $test = sub {
        my ($method, @args) = @{shift @tests};
        my $msg = pop @args;
        printf "T: %s is %s (%s)\n", $msg, $method, \@args;
        $client->$method (@{dclone \@args}, sub {
                              my ($received) = @_;
                              if (scalar @tests) {
                                  goto &$test;
                              } else {
                                  $cv->send;
                              }
                          });
    };
    $test->();
    DB::disable_profile() if defined $ENV{NYTPROF};
    $cv->recv;
}

sub sync {
    my ($selector, $protocol, $client, $tests) = @_;
    printf "T: running %s/%s synchronous\n", $selector, $protocol;
    my @tests = @{thaw $tests};
    while (1) {
        my ($method, @args) = @{shift @tests};
        my $msg = pop @args;
        printf "T: %s is %s (%s)\n", $msg, $method, join ",", @args;
        DB::enable_profile() if defined $ENV{NYTPROF};
        my $received = $client->$method (@args);
        DB::disable_profile() if defined $ENV{NYTPROF};
        last unless (@tests);
    }
}

sub find_memcached {
    #diag "Looking for environment";
    # If we're told where to look, use it if it looks executable
    return $ENV{MEMCACHED} if ($ENV{MEMCACHED} and -x $ENV{MEMCACHED});
    #diag "Looking using which";
    # Try using which
    chomp (my $memcached = qx{which memcached});
    # If we got output, use it if it looks executable
    return $memcached if ($memcached and -x $memcached);
    #diag "Trying using path";
    # If we're able to execute it without error
    return "memcached" unless system qq{memcached -h 2>/dev/null};
    #diag "Failing";
    # We failed, we're going to skip
    return;
}
1;
