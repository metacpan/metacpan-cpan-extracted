#!/usr/bin/perl -w
# $Id: benchmark.pl 35 2005-06-06 04:48:39Z asari $

use strict;
use blib;
use Benchmark qw[:all];

use blib;
use File::Basename;
use IPC::Door::Client;
use Fcntl;
use Errno qw( EAGAIN );

my ( $base, $path, $suffix ) = fileparse( $0, qr(\.[t|pl]) );
my $pipe_server = $path . "bench-pipe-server.pl";
my $pipe_server_pid;
my $door_server = $path . "bench-door-server.pl";
my $door_server_pid;
my $door    = $path . 'DOOR';
my $dclient = new IPC::Door::Client($door);

use constant int_max   => 2**16 - 1;
use constant precision => 0.005;

my $iteration = shift || 500;

my $read_pipe  = $path . "CLIENT_PIPE";
my $write_pipe = $path . "SERVER_PIPE";

my %errors = ( 'DOOR' => 0, 'PIPE' => 0 );
my %count  = ( 'DOOR' => 0, 'PIPE' => 0 );

$SIG{INT}  = \&cleanup;
$SIG{TERM} = \&cleanup;

&spawn_pipe_server();
&spawn_door_server();
print "Ready for benchmarks? ";
my $ans = <STDIN>;
if ( $ans =~ m/^[nN]/ ) {
    &cleanup;
    die "Benchmarking aborted.\n";
}

timethese(
    $iteration,
    {
        'DOOR' => \&call_door_server,
        'PIPE' => \&call_pipe_server,
    }
);

print "DOOR: executed $count{'DOOR'}; $errors{'DOOR'} errors\n";
print "PIPE: executed $count{'PIPE'}; $errors{'PIPE'} errors\n";

select undef, undef, undef, 2;
&cleanup;

sub spawn_pipe_server () {
  FORK_PIPE_SERVER: {
        if ( $pipe_server_pid = fork ) {
            ;
        }
        elsif ( defined $pipe_server_pid ) {
            exec $pipe_server;
        }
        elsif ( $! == EAGAIN ) {
            sleep 5;
            redo FORK_PIPE_SERVER;
        }
        else {
            die "Cannot fork the pipe server: $!\n";
        }
    }

}

sub spawn_door_server () {
  FORK_DOOR_SERVER: {
        if ( $door_server_pid = fork ) {
            ;
        }
        elsif ( defined $door_server_pid ) {
            exec $door_server;
        }
        elsif ( $! == EAGAIN ) {
            sleep 5;
            redo FORK_DOOR_SERVER;
        }
        else {
            die "Cannot fork the door server: $!\n";
        }
    }

}

sub call_door_server {
    my $num    = rand() * int_max;
    my $answer = $dclient->call($num) || 0;

    if ( abs( $answer - $num**2 ) > precision ) { $errors{'DOOR'}++ }
    $count{'DOOR'}++;
}

sub call_pipe_server {
    my $num = rand() * int_max;
    sysopen( SERVER_PIPE, $write_pipe, O_WRONLY )
      or die "Can't write to $write_pipe: $!";
    sysopen( CLIENT_PIPE, $read_pipe, O_RDONLY )
      or die "Can't read to $read_pipe: $!";

    print SERVER_PIPE $num;
    close SERVER_PIPE;

    my $answer = <CLIENT_PIPE>;
    close CLIENT_PIPE;

    if ( abs( $answer - $num**2 ) > precision ) { $errors{'PIPE'}++ }
    $count{'PIPE'}++;

    #	print "PIPE: Sent $num, got $answer\n";
}

sub cleanup {

    # terminate server processes
    kill 'INT', $door_server_pid;
    kill 'INT', $pipe_server_pid;

    unlink $door       || warn "Can't remove $door: $!\n";
    unlink $read_pipe  || warn "Can't remove $read_pipe: $!\n";
    unlink $write_pipe || warn "Can't remove $read_pipe: $!\n";
}
