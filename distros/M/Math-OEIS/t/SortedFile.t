#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Math-OEIS.
#
# Math-OEIS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-OEIS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-OEIS.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use Test::More tests => 6;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::OEIS::SortedFile;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 11;
  is ($Math::OEIS::SortedFile::VERSION, $want_version,
      'VERSION variable');
  is (Math::OEIS::SortedFile->VERSION,  $want_version,
      'VERSION class method');

  is (eval { Math::OEIS::SortedFile->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  is (! eval { Math::OEIS::SortedFile->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# names and stripped separate singleton instances

{
  require Math::OEIS::Names;
  require Math::OEIS::Stripped;
  my $names = Math::OEIS::Names->instance;
  my $stripped = Math::OEIS::Stripped->instance;
  ok (Math::OEIS::Names->instance->isa('Math::OEIS::Names'));
  ok (Math::OEIS::Stripped->instance->isa('Math::OEIS::Stripped'));
}

#------------------------------------------------------------------------------
exit 0;
