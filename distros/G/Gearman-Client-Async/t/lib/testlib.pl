#!/usr/bin/perl

use strict;
use warnings;
our $Bin;
use FindBin qw( $Bin );

# for working out of svn:
use lib "$Bin/../../Gearman/lib";
$ENV{PERL5LIB} .= ":$Bin/../../Gearman/lib";

# for disttest, which is another layer down.  :(
use lib "$Bin/../../../Gearman/lib";
$ENV{PERL5LIB} .= ":$Bin/../../../Gearman/lib";

use Gearman::Client::Async;
use POSIX qw( :sys_wait_h );
use List::Util qw(first);;
use IO::Socket::INET;

Danga::Socket->SetLoopTimeout(100);

our %Children;

END { kill_children() }

sub start_server {
    my($port) = @_;
    my @loc = ("$Bin/../../../../server/gearmand",    # using svn
               "$Bin/../../../../../server/gearmand", # using svn, with disttest
               '/usr/bin/gearmand',            # where some distros might put it
               '/usr/sbin/gearmand',           # where other distros might put it
               );
    my $server = first { -e $_ } @loc
        or return 0;

    my $pid = start_child([ $server, '-p', $port ]);
    $Children{$pid} = 'S';
    wait_for_port($port);
    return $pid;
}

sub start_worker {
    my($port, $num) = @_;
    my $worker = "$Bin/worker.pl";
    my $servers = join ',',
                  map '127.0.0.1:' . (PORT + $_),
                  0..$num-1;
    my $pid = start_child([ $worker, '-s', $servers ]);
    $Children{$pid} = 'W';
    return $pid;
}

sub start_child {
    my($cmd) = @_;
    my $pid = fork();
    die $! unless defined $pid;
    unless ($pid) {
        exec 'perl', '-Iblib/lib', '-Ilib', @$cmd or die $!;
    }
    $pid;
}

sub kill_children {
    kill INT => keys %Children;
}

sub wait_for_port {
    my($port) = @_;
    my $start = time;
    while (1) {
        my $sock = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        return 1 if $sock;
        select undef, undef, undef, 0.25;
        die "Timeout waiting for port $port to startup" if time > $start + 5;
    }
}

1;
