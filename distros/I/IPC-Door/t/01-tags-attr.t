#########################
# Test script for IPC::Door
# $Id: 01-tags-attr.t 15 2005-05-27 04:20:14Z asari $

# make sure the tags work

use Test::More tests => 13;
use Fcntl;
use strict;
use POSIX;
BEGIN { use_ok('IPC::Door', qw(:attr)) }

my $release = (POSIX::uname())[2];
my ($major, $minor) = split /\./, $release;

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

# done
