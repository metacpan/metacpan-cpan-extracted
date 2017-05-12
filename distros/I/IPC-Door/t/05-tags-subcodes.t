#########################
# Test script for IPC::Door
# $Id: 05-tags-subcodes.t 15 2005-05-27 04:20:14Z asari $

# make sure the tags work

use Test::More tests => 11;
use Fcntl;
use strict;
use POSIX qw( uname );
my $release = (POSIX::uname())[2];
my ($major, $minor) = split /\./, $release;
BEGIN { use_ok('IPC::Door', qw(:subcodes)) }

# don't skip these
is(DOOR_CREATE, 0, 'DOOR_CREATE');
is(DOOR_REVOKE, 1, 'DOOR_REVOKE');
is(DOOR_INFO,   2, 'DOOR_INFO');
is(DOOR_CALL,   3, 'DOOR_CALL');
is(DOOR_RETURN, 4, 'DOOR_RETURN');

# DOOR_CRED is removed in Solaris 10
SKIP: {
    skip "DOOR_CRED", 1 if $minor >= 10;
    is(DOOR_CRED,   5, 'DOOR_CRED');
}

is(DOOR_BIND,   6, 'DOOR_BIND');
is(DOOR_UNBIND, 7, 'DOOR_UNBIND');

# DOOR_UNREFSYS is new in Solaris 9
SKIP: {
    skip "DOOR_UNREFSYS", 1 if $minor < 9;
    is(DOOR_UNREFSYS, 8, 'DOOR_UNREFSYS');
}

# DOOR_UCRED is new in Solaris 10
SKIP: {
    skip "DOOR_UCRED", 1 if $minor < 10;
    is(DOOR_UCRED, 9, 'DOOR_UCRED');
}

# done
