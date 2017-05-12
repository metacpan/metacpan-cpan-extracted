use Test::More tests => 10;
use IO::Select;
use IO::Socket::INET;
use POSIX 'strftime';

use lib 't/lib';
use LSF;

# strerror(3) messages on linux in the "C" locale are included below for reference

my @params = (LOG_AUTH, LOG_INFO, 'localhost', 'test');

for my $p (qw(udp)) {

    # basic behavior
    eval {
        my $server = make_server($p);
        ok($server->{listener}, "$p: listen") or diag("listen failed: $!");

        my $logger = $server->connect($CLASS => @params);
        ok($logger, "$p: ->new returns something");
        is(ref $logger, $CLASS, "$p: ->new returns a $CLASS object");

        my $receiver = $server->accept;
        ok($receiver, "$p: accepted");

        my $time = time;

        my $msg = '.' x 4500; # larger than INITIAL_BUFSIZE

        my @payload_params = (@params, $$, $msg, $time);
        my $expected = expected_payload(@payload_params);

        my $sent = eval { $logger->send($msg) };
        ok(!$@, "$p: ->send doesn't throw");
        is($sent, length $expected, "$p: ->send sent whole payload");

        my $found = wait_for_readable($receiver);
        ok($found, "$p: didn't time out while waiting for data");

        if ($found) {
            $receiver->recv(my $buf, 5000);

            ok($buf =~ /^<38>/, "$p: ->send has the right priority");
            ok($buf =~ /$msg$/, "$p: ->send has the right message");
            ok(payload_ok($buf, @payload_params), "$p: ->send has correct payload");
        }
    };
    diag($@) if $@;
}

sub expected_payload {
    my ($facility, $severity, $sender, $name, $pid, $msg, $time) = @_;
    return sprintf "<%d>%s %s %s[%d]: %s",
        ($facility << 3) | $severity,
        strftime("%h %e %T", localtime($time)),
        $sender, $name, $pid, $msg;
}

sub payload_ok {
    my ($payload, @payload_params) = @_;
    for my $offset (0, -1, 1) {
        my $allowed = expected_payload(@payload_params);
        return 1 if $allowed eq $payload;
    }
    return 0;
}

1;
