use strict;
use warnings;

use Test::More;
use IO::Socket::INET;

use EV;
use EV::Redis;

# a server that answers the first request with scripted bytes and holds the
# connection; returns the port and a cleanup closure
sub fake_server {
    my (@replies) = @_;
    my $l = IO::Socket::INET->new(
        Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
    ) or die "listen: $!";
    my ($conn, $watch);
    my $accept = EV::io $l, EV::READ, sub {
        $conn = $l->accept or return;
        $watch = EV::io $conn, EV::READ, sub {
            my $buf;
            sysread $conn, $buf, 65536;
            undef $watch;
            for my $data (@replies) {
                my $off = 0;
                while ($off < length $data) {
                    my $n = syswrite $conn, $data, length($data) - $off, $off;
                    die "write: $!" if !defined $n || $n <= 0;
                    $off += $n;
                }
            }
        };
    };
    return ($l->sockport, sub { undef $accept; undef $watch; undef $conn; });
}

sub run_client {
    my ($port, $setup) = @_;
    my ($error, $disconnected);
    my $r = EV::Redis->new(
        on_error => sub { $error = $_[0] },
        on_disconnect => sub { $disconnected++; EV::break; },
    );
    $r->connect('127.0.0.1', $port);
    $setup->($r);
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    my $connected = $r->is_connected;
    my $was_disconnected = $disconnected;
    $r->disconnect if $connected;
    return ($r, $error, $was_disconnected, $connected);
}

# positive control: the harness itself answers
{
    my ($port, $close) = fake_server("+PONG\r\n");
    my ($got, $cb_err);
    my ($r, $error) = run_client($port, sub {
        $_[0]->command('PING', sub { ($got, $cb_err) = @_; EV::break; });
    });
    $close->();
    is $got, 'PONG', 'scripted server answers';
    is $cb_err, undef, 'no callback error';
    is $error, undef, 'no connection error';
}

# attribute metadata is dropped and the reply it belongs to arrives as usual
{
    my ($port, $close) = fake_server("|1\r\n\$3\r\nttl\r\n:99\r\n+PONG\r\n");
    my ($got, $cb_err);
    my ($r, $error, $disconnected, $connected) = run_client($port, sub {
        $_[0]->command('PING', sub { ($got, $cb_err) = @_; EV::break; });
    });
    $close->();
    is $got, 'PONG', 'attribute: the data reply arrives';
    is $cb_err, undef, 'attribute: no callback error';
    is $error, undef, 'attribute: no connection error';
    is $disconnected, undef, 'attribute: stays connected';
    ok $connected, 'attribute: still connected';
}

# an attribute inside an array takes an element's place: nothing may reach
# the next command's callback
{
    my ($port, $close) = fake_server("*2\r\n|1\r\n+meta\r\n+val\r\n:1\r\n:2\r\n");
    my @calls;
    my ($r, $error, $disconnected) = run_client($port, sub {
        $_[0]->command('GET', 'a', sub { push @calls, ['first', @_] });
        $_[0]->command('GET', 'b', sub { push @calls, ['second', @_] });
    });
    $close->();
    is_deeply [map { [$_->[0], $_->[1]] } @calls], [['first', undef], ['second', undef]],
        'nested attribute: neither command gets a reply';
    like $calls[0][2] // '', qr/Protocol error/, 'nested attribute: first command fails';
    like $error // '', qr/attribute/, 'nested attribute: protocol error';
    is $disconnected, 1, 'nested attribute: disconnected';
}

# a second reply with no command waiting for it
{
    my ($port, $close) = fake_server("+PONG\r\n+EXTRA\r\n");
    my ($got, $cb_err);
    my ($r, $error, $disconnected, $connected) = run_client($port, sub {
        $_[0]->command('PING', sub { ($got, $cb_err) = @_; });
    });
    $close->();
    is $got, 'PONG', 'unsolicited reply: the awaited reply still arrives';
    is $cb_err, undef, 'unsolicited reply: no callback error';
    like $error // '', qr/unsolicited reply/, 'unsolicited reply: protocol error';
    is $disconnected, 1, 'unsolicited reply: disconnected';
    ok !$connected, 'unsolicited reply: not connected';
}

# a message-shaped array the subscribed parser cannot take
{
    my ($port, $close) = fake_server(
        "*3\r\n\$9\r\nsubscribe\r\n\$2\r\nch\r\n:1\r\n",
        "*3\r\n:1\r\n:2\r\n:3\r\n",
    );
    my @calls;
    my ($r, $error, $disconnected) = run_client($port, sub {
        $_[0]->subscribe('ch', sub { push @calls, [@_] });
    });
    $close->();
    is scalar(@calls), 2, 'bad message: confirm then error';
    is_deeply $calls[0][0], ['subscribe', 'ch', 1], 'bad message: confirm arrives';
    like $calls[1][1] // '', qr/Protocol error/, 'bad message: teardown error';
    like $error // '', qr/malformed pub\/sub/, 'bad message: protocol error';
    is $disconnected, 1, 'bad message: disconnected';
}

# a subscribe confirmation for a channel with no subscription
{
    my ($port, $close) = fake_server(
        "*3\r\n\$9\r\nsubscribe\r\n\$5\r\nother\r\n:1\r\n",
    );
    my @calls;
    my ($r, $error, $disconnected) = run_client($port, sub {
        $_[0]->subscribe('ch', sub { push @calls, [@_] });
    });
    $close->();
    is scalar(@calls), 1, 'unknown confirm: only the teardown error';
    like $calls[0][1] // '', qr/Protocol error/, 'unknown confirm: teardown error';
    like $error // '', qr/without a subscription/, 'unknown confirm: protocol error';
    is $disconnected, 1, 'unknown confirm: disconnected';
}

# an unsubscribe confirmation without an integer count
{
    my ($port, $close) = fake_server(
        "*3\r\n\$9\r\nsubscribe\r\n\$2\r\nch\r\n:1\r\n",
        "*3\r\n\$11\r\nunsubscribe\r\n\$2\r\nch\r\n\$1\r\nx\r\n",
    );
    my @calls;
    my ($r, $error, $disconnected) = run_client($port, sub {
        $_[0]->subscribe('ch', sub { push @calls, [@_] });
    });
    $close->();
    is scalar(@calls), 2, 'bad unsub count: confirm then error';
    like $calls[1][1] // '', qr/Protocol error/, 'bad unsub count: teardown error';
    like $error // '', qr/without a subscriber count/, 'bad unsub count: protocol error';
    is $disconnected, 1, 'bad unsub count: disconnected';
}

# a truncated subscribe-shaped push
{
    my ($port, $close) = fake_server(
        "*3\r\n\$9\r\nsubscribe\r\n\$2\r\nch\r\n:1\r\n",
        ">1\r\n\$9\r\nsubscribe\r\n",
    );
    my @calls;
    my ($r, $error, $disconnected) = run_client($port, sub {
        $_[0]->subscribe('ch', sub { push @calls, [@_] });
    });
    $close->();
    is scalar(@calls), 2, 'short push: confirm then error';
    like $calls[1][1] // '', qr/Protocol error/, 'short push: teardown error';
    like $error // '', qr/short pub\/sub/, 'short push: protocol error';
    is $disconnected, 1, 'short push: disconnected';
}

# a truncated unsubscribe-shaped push
{
    my ($port, $close) = fake_server(
        "*3\r\n\$9\r\nsubscribe\r\n\$2\r\nch\r\n:1\r\n",
        ">2\r\n\$11\r\nunsubscribe\r\n\$2\r\nch\r\n",
    );
    my @calls;
    my ($r, $error, $disconnected) = run_client($port, sub {
        $_[0]->subscribe('ch', sub { push @calls, [@_] });
    });
    $close->();
    is scalar(@calls), 2, 'short unsub: confirm then error';
    like $calls[1][1] // '', qr/Protocol error/, 'short unsub: teardown error';
    like $error // '', qr/short pub\/sub/, 'short unsub: protocol error';
    is $disconnected, 1, 'short unsub: disconnected';
}

# an over-deep push is dropped with an error instead of reaching on_push
{
    my $hello = "%7\r\n\$6\r\nserver\r\n\$5\r\nredis\r\n\$7\r\nversion\r\n\$3\r\n8.0"
        . "\r\n\$5\r\nproto\r\n:3\r\n\$2\r\nid\r\n:1\r\n\$4\r\nmode\r\n\$10\r\nstandalone"
        . "\r\n\$4\r\nrole\r\n\$6\r\nmaster\r\n\$7\r\nmodules\r\n*0\r\n";
    my ($port, $close) = fake_server(
        $hello,
        ">2\r\n\$10\r\ninvalidate\r\n*1\r\n\$4\r\nkey1\r\n",
        ">1\r\n" . ("*1\r\n" x 600) . ":7\r\n",
    );
    my (@pushes, $error, $disconnected, $herr);
    my $r = EV::Redis->new(
        on_error => sub { $error = $_[0]; EV::break },
        on_disconnect => sub { $disconnected++; EV::break; },
    );
    $r->connect('127.0.0.1', $port);
    $r->on_push(sub { push @pushes, [@_] });
    $r->hello(3, sub { $herr = $_[1] });
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    $close->();
    is $herr, undef, 'deep push: hello answered';
    is scalar(@pushes), 1, 'deep push: only the shallow push delivered';
    is_deeply $pushes[0][0], ['invalidate', ['key1']], '... with its content';
    like $error // '', qr/nesting depth/, 'deep push: error signalled';
    is $disconnected, undef, 'deep push: stays connected';
    ok $r->is_connected, 'deep push: still connected';
    $r->disconnect;
}

done_testing;
