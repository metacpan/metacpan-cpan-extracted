# Copyright 2009 Kevin Ryde.
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

package Sys::Mmap::Object;
use strict;
use warnings;
use Sys::Mmap;
use Scalar::Util;

my %cache;

sub new {
  my ($class, $filename) = @_;

  return $cache{$filename} || do {
    open my $fh, '<', $filename
      or die "Cannot open $filename: $!";
    my $self = bless { filename => $filename,
                       fh       => $fh,
                       mmap     => undef }, $class;
    Sys::Mmap::mmap ($self->{'mmap'}, 0,
                     Sys::Mmap::PROT_READ(), Sys::Mmap::MAP_SHARED(), $fh)
        or die "Cannot mmap\n";
    $cache{$filename} = $self;
    Scalar::Util::weaken ($cache{$filename});
    $self;
  };
}

sub DESTROY {
  my ($self) = @_;
  Sys::Mmap::munmap ($self->{'mmap'})
      or die "Oops, cannot munmap\n";

  # FIXME: not weakened yet ...
  my $filename = $self->{'filename'};
  print "DESTROY ", $cache{$filename}//'undef',"\n";
  if (! defined $cache{$filename}) {
    delete $cache{$filename};
  }
}

if (1) {
  package main;
  my $filename = '/var/cache/locate/locatedb';
  my $m1 = Sys::Mmap::Object->new ($filename);
  print $m1,"\n";
  my $m2 = Sys::Mmap::Object->new ($filename);
  print $m2,"\n";

  undef $m1;
  undef $m2;
  print $cache{$filename}//'undef',"\n";
  print exists $cache{$filename} ? "yes\n" : "no\n";
}

1;
__END__
