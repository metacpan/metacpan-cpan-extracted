#!/usr/bin/perl -w

# Copyright 2012, 2014, 2015, 2020 Kevin Ryde

# This file is part of Image-Base-Wx.
#
# Image-Base-Wx is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Wx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Image::Base::Wx',
   ABSTRACT     => 'Image::Base drawing to Wx things.',
   VERSION_FROM => 'lib/Image/Base/Wx/DC.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   PREREQ_PM    => {
                    # actually only Wx::Image bits Image::Base ellipse(),
                    # but it's not too terrible to ask for it always
                    'Image::Base' => '1.12', # for ellipse() $fill

                    'Wx' => 0,
                   },
   MIN_PERL_VERSION => '5.008',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/image-base-wx/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },

     prereqs =>
     { test =>
       { suggests =>
         { 'Test::Weaken' => '2.000',
         },
       },
     },

     # Image::Base::Wx gets the dist name, no actual module of that name
     provides =>
     { 'Image::Base::Wx' => { file => 'META.yml',
                              version => 6,
                            },
       'Image::Base::Wx::Bitmap' =>
       { file => 'Image/Base/Wx/Bitmap.pm',
         version => 6,
       },
       'Image::Base::Wx::DC' =>
       { file => 'Image/Base/Wx/DC.pm',
         version => 6,
       },
       'Image::Base::Wx::Image' =>
       { file => 'Image/Base/Wx/Image.pm',
         version => 6,
       },
     },
   },
  );
