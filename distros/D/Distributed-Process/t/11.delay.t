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
plan tests => 3 * ($n_workers - 1);
my $port = 8147;

for ( 1 .. $n_workers ) {
    my $pid = fork;

    if ( !$pid ) {
	require Delay;
	require Distributed::Process::Client;
	sleep 2;
	my $c = new Distributed::Process::Client
	    -worker_class => 'Delay',
	    -host => 'localhost',
	    -port => $port,
            -id  => "wrk$_",
	;
	$c->run();
	exit 0;
    }
}

require Delay;
require Distributed::Process::Master;
require Distributed::Process::Server;
my ($server, $parent) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $server_pid = fork;
if ( ! $server_pid ) {
    die "Cannot fork: $!" unless defined($server_pid);
    $server->close();
    my $m = new Distributed::Process::Master
	-worker_class => 'Delay',
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

my %result = ();
while ( <$server> ) {
    last if /ready to run/;
}

print $server "/run" . CRLF;
while ( <$server> ) {
    chomp;
    /^ok/ and print $server "/quit" . CRLF;
    /\t/ or next;
    my ($id, $date, $msg) = split /\t/;
    push @{$result{$msg} ||= []}, $date;
}

foreach my $test ( sort keys %result ) {
    $_ = $result{$test};
    for ( @$_ ) {
        my ($Y, $m, $d, $H, $M, $S) = /(\d{4})(\d\d)(\d\d)-(\d\d)(\d\d)(\d\d)/;
        $Y -= 1900;
        $m--;
        $_ = timelocal $S, $M, $H, $d, $m, $Y;
    }
    @$_ = sort @$_;
    my $x = shift @$_;
    while ( @$_ ) {
        my $y = shift @$_;
        my $diff = abs($x - $y);
        ok($diff == 4 || $diff == 5, "$test: comparing $x and $y");
        $x = $y;
    }
}
