#!/usr/bin/perl -w

# Copyright 2010, 2011, 2013, 2014 Kevin Ryde

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

use strict;
use warnings;
use Test::More tests => 6;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Filter::gunzip;

#-----------------------------------------------------------------------------
# VERSION

{
  my $want_version = 6;
  is ($Filter::gunzip::VERSION, $want_version, 'VERSION variable');
  is (Filter::gunzip->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Filter::gunzip->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Filter::gunzip->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
# _rsfp

# {
#   my $rsfp = Filter::gunzip::_rsfp();
#   diag "_rsfp is ", $rsfp;
#   if ($rsfp) {
#     my $rsfp_filters = Filter::gunzip::_rsfp_filters();
#     diag "_rsfp_filters is ", $rsfp_filters;
#   }
# }


#-----------------------------------------------------------------------------
# test1

{
  require FindBin;
  my $used_more_than_once = $FindBin::Bin;
  my $filename = File::Spec->catfile ($FindBin::Bin, 'test1.dat');

  use vars qw($test1 $test1_more);
  $test1 = 0;
  $test1_more = 0;
  diag "load $filename";
  my $result = eval { no warnings;
                      require $filename };
  my $err = $@;
  is ($result, "some thing");
  is ($err, '');
}

exit 0;
