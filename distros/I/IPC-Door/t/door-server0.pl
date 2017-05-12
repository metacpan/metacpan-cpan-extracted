#!/usr/bin/perl -w
# $Id: door-server0.pl 37 2005-06-07 05:50:05Z asari $

use strict;
use Fcntl;
use Data::Dumper;
use blib;

use File::Basename;
my ( $base, $path, $suffix ) = fileparse( $0, qr(\.pl$) );

$SIG{INT}  = \&term;
$SIG{TERM} = \&term;
$SIG{USR1} = \&revoke;

use IPC::Door::Server;
my $door = $path . 'DOOR0';

check_door($door);

our $ok_to_die = 0;

my $server = new IPC::Door::Server( $door, \&serv )
  || die "Cannot create $door: $!\n";

while ( !($ok_to_die) ) {
    die "$door disappeared\n" unless IPC::Door::is_door($door);
    sysopen( DOOR, $door, O_WRONLY ) || die "Can't write to $door: $!\n";
    close DOOR;
    select undef, undef, undef, 0.2;
}

sub term {
    my $sig = shift;
    $ok_to_die = 1;
}

sub serv {
    my $arg = shift;
    my $ans = $arg ** 2;

    return $ans;
}

sub check_door {
    my $door = shift;
    if ( IPC::Door::is_door($door) ) {
        die "$door is an existing door.  Terminating.\n";
    }
    elsif ( stat($door) ) {
        print
          "$door exists, but it is not a door.  Shall I unlink it?  [y/n]: ";
        my $reply = <STDIN>;
        chomp $reply;
        if ( $reply =~ m/^y/i ) {
            unlink $door || die "Can't remove $door: $!\n";
        }
        else {
            exit "OK, I leave $door alone.\n";
        }
    }
}

sub revoke {
   $server->revoke;
}
