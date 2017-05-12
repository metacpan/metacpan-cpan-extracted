#!/usr/bin/perl -w

# Copyright 2010, 2011, 2014 Kevin Ryde

# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator.  If not, see <http://www.gnu.org/licenses/>.


# This is a poor man's version of the "locate" program, as an example of
# using iterators.  The head() and igrep() of Iterator::Simple are handy ways
# to implement the --limit and --existing options.
#

use 5.006;
use strict;
use warnings;
use Getopt::Long;
use Iterator::Simple 'igrep';
use Iterator::Simple::Locate;

our $VERSION = 23;

use FindBin;
my $progname = $FindBin::Script;

my @globs;
my $show_usage = 1;
my $output_terminator = "\n";
my $database_file;
my $option_count = 0;
my $option_existing = 0;
my $option_non_existing = 0;
my $option_limit;
my $use_mmap;

Getopt::Long::Configure ('bundling', 'no_ignore_case');
GetOptions('0|null'         => sub { $output_terminator = "\0" },
           'c|count'        => \$option_count,
           'd|database=s'   => \$database_file,
           'e|existing'     => \$option_existing,
           'E|non-existing' => \$option_non_existing,
           'l|limit=i'      => \$option_limit,
           'm|mmap'         => sub { $use_mmap = 1 },
           's|stdio'        => sub { $use_mmap = 0 },
           '<>'             => sub {
             # stringize against Getopt::Long incompatible change to option
             # callbacks
             push @globs, "$_[0]";
           },
           'version'        => sub {
             print "$progname version $VERSION\n";
             $show_usage = 0;
           },
           'help|?' => sub {
             print <<"HERE";
$progname [--options] pattern...
  -0, --null          print \0 after each filename
  -c, --count         print just a count of matches
  -d, --database FILENAME
                      the database file to read
  -e, --existing      print only files which still exist
  -E, --non-existing  print only files which no longer exist
  -l, --limit N       print only first N matches
  -m, --mmap          must use mmap (default is "if_sensible")
  -s, --stdio         use plain file reading, not mmap
  --version           print program version
  --help              print this help
HERE
             $show_usage = 0;
           }) or exit 1;

if (! @globs) {
  # no glob patterns given
  if ($show_usage) {
    print STDERR "usage: $progname [--options] pattern...\n";
    exit 1;
  } else {
    exit 0;
  }
}

my $it = Iterator::Simple::Locate->new (database_file => $database_file,
                                        globs => \@globs,
                                        use_mmap => $use_mmap);
if ($option_existing) {
  $it = igrep {-e} $it;
}
if ($option_non_existing) {
  $it = igrep {!-e} $it;
}
if (defined $option_limit) {
  $it = $it->head($option_limit);
}

my $count = 0;
while (defined (my $filename = $it->next)) {
  $count++;
  unless ($option_count) {
    print "$filename$output_terminator";
  }
}

if ($option_count) {
  print "$count\n";
}

exit 0;
