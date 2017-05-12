#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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
  (NAME         => 'Image-Base-Wx',
   ABSTRACT     => 'Image::Base drawing to Wx things.',
   VERSION_FROM => 'lib/Image/Base/Wx/DC.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
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
     no_index => { directory=>['devel'] },

     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Test::Weaken' => '2.000',
                     },
       },
     },
   },
  );
