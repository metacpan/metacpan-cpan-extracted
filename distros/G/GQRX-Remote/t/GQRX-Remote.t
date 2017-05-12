#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 16;
use IO::Socket::INET;

BEGIN { use_ok('GQRX::Remote') };

my $TEST_HOST = $ENV{GQRX_REMOTE_TEST_HOST} || '127.0.0.1';
my $TEST_PORT = $ENV{GQRX_REMOTE_TEST_PORT} || 7356;

my $MOCK_SERVER_PID;

# This includes basic functionality tests for the API.
# Tests are not included for the recording/recorder APIs.

# If a server is listening on 127.0.0.1:$TEST_PORT, test against that.
# Otherwise, fork a mock server so that the tests can run.

# The default host and port to test against can be overridden
# with environment variables: GQRX_REMOTE_TEST_HOST and GQRX_REMOTE_TEST_PORT

sub run_tests {
    my $remote = new GQRX::Remote();

    ok (defined($remote), "Create new GQRX::Remote");

    is ($remote->disconnect(), undef, "Disconnect an unopened connection");
    is ($remote->get_frequency(), undef, "Get frequency on unopened connection");
    is ($remote->error(), "Failed to send: Not connected", "  Verify error()");

    ok ($remote->connect(), "Connect to GQRX");
    ok ($remote->connect(), "Connect while connected (reconnect)");

    ok ($remote->set_frequency(100000000), "Set frequency to 100MHz");
    is ($remote->get_frequency(), 100000000, "Get frequency");

    is ($remote->set_demodulator_mode("INVALID"), undef, "Set Demodulator Mode to INVALID");
    is ($remote->error(), "Set demodulator mode failed. Unexpected response: RPRT 1", "  Verify error()");
    is ($remote->set_demodulator_mode("WFM"), 1, "Set Demodulator Mode to WFM");
    is ($remote->get_demodulator_mode(), "WFM", "Get Demodulator Mode");

    is ($remote->set_squelch_threshold("-20.1"), 1, "Set Squelch Threshold to -20.1");
    is ($remote->get_squelch_threshold(), "-20.1", "Get Squelch Threshold");

    is ($remote->disconnect(), undef, "Disconnect connection");
}


sub start_server {
    # Create a mock server
    # If $TEST_HOST is not 127.0.0.1 or if the port is unavailable,
    # assume GQRX is already listening and test against the real
    # server.  Otherwise, fork and create a simple mock server.
    # Return the PID of the mock server or undef if none
    my $socket;
    my $select_set;
    my $connection;
    my $pid;
    my %state = ( # Fake state for our server
	frequency => 24000,
	demodulator_mode => 'AM',
	squelch_threshold => -20
	);

    if ($TEST_HOST eq '127.0.0.1') {
        $socket = IO::Socket::INET->new(Listen    => 5,
                                        LocalAddr => $TEST_HOST,
                                        LocalPort => $TEST_PORT,
                                        Proto     => 'tcp',
                                        ReuseAddr => 1);
    }

    if (! $socket) { # The port is in use or $TEST_HOST is not local, so test against a real server
	print STDERR "***  Testing against $TEST_HOST:$TEST_PORT\n";
	return;
    }

    print STDERR "***  Testing against mock server\n";

    if ($pid = fork()) { # We are the parent, so return the $pid
	return ($pid);
    }

    while (1) {
	my $line;
	# NOTE: For simplicity, a single connection at a time is supported
	$connection = $socket->accept(); # Wait for connections

	while ($line = $connection->getline()) { # Once we have a connection, read lines from it
	    my @command;

	    chomp ($line);
	    @command = split(' ', $line);

	    if (! $connection->connected() || $command[0] eq 'c') {
		$connection->close();
		last; # After closing the connection, fall back so we can accept() again
	    }
	    elsif ($command[0] eq 'f') {
		$connection->send($state{frequency} . "\n");
	    }
	    elsif ($command[0] eq 'F') {
		$state{frequency} = $command[1];
		$connection->send("RPRT 0\n");
	    }
	    elsif ($command[0] eq 'm') {
		$connection->send($state{demodulator_mode} . "\n");
	    }
	    elsif ($command[0] eq 'M') {
		if ($command[1] =~ /^(OFF|RAW|AM|FM|WFM|WFM_ST|WFM_ST_OIRT|LSZB|USB|CW|CWL|CWU)$/) {
		    $state{demodulator_mode} = $command[1];
		    $connection->send("RPRT 0\n");
		}
		else { # Fail on unknown demodulator modes
		    $connection->send("RPRT 1\n");
		}
	    }
	    elsif ($command[0] eq 'l' && $command[1] eq 'STRENGTH') {
		$connection->send("-12.3\n");
	    }
	    elsif ($command[0] eq 'l' && $command[1] eq 'SQL') {
		$connection->send($state{squelch_threshold} . "\n");
	    }
	    elsif ($command[0] eq 'L' && $command[1] eq 'SQL') {
		$state{squelch_threshold} = $command[2];
		$connection->send("RPRT 0\n");
	    }
	    else { # Fail on unknown commands
		$connection->send("RPRT 1\n");
	    }
	}
    }
}


sub main {
    $MOCK_SERVER_PID = start_server();
    run_tests();

    if ($MOCK_SERVER_PID) {
	kill(9, $MOCK_SERVER_PID);
    }
}


main();
