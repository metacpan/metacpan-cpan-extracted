#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Devel-Mallinfo.
#
# Devel-Mallinfo is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Devel-Mallinfo is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test;
BEGIN {
  plan tests => 4;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

my $have_test_weaken = eval "use Test::Weaken 3.002; 1";
if (! $have_test_weaken) {
  MyTestHelpers::diag ("Test::Weaken 3.002 not available -- $@");
}

MyTestHelpers::diag ("Test::Weaken version ", Test::Weaken->VERSION);


#-----------------------------------------------------------------------------
# mallinfo()

require Devel::Mallinfo;
{
  my $leaks = $have_test_weaken && Test::Weaken::leaks
    ({ constructor => sub {
         return \(scalar(Devel::Mallinfo::mallinfo()));
       },
     });
  ok (! defined $leaks,
      1,
      'mallinfo() in scalar context');
}
{
  my $leaks = $have_test_weaken && Test::Weaken::leaks
    ({ constructor => sub {
         return [ map {\$_} Devel::Mallinfo::mallinfo() ];
       },
     });
  ok (! defined $leaks,
      1,
      'mallinfo() in list context');
}

#-----------------------------------------------------------------------------
# malloc_info_string(), checking mortalize on the newsv
  
my $have_malloc_info_string = defined &Devel::Mallinfo::malloc_info_string;
if (! $have_malloc_info_string) {
  MyTestHelpers::diag ('malloc_info_string() not available');
}

{
  my $leaks = $have_test_weaken && $have_malloc_info_string
    && Test::Weaken::leaks
    ({ constructor => sub {
         return \(scalar(Devel::Mallinfo::malloc_info_string(0)));
       },
     });
  ok (! $leaks,
      1,
      'malloc_info_string() in scalar context');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

{
  my $leaks = $have_test_weaken && $have_malloc_info_string
    && Test::Weaken::leaks
    ({ constructor => sub {
         return [ map {\$_} Devel::Mallinfo::malloc_info_string(0) ];
       },
     });
  ok (! $leaks,
      1,
      'malloc_info_string() in list context');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
