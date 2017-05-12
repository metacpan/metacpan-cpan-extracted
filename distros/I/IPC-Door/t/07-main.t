#########################
# Test script for IPC::Door
# $Id: 07-main.t 37 2005-06-07 05:50:05Z asari $

use Test::More tests => 10;
use Fcntl;
use strict;
use constant INT_MAX => 2**16 - 1;
use IPC::Door qw(:attr);
BEGIN { use_ok('IPC::Door::Client') }
BEGIN { use_ok('IPC::Door::Server') }

#########################

sub srv ($);

sub srv ($) {
    return shift;
}

# Can I create a door?
my $dpath = 'DOOR';
if ( -e $dpath && !( -d $dpath ) ) {
    unlink($dpath) || die "Cannot delete $dpath: $!\n";
}
elsif ( -d $dpath ) {
    die "$dpath is a directory.  Cannot continue.\n";
}

my $dserver = new IPC::Door::Server( $dpath, \&srv, DOOR_UNREF );
ok( defined($dserver),          'door_create()' );
ok( $dserver->is_door,          'is_door, OO-version' );
ok( IPC::Door::is_door($dpath), 'is_door, subroutine version' );

my $dclient = new IPC::Door::Client($dpath);

# Test door_info()
my ( $dserver_pid, $dpath_attr, $dpath_uniq ) = $dclient->info();
is( $dserver_pid, $$, 'info (server pid) - self, OO-version' );
is( $dpath_attr & DOOR_UNREF, DOOR_UNREF, 'info (attr) - self, OO-version' );

( $dserver_pid, $dpath_attr, $dpath_uniq ) = IPC::Door::info($dpath);
is( $dserver_pid, $$, 'info (server pid) - self, subroutine version' );
is( $dpath_attr & DOOR_UNREF,
    DOOR_UNREF, 'info (attr) - self, subroutine version' );

TODO: {
    local $TODO = 'not working';
    $dserver->revoke();
    is( ( IPC::Door::info($dpath) )[1] & DOOR_REVOKED,
        DOOR_REVOKED, 'door_revoke()' );
}
