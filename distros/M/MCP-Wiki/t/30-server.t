use strict;
use warnings;
use Test::More;
use Path::Tiny qw( tempdir );
use File::Spec;
use MCP::Wiki::Server;
use feature 'signatures';

subtest 'Server creation' => sub {
    my $server = MCP::Wiki::Server->new(
        wiki_root => '/tmp',
    );
    ok($server, 'server created');
    is($server->wiki_root, '/tmp', 'wiki_root set');
};

subtest 'Server with defaults' => sub {
    my $server = MCP::Wiki::Server->new;
    ok($server, 'server created with defaults');
    is($server->wiki_root, '.', 'default wiki_root is .');
    is($server->use_git, 0, 'use_git defaults to 0');
};

subtest 'on_change handler' => sub {
    my $server = MCP::Wiki::Server->new;
    my $called = 0;
    my $event_received;

    $server->on_change(sub ($event) {
        $called++;
        $event_received = $event;
    });

    # Simulate _fire_on_change
    $server->_fire_on_change({ type => 'test', page => 'test.md' });

    is($called, 1, 'handler was called');
    is($event_received->{type}, 'test', 'event type correct');
};

done_testing;