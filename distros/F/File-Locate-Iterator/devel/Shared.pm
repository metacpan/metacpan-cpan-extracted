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

package File::Map::Shared;
use strict;
use warnings;
use Carp;
use File::Map;
use Symbol;

my %cache;

sub map_file {
  my $filename = shift;
  my $mode = $_[0] || '<';
  open my $fh, $mode, $filename
    or croak "Couldn't open file $filename: $!";
  unshift @_, $fh;
  goto &map_handle;
}

sub map_handle {
  my ($fh, @args) = @_;
  $fh = Symbol::qualify_to_ref ($fh, caller);
  my ($dev, $ino) = stat ($fh);
  my $key = "$dev,$ino";
  return ($cache{$key} ||= do {
    my $mmap;
    File::Map::map_handle ($mmap, $fh, @args);
    my $ref = $cache{$key} = \$mmap;
    Scalar::Util::weaken ($cache{$key});
    $ref;
  });
}

package File::Locate::Iterator::TieHashDeleteUndef;
use Tie::Hash;
our @ISA = 'Tie::StdHash';

# sub TIEHASH {
#   my ($class) = @_;
#   return bless {}, $class;
# }
sub STORE {
  my ($self, $key, $value) = @_;
  $_[0]{$_[1]} = $_[2];
  if (! defined $value) {
    warn "Delete data with key $_[1].\n";
    delete $self->{$key};
  } else {
    warn "Storing data with key $_[1].\n";
    $self->{$key} = $value;
  }
}

package main;
my %h;
tie %h, 'File::Locate::Iterator::TieHashDeleteUndef';
$h{1} = 2;
$h{1} = undef;

require Scalar::Util;
$h{1} = [];
Scalar::Util::weaken ($h{1});
print "now $h{1}\n";

1;
__END__
