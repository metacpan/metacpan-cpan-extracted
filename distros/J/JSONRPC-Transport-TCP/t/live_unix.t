use Test::Base;
use File::Temp qw/tempdir/;

eval "use AnyEvent::JSONRPC::Lite::Server";
plan skip_all => "AnyEvent::JSONRPC::Lite::Server required to run this test" if $@;

plan tests => 4;

my $dir = tempdir( CLEANUP => 1 );
my $port = "$dir/socket";

my $child = fork;
if ($child == 0) {
    # create test server
    my $server = AnyEvent::JSONRPC::Lite::Server->new(
        address => 'unix/',
        port    => $port,
    );
    $server->reg_cb(
        echo => sub {
            my ($r, @args) = @_;
            $r->result(@args);
        },
        large_response => sub {
            my ($r) = @_;
            $r->result({
                large_text => 'x' x 1024,
            });
        },
    );
    AnyEvent->condvar->recv;
}
elsif (!defined $child) {
    die "fork failed: $!";
}

sleep 1; # XXX: wait for server available

use JSONRPC::Transport::TCP;

my $client = JSONRPC::Transport::TCP->new(
    host => 'unix/',
    port => $port,
);

{
    ok(my $res = $client->call('echo', 'foo'));
    is($res->result, 'foo');
}

{
    ok(my $res = $client->call('large_response'));
    is($res->result->{large_text}, 'x'x1024);
}

kill 9, $child;
