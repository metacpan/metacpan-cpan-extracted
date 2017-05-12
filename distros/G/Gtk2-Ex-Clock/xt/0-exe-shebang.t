#!/usr/bin/perl -w

# 0-exe-shebang.t -- check EXE_FILES use #!perl for interpreter

# Copyright 2010 Kevin Ryde

# 0-exe-shebang.t is shared by several distributions.
#
# 0-exe-shebang.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-exe-shebang.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

require 5;
use strict;
use Test::More;

Test::ExeFilesShebang->Test_More(verbose => 1);
exit 0;

package Test::ExeFilesShebang;
use strict;

sub Test_More {
  my ($class, %options) = @_;
  require Test::More;
  Test::More::plan (tests => 1);
  Test::More::ok ($class->check (diag => \&Test::More::diag,
                                 %options));
  1;
}

sub check {
  my ($class, %options) = @_;
  my $diag = $options{'diag'};
  if (! -e 'Makefile.PL') {
    &$diag ('skip, no Makefile.PL so not ExtUtils::MakeMaker');
    return 1;
  }

  if (! open FH, '<Makefile') {
    &$diag ('Oops, cannot open Makefile');
    return 0;
  }
  my $makefile = do { local $/ = undef; <FH> }; # slurp
  if (! close FH) {
    &$diag ("Oops, error closing Makefile");
    return 0;
  }

  # print $makefile;

  # if there's no EXE_FILES option used in the Makefile.PL then there's no
  # EXE_FILES variable setting line in the Makefile
  #
  if (! ($makefile =~ /^EXE_FILES = (.*)/m)) {
    &$diag ('No EXE_FILES in Makefile');
    return 1;
  }
  my @exe_files = split / /, $1;
  if ($options{'verbose'}) {
    &$diag ("EXE_FILES is ".join(' ',@exe_files));
  }

  my $good = 1;
  foreach (@exe_files) {
    my $filename = $_;
    unless (open FH, "<$filename") {
      &$diag ("Oops, cannot open $filename");
      $good = 0;
    }
    my $line = <FH>;
    if (! close FH) {
      &$diag ("Oops, error closing $filename");
      $good = 0;
    }

    if ($options{'verbose'}) {
      &$diag ("$filename line: $line");
    }
    if (! defined $line) {
      &$diag ("$filename: no shebang line");
    } elsif ($line =~ /#![ \t]*[^ \t]+perl/) {
      &$diag ("$filename: Shebang best as #!perl to let MakeMaker put real location\n  $line");
      $good = 0;
    }
  }
  return $good;
}
