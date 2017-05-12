#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-Prima.
#
# Image-Base-Prima is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Prima is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Prima.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
# use blib "$ENV{HOME}/perl/prima/Prima-1.28/blib";
use lib "$ENV{HOME}/perl/prima/Prima-1.28/inst/local/lib/perl/5.10.1/";
# use Prima::noX11;
use Prima;

use Smart::Comments;

{
  use Prima;
  use Prima::Const;

  my $d = Prima::Image->new;
  $d = Prima::Image->load('/usr/share/emacs/23.3/etc/images/icons/hicolor/16x16/apps/emacs.png',
                          loadExtras => 1);
  ### width: $d->width
  ### heightwidth: $d->height
  ### extras: $d->{'extras'}
  my $codecs = $d->codecs;
  ### fileShortTypes: map {$_->{'fileShortType'}} @{$d->codecs}
  ### codecs: $codecs

  # $d = Prima::Image->new (width => 1, height => 1);
  # $d->save (\*STDOUT) or die $@;
  exit 0;
}
