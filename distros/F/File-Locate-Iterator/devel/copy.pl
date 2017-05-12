#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde.
#
# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator; see the file COPYING.  Failing that, go to
# <http://www.gnu.org/licenses/>.


# re-open and check dev/ino
# seek fileno, if seekable
# replicate layers?

use 5.004; # sysseek()
use strict;
use warnings;

# uncomment this to run the ### lines
use Smart::Comments;


# separate buffer, common underlying filepos

open my $fh, '<', '/usr/share/common-licenses/GPL-2' or die;
open my $fh2, '<&', $fh or die;
### $fh
### $fh2

my $l = readline($fh);
print "tell=",tell($fh),' sysseek=',sysseek($fh,0,1),"\n";
print "tell=",tell($fh2),' sysseek=',sysseek($fh2,0,1),"\n";

my $l2 = readline($fh2);
print "tell=",tell($fh),' sysseek=',sysseek($fh,0,1),"\n";
print "tell=",tell($fh2),' sysseek=',sysseek($fh2,0,1),"\n";

# print tell(fileno($fh)),"\n";
# print tell(fileno($fh2)),"\n";

### $l
### $l2


#           {
#             my $it = File::Locate::Iterator->new (@database_option,
#                                                   use_mmap => $use_mmap);
#             $it->next;
#             my $it2 = $it->copy;
#             is ($it->next, $it2->next, 'copied iterator 1');
#             is ($it->next, $it2->next, 'copied iterator 2');
#             is ($it->next, $it2->next, 'copied iterator 3');
#           }
