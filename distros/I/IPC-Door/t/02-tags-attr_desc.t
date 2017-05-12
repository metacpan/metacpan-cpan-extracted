#########################
# Test script for IPC::Door
# $Id: 02-tags-attr_desc.t 27 2005-05-31 13:47:29Z asari $

# make sure the tags work

use Test::More tests => 3;
use Fcntl;
use strict;
use IPC::Door qw(:attr_desc);

is(DOOR_DESCRIPTOR, 0x10000, 'DOOR_DESCRIPTOR');

# this one is optional ( #ifdef _KERNEL )
SKIP: {
    eval { DOOR_HANDLE };
    skip 'DOOR_HANDLE', 1 if $@;
    is(DOOR_HANDLE, 0x20000, 'DOOR_HANDLE');
}

is(DOOR_RELEASE, 0x40000, 'DOOR_RELEASE');

# done
