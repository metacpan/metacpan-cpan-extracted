#########################
# Test script for IPC::Door
# $Id: 09-server.t 37 2005-06-07 05:50:05Z asari $
# Tests for server-side functionalities

use Test::More tests => 2;
use strict;
use Fcntl;

use IPC::Door::Server;

use File::Basename;
use Errno qw( EAGAIN );

# For testing door_cred() & door_ucred()
package IPC::Door;
our ( $CLIENT_EUID, $CLIENT_EGID, $CLIENT_RUID, $CLIENT_RGID, $CLIENT_PID );

package main;

my $ok        = 1;
my $iteration = 0;

$SIG{CONT} = sub { $ok = 0; return };

my ( $base, $path, $suffix ) = fileparse( $0, qr(\.t|pl]$) );
my $dpath = $path . "DOOR3";

my $dclient_script = $path . 'door-client.pl';
my $dclient_pid;

FORK_DOOR_CLIENT: {
    if ( $dclient_pid = fork ) {

        # fall through
        ;
    }
    elsif ( defined $dclient_pid ) {
        exec $dclient_script;
    }
    elsif ( $! == EAGAIN ) {
        sleep 5;
        redo FORK_DOOR_CLIENT;
    }
    else {
        die "Cannot fork the door client $dclient_script: $!\n";
    }
}

my $dserver = new IPC::Door::Server( $dpath, \&serv )
  || die "Cannot create $dpath: $!\n";

while ($ok) {
    select undef, undef, undef, 0.2;
    kill 'CONT', $dclient_pid if $iteration > 20;
    $iteration++;
}

sub serv {
    my $arg = shift;
    my $ans = $arg**2;

    # Since we have forked the client process, we assume that its
    # various ID's are identical to ours.
    #  skip "door_cred()/door_ucred() not working", 1;
    my $primary_egid = ( split /\s+/, $) )[0];
    my $primary_rgid = ( split /\s+/, $( )[0];

    # Solaris supports multiple group IDs
    is_deeply(
        [ $CLIENT_EUID, $CLIENT_EGID, $CLIENT_RUID, $CLIENT_RGID, $CLIENT_PID ],
        [ $>, $primary_egid, $<, $primary_rgid, $dclient_pid ],
        'door_cred()/door_ucred() - remote'
    );

  TODO: {
        local $TODO = 'not working';

        #  skip "door_info(DOOR_QUERY,'') not working", 1;
        my $target = ( $dserver->info() )[0];
        cmp_ok( $target, '==', $dclient_pid, "door_info(DOOR_QUERY, '')" );
    }

    return $ans;
}

