#!/usr/bin/perl -w

# Copyright 2007, 2012 Kevin Ryde

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

use Data::Dumper;
BEGIN {
  push @INC, '/home/gg/mallinfo/lib', '/home/gg/mallinfo/blib/arch';
}

use Devel::Mallinfo;
my $h = Devel::Mallinfo::mallinfo;
print "$h\n";
print Dumper (\$h);

print "arena ", $h->{'arena'}, "\n";

    my $info = Devel::Mallinfo::mallinfo();
    foreach my $field (keys %$info) {
      print "$field is $info->{$field}\n";
    }

