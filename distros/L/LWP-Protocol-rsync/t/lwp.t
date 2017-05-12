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


# Running via LWP.

use 5.004;
use strict;
use Test;

my $test_count = (tests => 1)[1];
plan tests => $test_count;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# actually LWP::UserAgent is included with LWP::Protocol
if (! eval { require LWP::UserAgent; 1 }) {
  my $err = $@;
  foreach (1 .. $test_count) {
    skip ("due to no LWP::UserAgent -- $err", 1, 1);
  }
  exit 0;
}

#------------------------------------------------------------------------------

{
  my $ua = LWP::UserAgent->new;
  my $resp = $ua->head('rsync://localhost:873/nosuchmodule/no/such/dir/nosuchfile.txt');
  ok (defined $resp, 1, 'HEAD');
  MyTestHelpers::diag("response code: ", $resp->code);
  MyTestHelpers::diag($resp->as_string);
}


#------------------------------------------------------------------------------
exit 0;
