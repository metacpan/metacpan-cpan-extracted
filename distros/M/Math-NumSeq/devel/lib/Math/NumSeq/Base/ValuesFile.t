#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test::More tests => 17;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::Base::MathImageFile;
use Math::NumSeq::Base::MathImageFileWriter;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  is ($Math::NumSeq::Base::MathImageFile::VERSION, $want_version,
      'VERSION variable');
  is (Math::NumSeq::Base::MathImageFile->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Base::MathImageFile->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Base::MathImageFile->VERSION($check_version); 1 },
      "VERSION class check $check_version");


  is ($Math::NumSeq::Base::MathImageFileWriter::VERSION, $want_version, 'VERSION variable');
  is (Math::NumSeq::Base::MathImageFileWriter->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::Base::MathImageFileWriter->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  ok (! eval { Math::NumSeq::Base::MathImageFileWriter->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
{
  my @values = (1, 2, 5, 19, 1234, 9999);
  my $hi = 10000;
  {
    diag "Values FileWriter create";
    my $vfw = Math::NumSeq::Base::MathImageFileWriter->new
      (hi => $hi,
       package => 'Values File-test');
    foreach my $n (@values) {
      $vfw->write_n ($n);
    }
    $vfw->done;
  }

  {
    diag "Values File past hi";
    my $vf = Math::NumSeq::Base::MathImageFile->new
      (hi => $hi+1,
       package => 'Values File-test');
    is ($vf, undef);
  }
  {
    diag "Values File read";
    my $vf = Math::NumSeq::Base::MathImageFile->new
      (hi => $hi,
       package => 'Values File-test');
    is ($vf->{'hi'}, $hi);

    my @got;
    foreach my $i (0 .. 30) {
      my ($got_i, $got_value) = $vf->next
        or last;
      is ($got_i, $i, "next() i at $i");
      push @got, $got_value;
    }
    diag "got @got";
    is_deeply (\@got, \@values, 'Values File next()');
  }
}

exit 0;


