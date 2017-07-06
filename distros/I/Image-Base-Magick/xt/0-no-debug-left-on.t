#!/usr/bin/perl -w

# 0-no-debug-left-on.t -- check no Smart::Comments left on

# Copyright 2011, 2012 Kevin Ryde

# 0-no-debug-left-on.t is shared by several distributions.
#
# 0-no-debug-left-on.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-no-debug-left-on.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


# cf Test::NoSmartComments which uses Module::ScanDeps.

require 5;
use strict;

Test::NoDebugLeftOn->Test_More(verbose => 0);
exit 0;


package Test::NoDebugLeftOn;
use strict;
use ExtUtils::Manifest;

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

  my $href = ExtUtils::Manifest::maniread();
  my @files = keys %$href;

  my $good = 1;

  my @perl_files = grep {m{
                            ^lib/
                          |^(lib|examples|x?t)/.*\.(p[lm]|t)$
                          |^Makefile.PL$
                          |^[^/]+$
                        }x
                      } @files;
  my $filename;
  foreach $filename (@perl_files) {
    if ($options{'verbose'}) {
      &$diag ("perl file ",$filename);
    }
    if (! open FH, "< $filename") {
      &$diag ("Oops, cannot open $filename: $!");
      $good = 0;
      next;
    }
    while (<FH>) {
      if (/^__END__/) {
        last;
      }
      # only a DEBUG=> non-zero number is bad, so an expression can copy a
      # debug from another package
      if (/(DEBUG\s*=>\s*[1-9][0-9]*)/
          || /^[ \t]*((use|no) (Smart|Devel)::Comments)/
          || /^[ \t]*(use lib\b.*devel.*)/
         ) {
        print STDERR "\n$filename:$.: leftover: $_\n";
        $good = 0;
      }
    }
    if (! close FH) {
      &$diag ("Oops, error closing $filename: $!");
      $good = 0;
      next;
    }
  }

  my @C_files = grep {m{
                         # toplevel or lib .c and .xs files
                         ^[^/]*\.([ch]|xs)$
                       |^(lib|examples|x?t)/.*\.([ch]|xs)$
                     }x
                   } @files;
  foreach $filename (@C_files) {
    if ($options{'verbose'}) {
      &$diag ("C/XS file ",$filename);
    }
    if (! open FH, "< $filename") {
      &$diag ("Oops, cannot open $filename: $!");
      $good = 0;
      next;
    }
    while (<FH>) {
      if (/^#\s*define\s+DEBUG\s+[1-9]/
         ) {
        print STDERR "\n$filename:$.: leftover: $_\n";
        $good = 0;
      }
    }
    if (! close FH) {
      &$diag ("Oops, error closing $filename: $!");
      $good = 0;
      next;
    }
  }

  &$diag ("checked ",scalar(@perl_files)," perl files, ",
          scalar(@C_files)," C/XS files\n");
  return $good;
}
