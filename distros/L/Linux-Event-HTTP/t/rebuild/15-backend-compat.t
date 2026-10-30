use v5.36;
use Test::More;
use Linux::Event::Loop;
use Linux::Event::HTTP::Server;
use Unblock::HTTP1::Server ();

sub options ($loop) {
    return (
        loop => $loop, host => '127.0.0.1', port => 0,
        on_request => sub ($tx, $req) { $tx->respond(status => 200, body => 'ok') },
    );
}

subtest 'outdated Unblock HTTP1 fails at construction before binding' => sub {
    my $loop = Linux::Event::Loop->new;
    my $server;
    my $error;
    {
        no warnings 'redefine';
        # Emulate a mixed installation missing the required method.
        local *Unblock::HTTP1::Server::drain;
        $server = eval { Linux::Event::HTTP::Server->new(options($loop)) };
        $error = "$@";
    }
    ok(!$server, 'incompatible backend refused');
    like($error, qr/Unblock::HTTP1::Server lacks drain\(\)/,
        'error explicitly identifies the unavailable backend capability');
    like($error, qr/install a compatible Unblock::HTTP1 build/,
        'error explains the required remediation');
    is($loop->count, 0, 'no listener or watcher created before rejection');
};

subtest 'supported Unblock HTTP1 starts and shuts down normally' => sub {
    my $loop = Linux::Event::Loop->new;
    ok(Unblock::HTTP1::Server->can('drain'), 'restored backend has drain');
    my $server = Linux::Event::HTTP::Server->new(options($loop));
    isa_ok($server, 'Linux::Event::HTTP::Server');
    my $completed = 0;
    $server->shutdown(grace => 0, on_complete => sub { ++$completed });
    is($completed, 1, 'idle shutdown completes synchronously');
    is($loop->count, 0, 'no watchers remain after shutdown');
};

done_testing;
