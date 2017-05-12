#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2014 Kevin Ryde

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
use FindBin;
use File::Spec;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

## no critic (ProtectPrivateSubs)

eval { require File::Map;
       File::Map->VERSION('0.38'); # as per FileMap.pm
       1 }
  or plan skip_all => "File::Map 0.38 not available -- $@";
diag "File::Map version ",File::Map->VERSION;

plan tests => 14;

use_ok ('File::Locate::Iterator::FileMap');
my $want_version = 23;
is ($File::Locate::Iterator::FileMap::VERSION, $want_version,
    'VERSION variable');
is (File::Locate::Iterator::FileMap->VERSION, $want_version,
    'VERSION class method');
{ ok (eval { File::Locate::Iterator::FileMap->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { File::Locate::Iterator::FileMap->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

# uncomment this to run the ### lines
# use Smart::Comments;

# $FindBin::Bin is tainted, it seems.
# Untaint $samp_locatedb so it can be opened.
my $samp_locatedb = File::Spec->catfile ($FindBin::Bin, 'samp.locatedb');
$samp_locatedb =~ /(.*)/ and $samp_locatedb = $1;  # untaint

#-----------------------------------------------------------------------------
# _have_mmap_layer()

{
  # Crib note: setting $ENV{'PERLIO'} has no effect, the default layers have
  # already been determined, but :raw overrides.
  my $fh;
  eval { open $fh, '<:raw', $samp_locatedb }   # if perlio
    or eval { open $fh, '<', $samp_locatedb }  # if older perl
      or die "oops, cannot open $samp_locatedb: $!";
  diag "not-mmap layers: ",join(' ',PerlIO::get_layers($fh));
  ok (! File::Locate::Iterator::FileMap::_have_mmap_layer($fh),
      '_have_mmap_layer identify no :mmap layer');
}

# File::Map depends on 5.008 which has PerlIO.pm, not sure how much should
# do to work without it ... the layer checks are fairly important
#
my $have_PerlIO = eval { require PerlIO; };
if (! $have_PerlIO) { diag "PerlIO module not available -- $@"; }
### $have_PerlIO

SKIP: {
  $have_PerlIO
    or skip 'PerlIO module not available', 1;

  my $fh;
  my $nosuchlayer;
  do {
    local $SIG{'__WARN__'} = sub {
      ### warn handler: @_
      if ($_[0] =~ /Unknown PerlIO layer/) {
        $nosuchlayer = 1;
      } else {
        warn $_[0];
      }
    };
    ### open: $samp_locatedb
    open $fh, '<:mmap', $samp_locatedb;
  } or skip "Cannot open $samp_locatedb with mmap: $!", 1;
  if ($nosuchlayer) {
    skip "No :mmap layer available", 1;
  }
  diag "mmap layers: ",join(' ',PerlIO::get_layers($fh));
  ok (File::Locate::Iterator::FileMap::_have_mmap_layer($fh),
      '_have_mmap_layer identify :mmap layer');
}

#-----------------------------------------------------------------------------
# _round_up_pagesize()

is (File::Locate::Iterator::FileMap::_round_up_pagesize(0), 0,
    '_round_up_pagesize(0)');
diag "_PAGESIZE is ",File::Locate::Iterator::FileMap::_PAGESIZE();
is (File::Locate::Iterator::FileMap::_round_up_pagesize(1),
    File::Locate::Iterator::FileMap::_PAGESIZE(),
    '_round_up_pagesize(1)');

#-----------------------------------------------------------------------------
# _total_space()

is (File::Locate::Iterator::FileMap::_total_space(0), 0,
    '_total_space() zero initially');

is (File::Locate::Iterator::FileMap::_total_space(1),
    File::Locate::Iterator::FileMap::_PAGESIZE(),
    '_total_space(1)');

#-----------------------------------------------------------------------------
# get()/find() caching

{
  open my $fh, '<', $samp_locatedb
    or die "oops, cannot open $samp_locatedb";
  binmode($fh)  # against msdos :crlf
    or die 'oops, cannot set binmode';

  is (File::Locate::Iterator::FileMap->find($fh), undef,
      'find() not mapped yet');
  my $fm1 = File::Locate::Iterator::FileMap->get ($fh);
  my $fm2 = File::Locate::Iterator::FileMap->get ($fh);
  is ($fm1, $fm2, "get() re-used");

  my $fm = $fm1;
  Scalar::Util::weaken ($fm);
  undef $fm1;
  undef $fm2;
  is ($fm, undef, 'FileMap destroyed when weakened');
}


exit 0;
