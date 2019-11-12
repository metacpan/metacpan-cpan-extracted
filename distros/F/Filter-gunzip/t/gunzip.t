#!/usr/bin/perl -w

# Copyright 2010, 2011, 2013, 2014, 2019 Kevin Ryde

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
use Test;
plan tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

BEGIN {
  require Filter::gunzip;
}

# #-----------------------------------------------------------------------------
# # Exercise _rsfp getting PL_rsfp and _rsfp_filters getting PL_rsfp_filters.
# 
# BEGIN {
#   # This runs in BEGIN since later there is no rsfp.
#   diag "diagnostics:";
# 
#   my $filters = Filter::gunzip::_rsfp_filters();
#   diag "PL_rsfp_filters aref = ",(defined $filters ? "$filters" : '[undef]');
#   if (defined $filters) {
#     diag "  length ",scalar(@$filters);
#   }
# 
#   # FIXME: These prints do something which stops all tests at this point.
#   # Is there something bad about looking at PL_rsfp here?
#   #
#   if (defined $filters) {
#     my $fh = Filter::gunzip::_rsfp();
#     diag "PL_rsfp = ",$fh;
#     if (defined $fh) {
#       my @layers = PerlIO::get_layers($fh);
#       diag "  layers: ",join(' ',@layers);
#       diag "  ftell:  ",tell($fh);
#     }
#   }
#   diag "end diagnostics";
# }
# CHECK {
#   diag "final BEGIN block";
# }
# CHECK {
#   diag "CHECK block runs";
# }

#-----------------------------------------------------------------------------
# VERSION

{
  my $want_version = 8;
  ok ($Filter::gunzip::VERSION, $want_version, 'VERSION variable');
  ok (Filter::gunzip->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Filter::gunzip->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Filter::gunzip->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

# {
#   require PerlIO::gzip;
#   diag "PerlIO::gzip version ",PerlIO::gzip->VERSION;
# }

# diag "end tests";
#-----------------------------------------------------------------------------
exit 0;
