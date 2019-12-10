use strict;
use warnings;

use Test::More tests => 278;
use lib 't/lib';
use LSF;

use POSIX 'strftime';

# strerror(3) messages on linux in the "C" locale are included below for reference

my @params = (LOG_AUTH, LOG_INFO, 'localhost', 'test');

for my $proto (LOG_TCP, LOG_UDP, LOG_UNIX) {
    eval { $CLASS->new($proto, '%^!/0', 0, @params) };
    like($@, qr/^Error in ->new/, "$proto: bad ->new call throws an exception");
}

for my $p (qw( tcp udp unix_dgram unix_stream )) {

    # basic behavior
    eval {
        my $server = make_server($p);
        ok($server->{listener}, "$p: listen") or diag("listen failed: $!");

        my $logger = $server->connect($::CLASS => @params);
        ok($logger, "$p: ->new returns something");
        is(ref $logger, $CLASS, "$p: ->new returns a $main::CLASS object");

        my $receiver = $server->accept;
        ok($receiver, "$p: accepted");

        my $time = time;
        for my $config (['without time'], ['with time', $time]) {
            my ($msg, @extra) = @$config;

            my @payload_params = (@params, $$, $msg, $time);
            my $expected = expected_payload(@payload_params, LOG_RFC3164);

            my $sent = eval { $logger->send($msg, @extra) };
            ok(!$@, "$p: ->send $msg doesn't throw");
            is($sent, length $expected, "$p: ->send $msg sent whole payload");

            my $found = wait_for_readable($receiver);
            ok($found, "$p: didn't time out while waiting for data $msg");

            if ($found) {
                $receiver->recv(my $buf, 256);

                ok($buf =~ /^<38>/, "$p: ->send $msg has the right priority");
                ok($buf =~ /$msg$/, "$p: ->send $msg has the right message");
                is($buf, expected_payload(@payload_params, LOG_RFC3164), "$p: ->send $msg has correct payload");
            }
        }
    };
    diag($@) if $@;

    # write accessors
    eval {

        my $server = make_server($p);
        my $logger = $server->connect($CLASS => @params);

        # ignore first connection for stream protos since reconnect is expected
        $server->accept();

        eval {
            # this method triggers a reconnect for stream protocols
            $logger->set_receiver($server->proto, $server->address);
        };
        ok(!$@, "$p: ->set_receiver doesn't throw");

        eval { $logger->set_priority(LOG_NEWS, LOG_CRIT) };
        ok(!$@, "$p: ->set_priority doesn't throw");

        eval { $logger->set_sender('otherhost') };
        ok(!$@, "$p: ->set_sender doesn't throw");

        eval { $logger->set_name('test2') };
        ok(!$@, "$p: ->set_name doesn't throw");

        eval { $logger->set_pid(12345) };
        ok(!$@, "$p: ->set_pid doesn't throw");

        my $receiver = $server->accept;

        my $msg = "testing 3";
        my @payload_params = (LOG_NEWS, LOG_CRIT, 'otherhost', 'test2', 12345, $msg, time);
        my $expected = expected_payload(@payload_params, LOG_RFC3164);

        my $sent = eval { $logger->send($msg) };
        ok(!$@, "$p: ->send after accessors doesn't throw");
        is($sent, length $expected, "$p: ->send sent whole payload");

        my $found = wait_for_readable($receiver);
        ok($found, "$p: didn't time out while listening");

        if ($found) {
            $receiver->recv(my $buf, 256);
            ok($buf, "$p: send after set_receiver went to correct port");
            ok($buf =~ /^<58>/, "$p: ->send after set_priority has the right priority");
            ok($buf =~ /otherhost/, "$p: ->send after set_sender has the right sender");
            ok($buf =~ /test2\[/, "$p: ->send after set_name has the right name");
            ok($buf =~ /\[12345\]/, "$p: ->send after set_name has the right pid");
            ok($buf =~ /$msg$/, "$p: ->send after accessors sends right message");
            is($buf, expected_payload(@payload_params, LOG_RFC3164), "$p: ->send $msg has correct payload");
        }
    };
    diag($@) if $@;

    # RFC5424 format
    eval {

        my $server = make_server($p);
        my $logger = $server->connect($CLASS => @params);

        # ignore first connection for stream protos since reconnect is expected
        $server->accept();

        eval {
            # this method triggers a reconnect for stream protocols
            $logger->set_receiver($server->proto, $server->address);
        };
        ok(!$@, "$p: ->set_receiver doesn't throw");

        eval { $logger->set_priority(LOG_NEWS, LOG_CRIT) };
        ok(!$@, "$p: ->set_priority doesn't throw");

        eval { $logger->set_sender('otherhost') };
        ok(!$@, "$p: ->set_sender doesn't throw");

        eval { $logger->set_name('test2') };
        ok(!$@, "$p: ->set_name doesn't throw");

        eval { $logger->set_pid(12345) };
        ok(!$@, "$p: ->set_pid doesn't throw");

        eval { $logger->set_format(LOG_RFC5424) };
        ok(!$@, "$p: ->set_format doesn't throw");

        my $receiver = $server->accept;

        my $msg = "testing 3";
        my @payload_params = (LOG_NEWS, LOG_CRIT, 'otherhost', 'test2', 12345, $msg, time);
        my $expected = expected_payload(@payload_params, LOG_RFC5424);

        my $sent = eval { $logger->send($msg) };
        ok(!$@, "$p: ->send after accessors doesn't throw");
        is($sent, length $expected, "$p: ->send sent whole payload");

        my $found = wait_for_readable($receiver);
        ok($found, "$p: didn't time out while listening");

        if ($found) {
            $receiver->recv(my $buf, 256);
            ok($buf, "$p: send after set_receiver went to correct port");
            ok($buf =~ /^<58>1/, "$p: ->send after set_priority has the right priority");
            ok($buf =~ / otherhost /, "$p: ->send after set_sender has the right sender");
            ok($buf =~ / test2 /, "$p: ->send after set_name has the right name");
            ok($buf =~ / 12345 /, "$p: ->send after set_name has the right pid");
            ok($buf =~ / $msg$/, "$p: ->send after accessors sends right message");
            is($buf, expected_payload(@payload_params, LOG_RFC5424), "$p: ->send $msg has correct payload");
        }
    };
    diag($@) if $@;

    # LOG_RFC3164_LOCAL format
    eval {
        my @params = (LOG_AUTH, LOG_INFO, 'localhost', 'test0');
        my $server = make_server($p);
        ok($server->{listener}, "$p: listen") or diag("listen failed: $!");

        my $logger = $server->connect($::CLASS => @params);
        ok($logger, "$p: ->new returns something");
        is(ref $logger, $CLASS, "$p: ->new returns a $main::CLASS object");

        my $receiver = $server->accept;
        ok($receiver, "$p: accepted");

        my $time = time;
        for my $config (['without time'], ['with time', $time]) {
            my ($msg, @extra) = @$config;

            eval { $logger->set_format(LOG_RFC3164_LOCAL) };
            ok(!$@, "$p: ->set_format doesn't throw");

            my @payload_params = (@params, $$, $msg, $time);
            my $expected = expected_payload(@payload_params, LOG_RFC3164_LOCAL);

            my $sent = eval { $logger->send($msg, @extra) };
            ok(!$@, "$p: ->send $msg doesn't throw");
            is($sent, length $expected, "$p: ->send $msg sent whole payload");

            my $found = wait_for_readable($receiver);
            ok($found, "$p: didn't time out while waiting for data $msg");

            if ($found) {
                $receiver->recv(my $buf, 256);
            
                ok($buf =~ /^<38>/, "$p: ->send $msg has the right priority");
                ok($buf =~ /$msg$/, "$p: ->send $msg has the right message");
                is($buf, expected_payload(@payload_params, LOG_RFC3164_LOCAL), "$p: ->send $msg has correct payload");
            }
        }
    };
    diag($@) if $@;

    # test failure behavior when server is unreachable
    eval {

        # test when server is initially available but goes away
        my $server = make_server($p);
        my $logger = $server->connect($CLASS => @params);
        $server->close();

        my $piped = 0;
        local $SIG{PIPE} = sub { $piped++ };
        eval { $logger->send("testclosed") };
        if ($p eq 'tcp') {
            # "Connection reset by peer" on linux, sigpipe on bsds
            ok($@ || $piped, "$p: ->send throws on server close");
        }
        elsif ($p eq 'udp') {
            ok(!$@, "$p: ->send doesn't throw on server close");
        }
        elsif ($p eq 'unix_dgram') {
            # "Connection refused"
            like($@, qr/Error while sending/, "$p: ->send throws on server close");
        }
        elsif ($p eq 'unix_stream') {
            ok($piped, "$p: ->send raises SIGPIPE on server close");
        }

        # test when server is not initially available

        # increment peer port to get one that (probably) wasn't recently used;
        # otherwise UDP/ICMP business doesn't work right on at least linux 2.6.18
        $server->{address}[1]++;

        if ($p eq 'udp') {
            # connectionless udp should fail on 2nd call to ->send, after ICMP
            # error is noticed by kernel

            my $logger = $server->connect($CLASS => @params);
            ok($logger, "$p: ->new doesn't throw on connect to missing server");

            for my $n (1..2) {
                eval { $logger->send("test$n") };
                ok(!$@, "$p: odd ->send to missing server doesn't throw");

                eval { $logger->send("test$n") };
                # "Connection refused"
                like($@, qr/Error while sending/, "$p: even ->send to missing server does throw");
            }
        }
        else {
            # connected protocols should fail on connect, i.e. ->new
            eval { $CLASS->new($server->proto, $server->address, @params); };
            like($@, qr/^Error in ->new/, "$p: ->new throws on connect to missing server");
        }
    };
    diag($@) if $@;
}

# test LOG_UNIX with nonexistent/non-sock endpoint
{
    my $filename = test_dir . "/fake";

    my $fake_server = DgramServer->new(
        listener    => 1,
        proto       => LOG_UNIX,
        address     => [$filename, 0],
    );

    eval {
        $fake_server->connect($CLASS => @params);
    };
    # "No such file"
    like($@, qr/Error in ->new/, 'unix: ->new with missing file throws');

    open my $fh, '>', $filename or die "couldn't create fake socket $filename: $!";

    eval { $fake_server->connect($CLASS => @params); };
    # "Connection refused"
    like($@, qr/Error in ->new/, 'unix: ->new with non-sock throws');
}

# check that bad methods are reported for the caller
eval {
    my $logger = $CLASS->new(LOG_UDP, 'localhost', 514, LOG_LOCAL0, LOG_INFO, "mymachine", "logger");
    $logger->nonexistent_method();
};
like($@, qr{at t/01-Log-Syslog-Fast.}, 'error in caller'); # not Fast.pm

sub expected_payload {
    my ($facility, $severity, $sender, $name, $pid, $msg, $time, $format) = @_;
    my $time_format = "%h %e %T";
    my $msg_format = "<%d>%s %s %s[%d]: %s";

    if ($format == LOG_RFC3164_LOCAL) {
        $msg_format = "<%d>%s %.0s%s[%d]: %s";
    }

    if ($format == LOG_RFC5424) {
        $time_format = "%Y-%m-%dT%H:%M:%S%z";
        $msg_format = "<%d>1 %s %s %s %d - - %s";
    }
    my $timestr = strftime($time_format, localtime($time));
    if ($format == LOG_RFC5424) {
        $timestr =~ s/(\d{2})$/:$1/;
    }
    return sprintf $msg_format,
        ($facility << 3) | $severity,
        $timestr,
        $sender, $name, $pid, $msg;
}

# vim: filetype=perl

1;
