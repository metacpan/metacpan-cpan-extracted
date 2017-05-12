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
use Devel::TimeThis;
use File::Locate::Iterator;

my $database = '/var/cache/locate/locatedb';

# Run on shortened locatedb.
{
  $ENV{'PATH'} =~ /(.*)/ and $ENV{'PATH'} = $1; # untaint PATH
  my $full_database = $database;
  $database = '/tmp/x.locatedb';
  system("locate --database=$full_database '*' | head -100000 | /usr/lib/locate/frcode >$database && ls -l $database") == 0
    or die;
}
my $str = do { my $fh; open $fh, '<', $database or die; local $/; <$fh> };

{
  require File::Locate;
  my $t = Devel::TimeThis->new('Callback all');
  File::Locate::locate ("*", $database, sub { });
}
{
  require File::Locate;
  my $t = Devel::TimeThis->new('Callback no match');
  File::Locate::locate ('fdsjkfjsdk', $database, sub {});
}
print "done callback\n";

foreach my $method (
                    'fh',
                    'mmap',
                   ) {
  my $use_mmap = ($method eq 'mmap');
  {
    my $t = Devel::TimeThis->new("Iterator $method, all");
    my $it = File::Locate::Iterator->new (database_file => $database,
                                          use_mmap => $use_mmap);
    while (defined ($it->next)) { }
  }
  {
    my $t = Devel::TimeThis->new("Iterator $method, no match");
    my $it = File::Locate::Iterator->new (database_file => $database,
                                          regexp => qr/^$/,
                                          use_mmap => $use_mmap);
    while (defined ($it->next)) { }
  }
  print "done $method\n";
}

{
  my $t = Devel::TimeThis->new("Iterator str_ref, all");
  my $it = File::Locate::Iterator->new (database_str_ref => \$str);
  while (defined ($it->next)) { }
}
{
  my $t = Devel::TimeThis->new("Iterator str_ref, no match");
  my $it = File::Locate::Iterator->new (database_str_ref => \$str,
                                        regexp => qr/^$/);
  while (defined ($it->next)) { }
}


exit 0;
