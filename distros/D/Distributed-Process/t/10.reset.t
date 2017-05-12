#!perl -T
use Test::More;
use strict;

use lib 't';

use Distributed::Process;

use Socket qw/ :crlf /;
use IO::Socket;
use IO::Select;
$/ = CRLF;

my $n_workers = 3;
plan tests => $n_workers + 3;
my $port = 8147;

for ( 1 .. $n_workers ) {
    my $pid = fork;

    if ( !$pid ) {
	require Session;
	require Distributed::Process::Client;
	sleep 4;
	our $ID = "wrk$_";
	my $c = new Distributed::Process::Client
	    -worker_class => 'Session',
	    -host => 'localhost',
	    -port => $port,
            -id   => $ID,
	;
	$c->run();
	exit 0;
    }
}

our $ID = 'server';

require Session;
require Distributed::Process::Master;
require Distributed::Process::Server;
my ($server, $parent) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $server_pid = fork;
if ( ! $server_pid ) {
    die "Cannot fork: $!" unless defined($server_pid);
    $server->close();
    my $m = new Distributed::Process::Master
        -worker_class => 'Session',
        -n_workers => $n_workers,
        -in_handle => $parent,
        -out_handle => $parent,
    ;
    my $s = new Distributed::Process::Server master => $m, port => $port;
    $s->listen();
    exit 0;
}
$parent->close();

for ( 1 .. $n_workers ) {
    my $line = <$server>;
    like($line, qr/new worker arrived/, "Arrival of worker #$_");
}
my $line = <$server>;
like($line, qr/ready to run/, "Workers all there");
print $server "/run" . CRLF;
my $n;
while ( <$server> ) {
    /^ok/ && last || $n++;
}
is($n, $n_workers, 'Received one result line per worker');
print $server "/reset" . CRLF;
sleep 1;
print $server "/run" . CRLF;
$n = 0;
while ( <$server> ) {
    /^ok/ && last || $n++;
}
print $server "/quit" . CRLF;
is($n, $n_workers, 'Received no more than one result line per worker');
