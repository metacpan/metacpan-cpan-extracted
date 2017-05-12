#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

# This file is part of LWP-Protocol-rsync.
#
# LWP-Protocol-rsync is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# LWP-Protocol-rsync is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with LWP-Protocol-rsync.  If not, see <http://www.gnu.org/licenses/>.


require 5;
use strict;
use Test;
plan tests => 5;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use LWP::Protocol::rsync;


# These numbers are the usual Unix way, but probably not portable otherwise.
# So an author test only.
#
ok (LWP::Protocol::rsync::_wstat_str(0), "exit code 0");
ok (LWP::Protocol::rsync::_wstat_str(0x100), "exit code 1");
ok (LWP::Protocol::rsync::_wstat_str(1), "signal 1");
ok (LWP::Protocol::rsync::_wstat_str(9), "signal 9");
ok (LWP::Protocol::rsync::_wstat_str(0xFFFF), "exit status 0xFFFF");

exit 0;
