
use Test::More tests => 11;

use IO::Socket::INET::Daemon;
use IO::Socket::INET;

use POSIX ":sys_wait_h";


my $host = new IO::Socket::INET::Daemon(
	port => 5000,  
	timeout => 20,
);

ok($host, 'daemon created');

$host->callback(data => \&data, add => \&add, remove => \&remove);

my $pid = fork;

if(!$pid) {
	$host->run;
	exit;
}

ok(sleep 1, 'sleep a second');

my $client = new IO::Socket::INET(
	PeerHost => 'localhost',
	PeerPort => 5000,
);

my $reply;

ok($client && $client->connected, 'connected');

$reply = $client->getline;
$reply =~ s/\r?\n//;

ok($reply && ($reply eq 'WELCOME'), 'got message');
ok($client->print("TEST\n"), 'message sent');

$reply = $client->getline;
$reply =~ s/\r?\n//;

ok($reply eq 'REPLY: TEST', 'got reply');
ok($client->print("quit\n"), 'quit sent');
$client->shutdown(SHUT_RDWR);
$client->close;

$client = new IO::Socket::INET(
	PeerHost => 'localhost',
	PeerPort => 5000,
);

ok($client && $client->connected, 'connected again');

$reply = $client->getline;
$reply =~ s/\r?\n//;

ok($reply && ($reply eq 'WELCOME'), 'got message');
ok($client->print("stop\n"), 'sent stop');
$client->shutdown(SHUT_RDWR);
$client->close;

ok(waitpid($pid, WNOHANG) != -1, 'server is gone');

sub add {
	my $io = shift;

	$io->print("WELCOME\n");

	return !0;
}

sub remove {
	my $io = shift;
}

sub data {
	my ($io, $host) = @_;

	my $line = $io->getline;

	$line =~ s/\r?\n//;

	if($line eq 'quit') {
		return 0;
	}    
	elsif($line eq 'stop') {
		$host->stop;
	}
	else {
		$io->print("REPLY: $line\n");
		return !0;
	}
}

