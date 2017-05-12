#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde

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
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

eval { require Taint::Util; 1 }
  or plan skip_all => "due to Taint::Util not available -- $@";

{
  my $str = '';
  Taint::Util::taint($str);
  Taint::Util::tainted($str)
      or plan skip_all => "due to not running under perl -T taint mode";
}
plan tests => 15;

require Math::OEIS::Names;
require Math::OEIS::Stripped;


#------------------------------------------------------------------------------
# line_split()

{
  my $str = 'A000001 some text';
  Taint::Util::taint($str);
  my @ret = Math::OEIS::Names->line_split($str);
  is (scalar(@ret), 2);
  is ($ret[0], 'A000001');
  is ($ret[1], 'some text');
  ok (Taint::Util::tainted($ret[0]));
  ok (Taint::Util::tainted($ret[1]));
}


#------------------------------------------------------------------------------
# Math::OEIS::Names -- anum_to_name()

{
  my $names = Math::OEIS::Names->new (filename => 't/test-names');
  my $name = $names->anum_to_name('A000001');
  is ($name, 'Name number one');
  ok (Taint::Util::tainted($name));
}

#------------------------------------------------------------------------------
# Math::OEIS::Stripped -- anum_to_name()

{
  my $stripped = Math::OEIS::Stripped->new (filename => 't/test-stripped');
  my $values_str = $stripped->anum_to_values_str('A000001');
  is ($values_str, '1,2,3,4,5');
  ok (Taint::Util::tainted($values_str));

  my @values = $stripped->anum_to_values('A000002');
  is (join(':',@values), '6:7:8:9:10');
  foreach my $i (0 .. 4) {
    ok (Taint::Util::tainted($values[$i]));
  }
}

#------------------------------------------------------------------------------
exit 0;
