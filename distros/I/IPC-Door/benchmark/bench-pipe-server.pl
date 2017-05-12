#!/usr/bin/perl -w
# $Id: bench-pipe-server.pl 35 2005-06-06 04:48:39Z asari $

use strict;
use blib;
use File::Basename;
use Fcntl;

$SIG{INT}  = \&term;
$SIG{TERM} = \&term;

my ( $base, $path, $suffix ) = fileparse( $0, qr(\.[t|pl]) );

my $read_pipe  = $path . 'SERVER_PIPE';
my $write_pipe = $path . 'CLIENT_PIPE';

unless ( -p $write_pipe ) {
    if ( -e _ ) {
        die "$0: Won't overwrite $write_pipe\n";
    }
    else {
        require POSIX;
        POSIX::mkfifo( $write_pipe, 0666 )
          or die "Can't create $write_pipe: $!\n";
    }
}

unless ( -p $read_pipe ) {
    if ( -e _ ) {
        die "$0: Won't overwrite $read_pipe\n";
    }
    else {
        require POSIX;
        POSIX::mkfifo( $read_pipe, 0666 )
          or die "Can't create $read_pipe: $!\n";
    }
}

while (1) {
    die "Pipe $read_pipe disappeared\n" unless -p $read_pipe;

    sysopen( SERVER_PIPE, $read_pipe, O_RDONLY )
      or die "Can't write to $read_pipe: $!";
    sysopen( CLIENT_PIPE, $write_pipe, O_WRONLY )
      or die "Can't read to $write_pipe: $!";

    my $arg = <SERVER_PIPE>;
    print CLIENT_PIPE $arg**2;

    close SERVER_PIPE;
    close CLIENT_PIPE;

    select undef, undef, undef, 0.2;
}

sub term {
    my $sig = shift;
    die "$0: Caught signal $sig.\n";
}
