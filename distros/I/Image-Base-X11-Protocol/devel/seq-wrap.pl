#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-X11-Protocol.
#
# Image-Base-X11-Protocol is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-X11-Protocol is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-X11-Protocol.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use X11::Protocol;

use Smart::Comments;

use lib 't';
use MyTestImageBase;

{
  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;
  # ### $X
  my $rootwin = $X->{'root'};

  my $reply;
  my $seq = $X->send('QueryPointer',$rootwin);
  $X->add_reply ($seq, \$reply);

  for (;;) {
    $X->handle_input;
    if ($reply) {
      undef $reply;
      $seq = $X->send('QueryPointer',$rootwin);
      $X->add_reply ($seq, \$reply);
      print "now seq $seq\n";
    }
  }
  exit 0;
}
