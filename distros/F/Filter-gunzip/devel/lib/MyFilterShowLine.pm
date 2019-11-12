# Copyright 2019 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Filter-gunzip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.

package MyFilterShowLine;
use strict;
use warnings;
use Filter::Util::Call;
use Devel::Peek;

sub import {
  my ($self, %options) = @_;
  my $count = (defined $options{'count'} ? $options{'count'} : 1);
  filter_add(sub {
               my $status = filter_read();
               if ($status > 0 && $count-- > 0) {
                 print "MyFilterShowLine line (status=$status):\n";
                 Devel::Peek::Dump($_);
                 print $_,"\n";
               }
               return $status;
             });
}
1;
__END__
