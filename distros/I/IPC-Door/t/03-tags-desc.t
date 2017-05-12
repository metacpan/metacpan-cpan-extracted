#########################
# Test script for IPC::Door
# $Id: 03-tags-desc.t 27 2005-05-31 13:47:29Z asari $

# make sure the tags work

use Test::More tests => 2;
use Fcntl;
use strict;
use IPC::Door qw(:desc);

is(DOOR_INVAL, -1, 'DOOR_INVAL');
is(DOOR_QUERY, -2, 'DOOR_QUERY');

# done
