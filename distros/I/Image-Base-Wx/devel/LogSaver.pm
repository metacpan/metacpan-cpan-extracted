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


package Wx::Perl::LogSaver;
use strict;
use Wx;

# $saver = Wx::Perl::LogSaver->new($newlogger);
# old logger restored on DESTROY

sub new {
  my ($class, $log) = @_;
  my $self = bless { }, $class;
  $self->install($log);
  return $self;
}
sub install {
  my ($self, $log) = @_;
  my $oldlog = Wx::Log::SetActiveTarget($log);
  if (! exists $self->{'oldlog'}) {
    $self->{'oldlog'} = $oldlog;
  }
}
sub uninstall {
  my ($self) = @_;
  Wx::Log::SetActiveTarget(delete $self->{'oldlog'});
}
sub DESTROY {
  my ($self) = @_;
  $self->uninstall;
}

1;
__END__
