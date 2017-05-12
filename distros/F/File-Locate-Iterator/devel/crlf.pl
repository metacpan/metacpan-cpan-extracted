#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
use Data::Dumper;


{
  # open.pm is lexical, PERLIO is global
  # use open IN => ':crlf';
  my $filename = '/tmp/crlf.db';
  open my $fh, '<', $filename or die;
  { local $,=' '; print PerlIO::get_layers($fh),"\n"; }
  my $it = File::Locate::Iterator->new (
                                        database_file => $filename,
                                        # database_fh => $fh
                                       );
  print exists $it->{'mmap'} ? "using mmap\n" : "using fh\n";
  while (defined (my $str = $it->next)) {
    print Data::Dumper->new([$str],['got'])->Useqq(1)->Dump;
  }
  exit 0;
}

{
  my $filename = File::Locate::Iterator->default_database_file;
  print "filename $filename ",(-s $filename),"\n";
  require Perl6::Slurp;
  my $str = Perl6::Slurp::slurp ('<:raw', $filename);
  if ($str =~ /\r\n/g) {
    print "crlf at ",pos($str),"\n";
  } else {
    print "no crlf\n";
  }
  exit 0;
}

{
  open my $fh, '|/usr/lib/locate/frcode -0 >/tmp/crlf.db' or die;
  print $fh "abc\r\ndef\0";
  print $fh "abc\r\n\0";
  print $fh "two\r\n\0";
  close $fh;
  exit 0;
}


