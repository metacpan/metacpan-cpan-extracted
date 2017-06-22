#!/usr/bin/perl -w

# Copyright 2014, 2015, 2016 Kevin Ryde

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
use Test::More tests => 12;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::OEIS::Names;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 10;
  is ($Math::OEIS::Names::VERSION, $want_version,
      'VERSION variable');
  is (Math::OEIS::Names->VERSION,  $want_version,
      'VERSION class method');

  is (eval { Math::OEIS::Names->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  is (! eval { Math::OEIS::Names->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# line_split()

{
  my @ret = Math::OEIS::Names->line_split('bogosity');
  is (scalar(@ret), 0);
}
{
  my @ret = Math::OEIS::Names->line_split('A000001 some text');
  is (scalar(@ret), 2);
  is ($ret[0], 'A000001');
  is ($ret[1], 'some text');
}
{
  my @ret = Math::OEIS::Names->line_split("A000001  \tsome text");
  is (scalar(@ret), 2);
  is ($ret[0], 'A000001');
  is ($ret[1], 'some text');
}

#------------------------------------------------------------------------------
# sample file reading

{
  my $names = Math::OEIS::Names->new (filename => 't/test-names');
  my $name = $names->anum_to_name('A000001');
  is ($name, 'Name number one');
}

#------------------------------------------------------------------------------
exit 0;
