#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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
use Test;
plan tests => 5;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

require Math::NumSeq::File;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::File::VERSION, $want_version, 'VERSION variable');
  ok (Math::NumSeq::File->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::File->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::File->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# next()

{
  require File::Spec;
  my $filename = File::Spec->catfile('t','File-1.txt');
  my @want = ([1,123], [2,456], [4,789]);
  my $seq = Math::NumSeq::File->new
    (filename => $filename);
  my @got;
  while (my ($i, $value) = $seq->next) {
    push @got, [$i,$value];
  }
  ok (join(',', map {'['.join(',',@$_).'],'} @got),
      join(',', map {'['.join(',',@$_).'],'} @want),
      "next() contents $filename");
}


exit 0;


