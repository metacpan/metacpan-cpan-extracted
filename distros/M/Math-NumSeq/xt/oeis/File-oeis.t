#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


# Check that all downloaded files can be parsed.
#

use 5.004;
use strict;
use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::OEIS::File;

my $bad = 0;
my $skip;

my $dir = Math::NumSeq::OEIS::File->oeis_dir;
MyTestHelpers::diag ("directory ",$dir);
if (! -d $dir) {
  $skip = "due to no download directory $dir";
}

unless ($skip) {
  chdir $dir or die;
  my $count_files = 0;

  foreach my $filename (<A*.html>) {
    $filename =~ /(A\d+)/;
    my $anum = $1;
    my $is_internal = ($filename =~ /internal/);

    $count_files++;
    MyTestHelpers::diag($filename);

    # .html files get description
    if (! $is_internal) {
      my $seq = Math::NumSeq::OEIS::File->new(_dont_use_internal=>1,
                                              anum=>$anum);
      if (! $seq->{'description'}) {
        MyTestHelpers::diag ("$dir/$filename:1:0: no description");
        $bad++;
      }
    }

    foreach my $dont ([],
                      [_dont_use_afile=>1],

                      [_dont_use_afile=>1,
                       _dont_use_bfile=>1],

                      ($is_internal && -e "A$anum.html"
                       ? [_dont_use_afile=>1,
                          _dont_use_bfile=>1,
                          _dont_use_internal=>1]
                       : ())) {
      my $seq = Math::NumSeq::OEIS::File->new(anum=>$anum, @$dont);
      my ($i,$value) = $seq->next;
      if (! defined $value) {
        MyTestHelpers::diag ("$dir/$filename:1:0: no values under @$dont");
        $bad++;
      }

      my $description = $seq->description;
      if ($description =~ /OFFSET/) {
        MyTestHelpers::diag ("$dir/$filename:1:0: oops, OFFSET in description()");
        $bad++;
      }
    }
  }
  MyTestHelpers::diag ("total $count_files files");
}
skip ($skip,
      $bad, 0);

exit 0;
