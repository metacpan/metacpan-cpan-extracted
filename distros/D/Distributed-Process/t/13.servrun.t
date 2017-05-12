#!perl -T
use Test::More;
use strict;

use lib 't';

use Distributed::Process;

use Socket qw/ :crlf /;
use IO::Socket;
$/ = CRLF;

my $n_workers = 3;
plan tests => 3 * $n_workers;
my $port = 8147;

for ( 1 .. $n_workers ) {
    my $pid = fork;

    if ( !$pid ) {
	require TestRun;
	require Distributed::Process::Client;
	sleep 2;
	my $c = new Distributed::Process::Client
	    -worker_class => 'TestRun',
	    -host => 'localhost',
	    -port => $port,
            -id   => "wrk$_",
	;
	$c->run();
	exit 0;
    }
}

require TestRun;
@TestRun::data = qw/ milliways heartofgold fortytwo zaphod magrathea trillian /;
require Distributed::Process::Master;
require Distributed::Process::Server;
my ($server, $parent) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $server_pid = fork;
if ( ! $server_pid ) {
    die "Cannot fork: $!" unless defined($server_pid);
    $server->close();
    my $m = new Distributed::Process::Master
	-worker_class => 'TestRun',
        -n_workers => $n_workers,
        -in_handle => $parent,
        -out_handle => $parent,
    ;
    my $s = new Distributed::Process::Server master => $m, port => $port;
    $s->listen();
    exit 0;
}
$parent->close();

while ( <$server> ) {
    last if /ready to run/;
}
print $server "/run" . CRLF;
$/ = CRLF;
my %expected = map { $_ => 1 } @TestRun::data;
while ( <$server> ) {
    chomp;
    /ok/ and print $server "/quit" . CRLF;
    /\t/ or next;
    my ($id, $date, $msg) = split /\t/;
    my ($n) = $id =~ /(\d+)/;
    for ( $msg ) {
	if ( /next is (.*)/ ) {
	    ok($expected{$1}--);
	}
	elsif ( /Square of (\d+) is (\d+)/ ) {
	    is($2, $1 ** 2);
	}
    }
}

