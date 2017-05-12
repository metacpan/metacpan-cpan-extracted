#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

BEGIN {
  eval { require Iterator }
    or plan skip_all => "Iterator.pm not available -- $@";

  # version 3.002 for "tracked_types"
  eval "use Test::Weaken 3.002; 1"
    or plan skip_all => "due to Test::Weaken 3.002 not available -- $@";

  eval "use Test::Weaken::ExtraBits; 1"
    or plan skip_all => "due to Test::Weaken::ExtraBits not available -- $@";

  plan tests => 3;
}

diag ("Test::Weaken version ", Test::Weaken->VERSION);
diag ("Iterator::Simple version ", Iterator::Simple->VERSION);


#-----------------------------------------------------------------------------

use FindBin;
use File::Spec;
my $samp_locatedb = File::Spec->catfile ($FindBin::Bin, 'samp.locatedb');

require Iterator::Locate;

# database_file
{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Iterator::Locate->new (database_file => $samp_locatedb);
       },
       contents => \&Test::Weaken::ExtraBits::contents_glob_IO,
       tracked_types => [ 'GLOB', 'IO' ],
     });
  is ($leaks, undef, 'deep garbage collection');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

# database_fh
{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $filename = $samp_locatedb;
         open my $fh, '<', $filename
           or die "oops, cannot open $filename";
         return [ Iterator::Locate->new (database_fh => $fh),
                  $fh ];
       },
       contents => \&Test::Weaken::ExtraBits::contents_glob_IO,
       tracked_types => [ 'GLOB', 'IO' ],
     });
  is ($leaks, undef, 'deep garbage collection');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

# database_fh, no mmap
{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $filename = $samp_locatedb;
         open my $fh, '<', $filename
           or die "oops, cannot open $filename";
         return [ Iterator::Locate->new (database_fh => $fh,
                                         use_mmap => 0),
                  $fh ];
       },
       contents => \&Test::Weaken::ExtraBits::contents_glob_IO,
       tracked_types => [ 'GLOB', 'IO' ],
     });
  is ($leaks, undef, 'deep garbage collection');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

exit 0;
