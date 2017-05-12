#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Other.
#
# Image-Base-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
BEGIN {
  plan tests => 2750;
}

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

require Image::Base::Multiplex;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 9;
  ok ($Image::Base::Multiplex::VERSION, $want_version, 'VERSION variable');
  ok (Image::Base::Multiplex->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Image::Base::Multiplex->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Image::Base::Multiplex->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $multiplex = Image::Base::Multiplex->new;
  ok ($multiplex->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $multiplex->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $multiplex->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# new()

{
  my $multiplex = Image::Base::Multiplex->new;
  ok (defined $multiplex && $multiplex->isa('Image::Base') && 1,
      1);
  ok (defined $multiplex && $multiplex->isa('Image::Base::Multiplex') && 1,
      1);
  my $aref = $multiplex->get('-images');
  ok ($aref && ref $aref eq 'ARRAY' && @$aref == 0,
      1,
      '-images default empty []');

  $multiplex->add_colours ('black');
  ok (1, 1, 'add_colours() when no images');
}

{
  require Image::Base::Text;
  my $text = Image::Base::Text->new (-width => 6,
                                     -height => 7);
  my $multiplex = Image::Base::Multiplex->new (-images => [$text]);
  my $aref = $multiplex->get('-images');
  ok ($aref && ref $aref eq 'ARRAY' && @$aref == 1 && $aref->[0] == $text,
      1,
      '-images one Text');
  ok ($multiplex->get('-width'), 6);
  ok ($multiplex->get('-height'), 7);

  $multiplex->xy (0,0, '*');
  ok ($text->xy(0,0), '*');

  $multiplex->add_colours ('black');
  ok (1, 1, 'add_colours() to one Text');
}

{

  require Image::Base::Text;
  my $text1 = Image::Base::Text->new (-width => 6,
                                      -height => 7);
  my $text2 = Image::Base::Text->new (-width => 8,
                                      -height => 9);

  my $multiplex = Image::Base::Multiplex->new (-images => [$text1,$text2]);
  my $aref = $multiplex->get('-images');
  ok ($aref && ref $aref eq 'ARRAY' && @$aref == 2 && $aref->[0] == $text1
      && $aref->[1] == $text2,
      1,
      '-images two Text');

  $multiplex->xy (0,0, '*');
  ok ($text1->xy(0,0), '*');
  ok ($text2->xy(0,0), '*');

  $multiplex->add_colours ('black');
  ok (1, 1, 'add_colours() to two Text');
}

{
  require Image::Base::Text;
  my $text = Image::Base::Text->new
    (-width => 21,
     -height => 10,
     -character_to_colour => { ' ' => 'black',
                               '*' => 'white' });
  my $multiplex = Image::Base::Multiplex->new (-images => [$text]);

  require MyTestImageBase;
  MyTestImageBase::check_image ($multiplex);
}

exit 0;
