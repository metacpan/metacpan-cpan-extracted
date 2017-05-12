#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Image-Base-Wx.
#
# Image-Base-Wx is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Wx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

package Wx::Perl::LogCapture;
use Scalar::Util 'refaddr';
use Carp;

use base 'Wx::LogStderr';
my %fh;

sub new {
  my ($class) = @_;
  require File::Temp;
  my $fh = File::Temp->new;
  my $self = $class->SUPER::new($fh);
  bless $self, $class;  # re-bless into subclass
  $fh{refaddr($self)} = $fh;
  return $self;
}
sub content {
  my ($self) = @_;
  my $fh = $fh{refaddr($self)};
  seek $fh, 0, 0
    or croak "Oops, cannot rewind tempfile ",$fh->filename,": $!";
  return do { local $/; <$fh> }; # slurp
}
sub DESTROY {
  my ($self) = @_;
  delete $fh{refaddr($self)};
}
1;
__END__
