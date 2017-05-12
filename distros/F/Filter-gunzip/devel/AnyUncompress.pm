# Copyright 2010, 2011, 2013, 2014 Kevin Ryde

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

package Filter::AnyUncompress;
use strict;
use warnings;
use Carp;
use Filter::Util::Call;

our $VERSION = 6;

use constant DEBUG => 1;

sub filter {
  my ($self) = @_;
  if (DEBUG) { print STDERR "AnyUncompress\n"; }

  my $status = filter_read(3);
  if (DEBUG) { print " filter_read() $status\n"; }
  if ($status <= 0) { return $status; }

  my $class = ($_ eq "\037\213" ? 'Filter::Gunzip'
               : $_ eq 'BZh'    ? 'Filter::Bunzip2'
               : undef);
  filter_del($self);
  if ($class) {
    eval "require $class";
    my $f = $class->new (input => $_);
    filter_add($f);
  }
}

sub import {
  my ($class) = @_;
  my $self = $class->new;
  filter_add($self);
}

sub new {
  my ($class) = @_;
  return bless {}, $class;
}

1;
__END__
