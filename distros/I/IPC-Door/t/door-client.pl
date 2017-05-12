#!/usr/bin/perl -w
# $Id: door-client.pl 35 2005-06-06 04:48:39Z asari $
use strict;

use IPC::Door::Client;

use File::Basename;
use Fcntl;
use Errno qw( EAGAIN );

my ($base, $path, $suffix) = fileparse($0, qr(\.[t|pl]$));
my $dserver_pid;
my $dserver_script = $path . "door-server3pl";
my $door           = $path . 'DOOR3';

my $cont = 0;

$SIG{CONT} = sub { $cont++; return };

my $dclient = new IPC::Door::Client($door);

my $num = rand() * (2**16 - 1);
my $ans;

while ( $cont == 0 ) {
   select undef, undef, undef, 0.2;
}

if ($dclient->is_door) {
    $dserver_pid = ($dclient->info())[0];
    $ans = $dclient->call($num, O_RDWR);
}
else {
    die "$door is not a door: $!\n";
}

kill 'CONT', $dserver_pid;
