#########################
# Test script for IPC::Door
# $Id: 04-tags-errors.t 27 2005-05-31 13:47:29Z asari $

# make sure the tags work

use Test::More tests => 2;
use Fcntl;
use strict;
use IPC::Door qw(:errors);

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

# done
