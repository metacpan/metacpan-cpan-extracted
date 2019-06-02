#!/usr/bin/perl -w

# Copyright 2015, 2019 Kevin Ryde

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
use FindBin;
use File::Spec;
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
plan tests => 19;

require Math::OEIS::Names;
require Math::OEIS::Stripped;

my $test_names_filename = File::Spec->catfile($FindBin::Bin, 'test-names');
my $test_stripped_filename = File::Spec->catfile($FindBin::Bin, 'test-stripped');
diag "test names filename: ",$test_names_filename;
diag "test stripped filename: ",$test_stripped_filename;

#------------------------------------------------------------------------------
# Math::OEIS::Names -- line_split()

{
  # tainted $line remains tainted after splitting
  my $line = 'A000001 some text';
  Taint::Util::taint($line);
  my @ret = Math::OEIS::Names->line_split($line);
  is (scalar(@ret), 2);
  is ($ret[0], 'A000001');
  is ($ret[1], 'some text');
  ok (Taint::Util::tainted($ret[0]),
      'Math::OEIS::Names line_split() anum remains tainted');
  ok (Taint::Util::tainted($ret[1]),
      'Math::OEIS::Names line_split() name remains tainted');
}


#------------------------------------------------------------------------------
# Math::OEIS::Names -- anum_to_name()

{
  my $names = Math::OEIS::Names->new (filename => $test_names_filename);
  my $name = $names->anum_to_name('A000001');
  is ($name, 'Name number one');
  ok (Taint::Util::tainted($name),
      'Math::OEIS::Names anum_to_name() tainted from file');
}

#------------------------------------------------------------------------------
# Math::OEIS::Stripped -- anum_to_values_str() and anum_to_values()

{
  my $stripped = Math::OEIS::Stripped->new (filename => $test_stripped_filename);
  {
    my $values_str = $stripped->anum_to_values_str('A000001');
    is ($values_str, '1,2,3,4,5');
    ok (Taint::Util::tainted($values_str),
        'Math::OEIS::Stripped anum_to_values_str() tainted from file');
  }
  {
    my @values = $stripped->anum_to_values('A000002');
    is (join(':',@values), '6:7:8:9:10');
    foreach my $i (0 .. $#values) {
      ok (Taint::Util::tainted($values[$i]),
          'Math::OEIS::Stripped anum_to_values() all tainted from file');
    }
  }
  {
    my $values_str = $stripped->anum_to_values_str('A000004');
    ok (Taint::Util::tainted($values_str),
        'Math::OEIS::Stripped anum_to_values_str() bignum string tainted from file');
  }
}
{
  my $stripped = Math::OEIS::Stripped->new (filename => $test_stripped_filename,
                                            use_bigint => 0);
  {
    my @values = $stripped->anum_to_values('A000004');
    is (scalar(@values), 1);
    is (length($values[0]), 90);
    ok (Taint::Util::tainted($values[0]),
        'Math::OEIS::Stripped anum_to_values() bignum value tainted from file');
  }
}

#------------------------------------------------------------------------------
exit 0;
