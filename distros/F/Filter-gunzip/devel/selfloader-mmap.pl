#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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


# Run as PERLIO=mmap perl selfloader-mmap.pl

use strict;
use warnings;
use SelfLoader;

sub lseektell {
  my ($fd) = @_;
  return POSIX::lseek ($fd, 0, POSIX::SEEK_CUR());
}

my $fd = POSIX::dup(fileno(\*DATA));
print "dup fd $fd\n";
print "dup fd lseek=",lseektell($fd),"\n";

my $fileno = fileno(DATA);
print "fileno $fileno tell=",tell(\*DATA)," sysseek=",sysseek(\*DATA,0,1),
  " lseek=",lseektell($fileno),"\n";

my $pid = fork();
if (! defined $pid) { die $!; }
if ($pid != 0) { sleep 2 }

# if ($pid == 0) {
#   print "fuser:\n";
#   system 'fuser', '-v', $0;
# }

print "tell=",tell(\*DATA)," sysseek=",sysseek(\*DATA,0,1),
  " lseek=",lseektell($fileno),"\n";
print "fd lseek=",lseektell($fd),"\n";
# print defined(&foo),"\n";
print "$$ $pid call foo()\n";
foo();
print "$$ $pid done foo()\n";
print "tell=",tell(\*DATA)," sysseek=",sysseek(\*DATA,0,1),
  " lseek=",lseektell($fileno,0),"\n";
print tell(\*DATA)," ",sysseek(\*DATA,0,1),"\n";
print "fd lseek=",lseektell($fd),"\n";
print "\n";

POSIX::lseek($fd,0,POSIX::SEEK_END());
exit 0;


__DATA__
sub foo {
  print "this if foo\n";
}
