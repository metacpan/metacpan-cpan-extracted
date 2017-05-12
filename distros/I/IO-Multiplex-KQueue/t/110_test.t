# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::Socket;
use IO::Multiplex;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $mux = new IO::Multiplex;

print $mux ? "ok 2\n" : "not ok 2\n";

my $listen_socket = IO::Socket::INET->new(Proto     => 'tcp',
                                          Listen    => 4);

print $listen_socket ? "ok 3\n" : "not ok 3\n";

$port = $listen_socket->sockport;

$test_no = 4;

$SIG{ALRM} = sub { print "not ok $test_no\n"; exit };

alarm(20);

$mux->listen($listen_socket);
$mux->set_callback_object(__PACKAGE__);
$mux->set_timeout($listen_socket, 5);
$mux->loop;

my $client_socket;

sub mux_timeout
{
    print "ok 4\n";

    $test_no = 5;
    $client_socket = IO::Socket::INET->new(PeerAddr => "127.0.0.1",
                                           PeerPort => $port,
                                           Proto    => 'tcp');

    print $client_socket ? "ok 5\n" : "not ok 5\n";
    $test_no = 6;
}

sub mux_connection
{
    my $package = shift;
    my $mux     = shift;
    my $fh      = shift;

    print "ok 6\n";
    $test_no++;

    print $client_socket "Hello\n";
}

sub mux_input
{
    print "ok 7\n";
    shift; shift; shift;
    my $input = shift;

    return unless $$input =~ /\n/;

    print $$input eq "Hello\n" ? "ok 8\n" : "not ok 8\n";

    exit;
}
