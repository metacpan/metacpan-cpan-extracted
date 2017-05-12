#!perl -T
use Test::More;
use strict;

use lib 't';
use Time::Local;

use Distributed::Process;

use Socket qw/ :crlf /;
use IO::Socket;
use IO::Select;
$/ = CRLF;

my $n_workers = 5;
plan tests => 2 * ($n_workers - 1);
my $port = 8147;

for ( 1 .. $n_workers ) {
    my $pid = fork;

    if ( !$pid ) {
	require Synchro;
	require Distributed::Process::Client;
	sleep 2;
	my $c = new Distributed::Process::Client
	    -worker_class => 'Synchro',
	    -host => 'localhost',
	    -port => $port,
            -id  => "wrk$_",
	;
	$c->run();
	exit 0;
    }
}

require Synchro;
require Distributed::Process::Master;
require Distributed::Process::Server;
my ($server, $parent) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $server_pid = fork;
if ( ! $server_pid ) {
    die "Cannot fork: $!" unless defined($server_pid);
    $server->close();
    my $m = new Distributed::Process::Master
	-worker_class => 'Synchro',
        -n_workers => $n_workers,
        -in_handle => $parent,
        -out_handle => $parent,
	-frequency => .25,
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
my %before;
my %after;
while ( <$server> ) {
    chomp;
    /^ok/ and print $server "/quit" . CRLF;
    /\t/ or next;
    my ($id, $date, $msg) = split /\t/;
    my ($n) = $id =~ /(\d+)/;
    my ($Y, $m, $d, $H, $M, $S) = $date =~ /(\d{4})(\d\d)(\d\d)-(\d\d)(\d\d)(\d\d)/;
    $Y -= 1900;
    $m--;
    my $t = timelocal $S, $M, $H, $d, $m, $Y;
    no strict 'refs';
    if ( $msg =~ /before synchro/ ) {
	$before{$n} = [ $date, $t ];
    }
    elsif ( $msg =~ /after synchro/ ) {
	$after{$n} = [ $date, $t ];
    }
}

for ( 2 .. $n_workers ) {
    my $d = $before{$_}[1] - $before{$_ - 1}[1];
    is($d, 2, "should be 2 seconds between $before{$_}[0] and $before{$_ - 1}[0] (really is $d)");
    $d = $after{$_}[1] - $after{$_ - 1}[1];
    is($d, 0, "should be 0 seconds between $after{$_}[0] and $after{$_ - 1}[0] (really is $d)");
}
