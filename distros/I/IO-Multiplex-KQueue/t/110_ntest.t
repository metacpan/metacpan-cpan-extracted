# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::Socket;
use IO::Multiplex;
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
$loaded = 1;

my $test_msg1 = "Sync test\n";
my $test_msg2 = "Hello\n";

print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $mux = new IO::Multiplex;

print $mux ? "ok 2\n" : "not ok 2\n";

my $client_socket;
my $server_socket;
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
#print STDERR "DEBUG: Doing loop...\n";
$mux->loop;
#print STDERR "DEBUG: Done with loop.\n";

print "ok 9\n";

$mux->remove($client_socket);
$mux->remove($server_socket);

print "ok 10\n";

my $flags = 0;
fcntl($server_socket, F_GETFL, $flags)
    or die "fcntl F_GETFL: $!\n";
fcntl($server_socket, F_SETFL, $flags & ~O_NONBLOCK)
    or die "fcntl F_SETFL $!\n";

if (syswrite ($client_socket, $test_msg1, length $test_msg1) == 10) {
    print "ok 11\n";
} else {
    print "not ok 11\n";
}
my $buf;

#print STDERR "DEBUG: doing sysread...\n";
if (sysread ($server_socket, $buf, 10) == 10) {
    print "ok 12\n";
} else {
    print "not ok 12\n";
}

if ( $buf eq $test_msg1 ) {
    print "ok 13\n";
} else {
    print "not ok 13\n";
}

sub mux_timeout
{
    #print STDERR "DEBUG: mux_timeout reached!\n";
    print "ok 4\n";
    
    $client_socket = IO::Socket::INET->new(PeerAddr => "127.0.0.1",
                                           PeerPort => $port,
                                           Proto    => 'tcp');
    $client_socket->autoflush(1);
    print $client_socket ? "ok 5\n" : "not ok 5\n";
    $test_no = 6;
}

sub mux_connection
{
    my $package    = shift;
    my $mux        = shift;
    $server_socket = shift;
    $server_socket->autoflush(1);
    $client_socket->autoflush(1);
    print "ok 6\n";
    $test_no++;

    syswrite($client_socket, $test_msg2, length $test_msg2);
}

sub mux_input
{
    print "ok 7\n";
    shift; shift; shift;
    my $input = shift;

    return unless $$input =~ /\n/;

    print $$input eq $test_msg2 ? "ok 8\n" : "not ok 8\n";

    $mux->endloop;
}
