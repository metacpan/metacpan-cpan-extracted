#!/usr/bin/perl -w
# $Id: bench-door-server.pl 35 2005-06-06 04:48:39Z asari $

use strict;
use blib;
use File::Basename;
use Cwd;
use Fcntl;
use blib;
use IPC::Door::Server;

$SIG{INT}  = \&term;
$SIG{TERM} = \&term;

my ( $base, $path, $suffix ) = fileparse( $0, qr(\.[t|pl]) );
my $door = $path . 'DOOR';

sub serv {
    my $arg = shift;

    return $arg**2;
}

my $server = new IPC::Door::Server( $door, \&serv )
  || die "Cannot create $door: $!\n";

while (1) {
    die "$door disappeared\n" unless $server->is_door;

    sysopen( DOOR, $door, O_WRONLY ) or die "Can't open $door: $!\n";

    close DOOR;

    select undef, undef, undef, 0.5;

}

sub term {
    my $sig = shift;
    print STDERR "$0: Caught signal $sig.\n" && die;
}
