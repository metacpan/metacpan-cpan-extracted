#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use File::Locate::Iterator;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $filename;
BEGIN {
  $] >= 5.008
    or plan skip_all => 'need perl 5.008 for multi-arg pipe open';

  # untaint PATH
  $ENV{'PATH'} =~ /(.*)/ and $ENV{'PATH'} = $1;

  my $locate_help = `locate --help`;
  (defined $locate_help && $locate_help =~ /--null/)
    or plan skip_all => 'locate program not available or no --null option';

  $filename = File::Locate::Iterator->default_database_file;
  diag "locate database $filename";
  -e $filename
    or plan skip_all => "no locate database $filename";

  plan tests => 4;
}

my $count_limit = ($ENV{'FILE_LOCATE_ITERATOR_T_COUNT_LIMIT'} || 500);

foreach my $use_mmap (0, 'if_possible') {
 SKIP: {
    ok (open(my $fh, '-|', 'locate', '--database', $filename, '--null', ''),
        'open pipe from locate program');
    my $it = File::Locate::Iterator->new (database_file => $filename,
                                          use_mmap => $use_mmap);

    my $count = 0;
    my $good = 1;
    {
      local $/ = "\0";
      for (;;) {
        $count++;
        if ($count >= $count_limit) {
          last;
        }
        my $want = <$fh>;
        if (defined $want) { chomp $want; }
        my $got = $it->next;

        if (! defined $want && ! defined $got) {
          last;
        }
        if (! (defined $want
               && defined $got
               && $want eq $got)) {
          diag "locate program: ", (defined $want ? $want : '[undef]');
          diag "iterator:       ", (defined $got  ? $got  : '[undef]');
          $good = 0;
          last;
        }
      }
    }
    # no error check on this close, since "locate" will exit non-zero due to
    # broken output pipe closing it before its output is finished
    close $fh;

    ok ($good, "iterator vs locate program, use_mmap=$use_mmap");
  }
}

exit 0;
