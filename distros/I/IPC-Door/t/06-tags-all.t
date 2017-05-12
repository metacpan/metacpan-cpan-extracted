#########################
# Test script for IPC::Door
# $Id: 06-tags-all.t 15 2005-05-27 04:20:14Z asari $

# make sure the tags work

use Test::More tests => 30;
use Fcntl;
use strict;
use POSIX qw( uname );
my $release = (POSIX::uname())[2];
my ($major, $minor) = split /\./, $release;
BEGIN { use_ok('IPC::Door', qw(:all)) }

# These are basically the same tests from 01 through 05, rehashed
# for testing the tag ':all'.

# Don't skip these!
is(DOOR_ATTR_MASK,
    $minor >= 10?
        DOOR_UNREF | DOOR_PRIVATE | DOOR_UNREF_MULTI | DOOR_REFUSE_DESC | DOOR_LOCAL | DOOR_REVOKED | DOOR_IS_UNREF:
        DOOR_UNREF | DOOR_PRIVATE | DOOR_UNREF_MULTI | DOOR_LOCAL | DOOR_REVOKED | DOOR_IS_UNREF,
    'DOOR_ATTR_MASK'
);
is(DOOR_UNREF,        0x01,     'DOOR_UNREF');
is(DOOR_PRIVATE,      0x02,     'DOOR_PRIVATE');
is(DOOR_UNREF_MULTI,  0x10,     'DOOR_UNREF_MULTI');
is(DOOR_LOCAL,        0x04,     'DOOR_LOCAL');
is(DOOR_REVOKED,      0x08,     'DOOR_REVOKED');
is(DOOR_IS_UNREF,     0x20,     'DOOR_IS_UNREF');
is(DOOR_DELAY,        0x80000,  'DOOR_DELAY');
is(DOOR_UNREF_ACTIVE, 0x100000, 'DOOR_UNREF_ACTIVE');
SKIP: {
    skip "Solaris 9 and earlier", 3 if $minor < 10;
    is(DOOR_REFUSE_DESC, 0x40,  'DOOR_REFUSE_DESC');
    is(DOOR_CREATE_MASK, (DOOR_UNREF | DOOR_PRIVATE | DOOR_UNREF_MULTI | DOOR_REFUSE_DESC ), 'DOOR_CREATE_MASK');
    is(DOOR_KI_CREATE_MASK, (DOOR_UNREF | DOOR_UNREF_MULTI), 'DOOR_KI_CREATE_MASK');
}

is(DOOR_DESCRIPTOR, 0x10000, 'DOOR_DESCRIPTOR');

# this one is optional ( #ifdef _KERNEL )
SKIP: {
    eval { DOOR_HANDLE };
    skip 'DOOR_HANDLE', 1 if $@;
    is(DOOR_HANDLE, 0x20000, 'DOOR_HANDLE');
}
is(DOOR_RELEASE, 0x40000, 'DOOR_RELEASE');

is(DOOR_INVAL, -1, 'DOOR_INVAL');
is(DOOR_QUERY, -2, 'DOOR_QUERY');

# these are optional ( #if defined(_KERNEL) )
SKIP: {
    eval { DOOR_WAIT };
    skip 'DOOR_WAIT', 1 if $@;
    is(DOOR_WAIT, -1, 'DOOR_WAIT');
}
SKIP: {
    eval { DOOR_EXIT };
    skip 'DOOR_EXIT', 1 if $@;
    is(DOOR_EXIT, -2, 'DOOR_EXIT');
}

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
