#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.


# Usage: perl grep-not-in-oeis.pl [-v] filename...
#
# Do some Math::OEIS::Grep searches for numbers in the given files.
# The numbers should appear as for instance
#
#     # not in OEIS: 17238, 12783, 4839, 589
#
# The idea is that a document or program can note values you didn't find in
# the OEIS (and haven't decided to add yet, or ever maybe) but which with a
# machine-readable form so grep in the future to see if they or something
# close has been added.
#
# Sequences which match but you know are false (become different later, only
# a middle match, etc) can be excluded by further "not" lines like
#
#     # not in OEIS: 17238, 12783, 4839, 589
#     # not A123456 as its formula is different after 512 terms
#     # not A000006 which begins differently
#
# The results are rough, and the document style demanded may change wildly,
# but this is an example of using Math::OEIS::Grep in a mechanical way.
#

use 5.010;
use strict;
use warnings;
use Encode ();
use Encode::Locale;
use File::Basename;
use File::Slurp;
use List::Util 'min';
use Math::OEIS::Grep;
use PerlIO::encoding;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 13;
$|=1;

# output coding for the benefit of Math::OEIS::Grep printing sequence names
# which have non-ASCII (usually people's names)
$PerlIO::encoding::fallback = Encode::PERLQQ();
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");

# $pos is a position in string $str, starting $pos=0 for start of the string.
# Return the line number of $pos in $str, starting from 1 for first line.
sub pos_linenum {
  my ($str, $pos) = @_;
  $pos //= pos($_[0]);
  $str = substr($str, 0, $pos);
  return 1 + scalar($str =~ tr/\n//);
}

my $verbose = 0;
if (@ARGV && $ARGV[0] eq '-v') {
  $verbose = 1;
  shift @ARGV;
}
my @filenames = @ARGV;

# hashrefs { str=>, filename=>, linenum=> }
my @seen;

my $count = 0;
foreach my $filename (@filenames) {
  if ($verbose) {
    print "$filename\n";
  }
  my $str = File::Slurp::slurp($filename);
  while ($str =~ /^(.*)no[t] in OEIS:(.*)\n((\1not A[0-9]+.*?\n)*)/mg) {
    $count++;
    my $values = $2;
    my $extras = $3;
    my $linenum = pos_linenum($str, $-[0]);
    ### $values
    ### $extras

    next if $values eq '...';  # usage shown in this script

    if ($verbose) {
      print "$filename $values\n";
    }
    $values =~ s{(.*)(#|\\\\|/\*).*}{$1}; # trailing comment
    $values =~ s/^\s+//;                  # leading whitespace
    $values =~ s/(\s*,)?\s*$//;           # trailing whitespace or single comma

    if ($values eq '') {
      print "$filename:$linenum: no values to grep on line\n$&\n";
      next;
    }

    my @values;
    if ($values =~ /\./) {
      ### decimal: $values
      $values =~ s/^0+\.//;                 # grep without initial 0.
      $values =~ s/^-//;                    # grep without -
      @values = split /\.|/, $values;       # 1.234 -> 1 2 3 4
    } else {
      ### integers ...
      @values = split /\s*,\s*/, $values;   # 1,2,3,4
    }
    ### @values
    foreach my $value (@values) {
      unless ($value =~ /^(-?[1-9][0-9]*|0)$/) {
        print "$filename:$linenum: bad value \"$value\" in \"$values\"\n";
        exit 1;
      }
    }

    {
      # Notice duplicate searches, which can be due to too much cut and
      # paste, or sometimes an unnoticed relationship between formulas etc.
      # Those on immediately following lines are ok, being some subset
      # search.
      my $str = join(',',@values);
      foreach my $seen (reverse @seen) {  # reverse for most recent first
        my $seen_str = $seen->{'str'};
        my $len = min(length($str),length($seen_str));
        if (index($str,$seen_str)>=0 || index($seen_str,$str)>=0) {
          last if ($filename eq $seen->{'filename'}   # close previous
                   && abs($linenum - $seen->{'linenum'}) <= 2);
          print "$filename:$linenum: duplicate",
            ($filename eq $seen->{'filename'} ? '' : ' in different file'),
            "\n";
          print "$seen->{filename}:$seen->{linenum}: ... previous is here\n";
          last;
        }
      }
      push @seen, {str      => $str,
                   filename => $filename,
                   linenum  => $linenum };
    }

    my @exclude_list;
    while ($extras =~ /not (A[0-9]+)/g) {
      push @exclude_list, $1;
    }

    ### @exclude_list
    Math::OEIS::Grep->search (array => \@values,
                              name => "$filename:$linenum: $values",
                              verbose => $verbose,
                              exclude_list => \@exclude_list);
  }
}

print "total $count \"not in OEIS\" searches\n";
exit 0;
