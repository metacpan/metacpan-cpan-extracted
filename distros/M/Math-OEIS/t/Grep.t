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
use Test::More tests => 8;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::OEIS::Grep;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 11;
  is ($Math::OEIS::Grep::VERSION, $want_version,
      'VERSION variable');
  is (Math::OEIS::Grep->VERSION,  $want_version,
      'VERSION class method');

  is (eval { Math::OEIS::Grep->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  is (! eval { Math::OEIS::Grep->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
{
  my $filename = 'tempfile.tmp';
  open my $fh, '+>', $filename or die $!;
  my $extra = '';
  print $fh ('x' x 65536) or die $!;
  seek $fh, 0, 0 or die $!;
  { my $block = Math::OEIS::Grep::_read_block_lines($fh,$extra);
    is (length($block), 65536); }
  { my $block = Math::OEIS::Grep::_read_block_lines($fh,$extra);
    ok (! defined $block);
  }

  print $fh 'x' or die $!;
  seek $fh, 0, 0 or die $!;
  { my $block = Math::OEIS::Grep::_read_block_lines($fh,$extra);
    is (length($block), 65537); }
  { my $block = Math::OEIS::Grep::_read_block_lines($fh,$extra);
    ok (! defined $block);
  }

  close $fh;
  unlink $filename;
}

#------------------------------------------------------------------------------
exit 0;
