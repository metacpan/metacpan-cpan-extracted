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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

eval { require Taint::Util; 1 }
  or plan skip_all => "due to Taint::Util not available -- $@";

plan tests => 17;

use File::Locate::Iterator;

# uncomment this to run the ### lines
#use Devel::Comments;


#------------------------------------------------------------------------------
# taint from a "database_file"

{
  require FindBin;
  require File::Spec;
  my $samp_zeros    = File::Spec->catfile ($FindBin::Bin, 'samp.zeros');
  my $samp_locatedb = File::Spec->catfile ($FindBin::Bin, 'samp.locatedb');

  my $want_taint;
  {
    open my $fh, '<', $samp_locatedb or die "Oops, cannot open $samp_locatedb";
    my $bytes;
    read($fh, $bytes, 1) or die "Oops, cannot read $samp_locatedb";
    close $fh or die "Oops, error closing $samp_locatedb";
    $want_taint = Taint::Util::tainted($bytes);
  }

  foreach my $use_mmap ('if_possible', 0) {
    my $it = File::Locate::Iterator->new (database_file => $samp_locatedb,
                                          use_mmap => $use_mmap);
    my $entry = $it->next;
    is ($entry, 'shortening');
    my $got_taint = Taint::Util::tainted($entry);
    is ($got_taint, $want_taint, "tainted() with use_mmap=$use_mmap");
  }
}

#------------------------------------------------------------------------------
# taint from a tainted "database_str"

{
  my $locatedb_str = "\0LOCATE02\0\0/hello\0\006/world\0";
  Taint::Util::taint($locatedb_str);
  my $want_taint = Taint::Util::tainted($locatedb_str);

  my $it = File::Locate::Iterator->new (database_str => $locatedb_str);
  Taint::Util::untaint($locatedb_str);

  my $entry = $it->next;
  is ($entry, '/hello');
  my $got_taint = Taint::Util::tainted($entry);
  is ($got_taint, $want_taint, "database_str tainted");
}

{
  my $locatedb_str = "\0LOCATE02\0\0/hello\0\006/world\0";
  my $it = File::Locate::Iterator->new (database_str => $locatedb_str);
  my $entry = $it->next;
  is ($entry, '/hello');
  my $got_taint = Taint::Util::tainted($entry);
  ok (! $got_taint, "database_str untainted");
}


#------------------------------------------------------------------------------
# taint from "database_str_ref"

{
  my $dummy_str = '';
  Taint::Util::taint($dummy_str);
  my $want_taint = Taint::Util::tainted($dummy_str);

  my $locatedb_str = "\0LOCATE02\0\0/hello\0\006/world\0";
  my $it = File::Locate::Iterator->new (database_str_ref => \$locatedb_str);
  {
    my $entry = $it->next;
    is ($entry, '/hello');
    my $got_taint = Taint::Util::tainted($entry);
    ok (! $got_taint, "database_str_ref untainted");
  }
  Taint::Util::taint($locatedb_str);
  {
    my $entry = $it->next;
    is ($entry, '/hello/world');
    my $got_taint = Taint::Util::tainted($entry);
    is ($got_taint, $want_taint, "database_str_ref tainted");
  }
}

{
  my $dummy_str = '';
  Taint::Util::taint($dummy_str);
  my $want_taint = Taint::Util::tainted($dummy_str);

  my $locatedb_str = "\0LOCATE02\0\0/hello\0\006/world\0";
  Taint::Util::taint($locatedb_str);
  my $it = File::Locate::Iterator->new (database_str_ref => \$locatedb_str);
  {
    my $entry = $it->next;
    is ($entry, '/hello');
    my $got_taint = Taint::Util::tainted($entry);
    is ($got_taint, $want_taint, "database_str_ref tainted");
  }
  Taint::Util::untaint($locatedb_str);
  $it->rewind;
  {
    my $entry = $it->next;
    is ($entry, '/hello');
    my $got_taint = Taint::Util::tainted($entry);
    ok (! $got_taint, "database_str_ref untainted");
  }
}

#------------------------------------------------------------------------------
# check taint of an empty mmapped file doesn't affect future such mmaps

{
  require FindBin;
  require File::Spec;
  my $filename = File::Spec->catfile ($FindBin::Bin, 'samp.empty');

  my $first_taint;
  {
    my $mmap;
    eval {
      require File::Map;
      File::Map::map_file ($mmap, $filename);
      1;
    } or diag "No File::Map map_file() -- $@";
    my $first_taint = Taint::Util::tainted($mmap);
    diag "File::Map empty file taint is '$first_taint'";
    ### $first_taint
  }

  eval {
    File::Locate::Iterator->new (database_file => $filename,
                                 use_mmap => 1);
  };

  my $second_taint;
  {
    my $mmap;
    eval {
      require File::Map;
      File::Map::map_file ($mmap, $filename);
    };
    my $second_taint = Taint::Util::tainted($mmap);
    ### $second_taint
  }

  is ($first_taint, $second_taint, "tainted() of File::Map empty unchanged");
}

exit 0;
