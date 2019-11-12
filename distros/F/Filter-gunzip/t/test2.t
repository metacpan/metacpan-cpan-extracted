#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2014, 2019 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Filter-gunzip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.


# Exercise Filter::gunzip::Filter by test2.dat containing
# "use Filter::gunzip::Filter" followed by raw gzipped bytes
# (of the code in test2.in).


use strict;
use warnings;
use Test;
plan tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

{
  require FindBin;
  require File::Spec;
  my $used_more_than_once = $FindBin::Bin;
  my $filename = File::Spec->catfile ($FindBin::Bin, 'test2.dat');
  MyTestHelpers::diag("filename ",$filename);

  use vars qw($test2 $test2_more);
  $test2 = 0;
  $test2_more = 0;
  my $result = eval {
    # warnings not fatal (should be none though)
    local $SIG{'__WARN__'} = sub {
      MyTestHelpers::diag("warning message: ",@_);
    };
    require $filename;
  };
  my $err = $@;
  MyTestHelpers::diag("result: ",(defined $result ? "'$result'" : '[undef]'));
  MyTestHelpers::diag("err:    ",(defined $err ? "'$err'" : '[undef]'));
  ok (defined $result && $result eq "test2 compressed end");
  ok (defined $err && $err eq '');
  ok ($test2, "test2 compressed end");
  ok ($test2_more, 0);
}

exit 0;
