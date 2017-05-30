#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2014, 2015 Kevin Ryde

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

use 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Image::Base::X11::Protocol',
   ABSTRACT     => 'Image::Base drawing into X windows and pixmaps using X11::Protocol.',
   VERSION_FROM => 'lib/Image/Base/X11/Protocol/Drawable.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   PREREQ_PM    => {
                    # ellipse() $fill done natively, so no need to depend on
                    # Image::Base 1.12 for that
                    # diamond() done entirely natively, so no need to depend on
                    # Image::Base 1.16 for that
                    'Image::Base' => 0,

                    # 0.56 for robust_req() fix
                    'X11::Protocol' => '0.56',

                    'X11::Protocol::Other' => 3,
                    },
   TEST_REQUIRES => {
                    'Test' => 0,
                   },
   MIN_PERL_VERSION => '5.004',

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     no_index => { directory=>['devel','xt'] },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/image-base-x11-protocol/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
   });
