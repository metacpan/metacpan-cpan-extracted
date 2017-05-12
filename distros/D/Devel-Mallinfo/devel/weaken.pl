#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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
use warnings;
use Devel::Mallinfo;
use Test::Weaken 'leaks';
use Devel::Peek;

# uncomment this to run the ### lines
use Smart::Comments;

our $F1 = 456;
use constant F1 => 123;
my $global = 123;
sub F2 {
  return $global;
}
sub F3 () {
  return 123;
}
{ my $scalar = 456;
  *F4 = sub () { 456 };
}


{ my $leaks = leaks (sub { \(F4()) });
  ### $leaks
}

{ my $symtab = \%main::;
  my $entry = $symtab->{'F1'};
  ### $entry
}

# { my $glob = *F1;
#   ### $glob
#   Dump($glob);
#   Dump(*F3);
# }
# { my $leaks = leaks (sub { \(Devel::Mallinfo::malloc_info_string(0)) });
#   ### $leaks
# }

exit 0;
