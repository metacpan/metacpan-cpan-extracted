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

use 5.004;
use strict;
use Test;
plan tests => 13;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use LWP::Protocol::rsync;

# uncomment this to run the ### lines
# use Smart::Comments;

#------------------------------------------------------------------------------

my $want_version = 1;
ok ($LWP::Protocol::rsync::VERSION,
    $want_version,
    'VERSION variable');
ok (LWP::Protocol::rsync->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { LWP::Protocol::rsync->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { LWP::Protocol::rsync->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# _parse_listing()

foreach my $elem (["-rw-r--r--          1,260 2004/10/29 04:50:12 foo.txt\n",
                   "-rw-r--r--",
                   1260,
                   1099025412 ],

                  ["-rw-r--r--      1.234.567 1970/01/02 00:00:00 foo.txt\n",
                   "-rw-r--r--",
                   1234567,
                   86400 ],


                  ["lrwxrwxrwx              3 2014/03/20 17:21:21 bar -> foo\n",
                   "lrwxrwxrwx",
                   3,
                   1395336081 ],

                 ) {
  my ($listing, $want_perms, $want_length, $want_mtime) = @$elem;
  my ($got_perms, $got_length, $got_mtime) = LWP::Protocol::rsync::_parse_listing($listing);
  ok ($got_perms, $want_perms);
  ok ($got_length, $want_length, "listing: $listing");
  ok ($got_mtime, $want_mtime, "listing: $listing");
  ### $got_mtime
}

#------------------------------------------------------------------------------
exit 0;
