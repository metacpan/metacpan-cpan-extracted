#!/usr/bin/perl -w

# Copyright 2011, 2019 Kevin Ryde

# This file is part of Image-Base-SVG.
#
# Image-Base-SVG is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-SVG is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-SVG.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Test::More;

# suspect libxml too strict, use either the pureperl or expat
use SVG::Parser qw(SAX=XML::SAX::PurePerl Expat);

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

require Image::Base::SVG;
diag "Image::Base version ", Image::Base->VERSION;

if (eval { require XML::Parser::Expat; 1 }) {
  diag "XML::Parser::Expat version ", XML::Parser::Expat->VERSION;
  if (! eval { XML::Parser::Expat->VERSION(2.41); 1 }) {
    plan skip_all => "due to XML::Parser::Expat before 2.41 gets warnings for perl 5.14 incompatible changes -- $@";
  }
}

sub find_elem {
  my ($image, $tagname) = @_;
  my $svg = $image->get('-svg_object')
    || die "Oops, no svg_object";
  my $docroot = ($svg->getElements($svg->{'-docroot'}))[0]
    || die "Oops docroot not found";
  return ($docroot->getElements($tagname))[0]
    || die "Oops $tagname not found";
}

plan tests => 83;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 5;
  is ($Image::Base::SVG::VERSION, $want_version, 'VERSION variable');
  is (Image::Base::SVG->VERSION,  $want_version, 'VERSION class method');

  is (eval { Image::Base::SVG->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  is (! eval { Image::Base::SVG->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $image = Image::Base::SVG->new (-svg_object => 'dummy');
  is ($image->VERSION,  $want_version, 'VERSION object method');

  is (eval { $image->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  is (! eval { $image->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# new()

{
  my $image = Image::Base::SVG->new;
  is ($image->get('-file'), undef);
  is (defined $image && $image->isa('Image::Base') && 1,
      1,
      'isa Image::Base');
  is (defined $image && $image->isa('Image::Base::SVG') && 1,
      1,
      'isa Image::Base::SVG');
}
{
  my $image = Image::Base::SVG->new (-width => 6,
                                                     -height => 7);

  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::SVG');

  is ($image->get('-file'), undef);
  is ($image->get('-width'), 6, 'new() -width');
  is ($image->get('-height'), 7, 'new() -height');

  is_deeply ([$image->get('-width')], [6], 'new() -width array context');
  is_deeply ([$image->get('-height')], [7], 'new() -height array context');
}

#------------------------------------------------------------------------------
# -title

{
  my $title = 'hello world';
  my $image = Image::Base::SVG->new (-title => $title);
  is ($image->get('-title'), $title, 'new() -title');
  is_deeply ([$image->get('-title')], [$title], 'new() -title array context');
  isnt (find_elem($image,'title'), undef, '-title element');
}
{
  my $title = 'hello world';
  my $image = Image::Base::SVG->new;
  $image->set (-title => $title);
  is ($image->get('-title'), $title, 'new() -title');
  is_deeply ([$image->get('-title')], [$title], 'new() -title array context');
}

#------------------------------------------------------------------------------
# -description

{
  my $description = 'hello world';
  my $image = Image::Base::SVG->new (-description => $description);
  is ($image->get('-description'), $description, 'new() -description');
  is_deeply ([$image->get('-description')], [$description], 'new() -description array context');
  isnt (find_elem($image,'desc'), undef, '-description element');
}
{
  my $description = 'hello world';
  my $image = Image::Base::SVG->new;
  $image->set (-description => $description);
  is ($image->get('-description'), $description, 'new() -description');
  is_deeply ([$image->get('-description')], [$description], 'new() -description array context');
}


#------------------------------------------------------------------------------
# clone

# {
#   my $image = Image::Base::SVG->new (-width => 6,
#                                                      -height => 7);
#   my $i2 = $image->new;
#   is (defined $i2 && $i2->isa('Image::Base') && 1,
#       1,
#       'isa Image::Base');
#   is (defined $i2 && $i2->isa('Image::Base::SVG') && 1,
#       1,
#       'isa Image::Base::SVG');
#   ### $i2
#   is ($i2->get('-width'),  6, 'copy object -width');
#   is ($i2->get('-height'), 7, 'copy object -height');
#   is ($i2->get('-svg_object') != $image->get('-svg_object'),
#       1,
#       'copy object different -svg_object');
# }


#------------------------------------------------------------------------------
# save() / load()

my $tempfilename = 'tempfile.svg';
END { $tempfilename && unlink $tempfilename }

{
  my $image = Image::Base::SVG->new (-width => 20, -height => 10);
  isnt ($image->get('-svg_object'), undef);
  $image->rectangle (0,0, 19,9, '#000000');
  $image->save($tempfilename);
}
{
  my $image = Image::Base::SVG->new (-file => $tempfilename);
}
{
  my $image = Image::Base::SVG->new;
  $image->load($tempfilename);
}


#------------------------------------------------------------------------------
# xy()

{
  my $image = Image::Base::SVG->new (-width  => 100,
                                     -height => 100);
  $image->xy (50,60, '#112233');
  is ($image->xy (50,60), undef, 'xy() 50,50');
  is_deeply ([$image->xy (50,60)], [undef], 'xy() 50,50 - array context');
}
{
  my $colour = 'green';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->xy (2,3, $colour);

  my $rect = find_elem($image,'rect');
  my $href = $rect->getAttributes;
  is ($href->{'x'}, 2);
  is ($href->{'y'}, 3);
  is ($href->{'width'}, 1);
  is ($href->{'height'}, 1);
  is ($href->{'fill'}, $colour);
}

#------------------------------------------------------------------------------
# rectangle()

{
  my $colour = '#000000';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->rectangle (2,3, 4,8, $colour, 1); # filled

  my $rect = find_elem($image,'rect');
  my $href = $rect->getAttributes;
  is ($href->{'x'}, 2);
  is ($href->{'y'}, 3);
  is ($href->{'width'}, 3);
  is ($href->{'height'}, 6);
  is ($href->{'fill'}, $colour);
}
{
  my $colour = '#000000';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->rectangle (2,3, 4,8, $colour); # unfilled

  my $rect = find_elem($image,'rect');
  my $href = $rect->getAttributes;
  is ($href->{'x'}, 2.5);
  is ($href->{'y'}, 3.5);
  is ($href->{'width'}, 2);
  is ($href->{'height'}, 5);
  is ($href->{'stroke'}, $colour);
}
{
  my $colour = '#000000';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->rectangle (2,3, 2,3, $colour); # unfilled

  my $rect = find_elem($image,'rect');
  my $href = $rect->getAttributes;
  is ($href->{'x'}, 2);
  is ($href->{'y'}, 3);
  is ($href->{'width'}, 1);
  is ($href->{'height'}, 1);
  is ($href->{'fill'}, $colour);
}

#------------------------------------------------------------------------------
# ellipse

{
  my $colour = '#000000';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->ellipse (2,3, 4,8, $colour, 1); # filled

  my $ellipse = find_elem($image,'ellipse');
  my $href = $ellipse->getAttributes;
  is ($href->{'cx'}, 3.5);
  is ($href->{'cy'}, 6);
  is ($href->{'rx'}, 1.5);
  is ($href->{'ry'}, 3);
  is ($href->{'fill'}, $colour);
}
{
  my $colour = '#000000';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->ellipse (2,3, 4,8, $colour); # unfilled

  my $ellipse = find_elem($image,'ellipse');
  my $href = $ellipse->getAttributes;
  is ($href->{'cx'}, 3.5);
  is ($href->{'cy'}, 6);
  is ($href->{'rx'}, 1);
  is ($href->{'ry'}, 2.5);
  is ($href->{'stroke'}, $colour);
}
{
  my $colour = '#000000';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->ellipse (2,3, 2,3, $colour); # unfilled 1x1

  my $ellipse = find_elem($image,'ellipse');
  my $href = $ellipse->getAttributes;
  is ($href->{'cx'}, 2.5);
  is ($href->{'cy'}, 3.5);
  is ($href->{'rx'}, 0.5);
  is ($href->{'ry'}, 0.5);
  is ($href->{'fill'}, $colour);
}
{
  my $colour = '#000000';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->ellipse (2,3, 4,3, $colour); # unfilled, 3x1

  my $ellipse = find_elem($image,'ellipse');
  my $href = $ellipse->getAttributes;
  is ($href->{'cx'}, 3.5);
  is ($href->{'cy'}, 3.5);
  is ($href->{'rx'}, 1.5);
  is ($href->{'ry'}, 0.5);
  is ($href->{'fill'}, $colour);
}

#------------------------------------------------------------------------------
# line

{
  my $colour = '#abcdef';
  my $image = Image::Base::SVG->new (-width => 20,
                                                    -height => 10);
  $image->line (5,6, 7,8, $colour);

  my $ellipse = find_elem($image,'line');
  my $href = $ellipse->getAttributes;
  is ($href->{'x1'}, 5.5);
  is ($href->{'y1'}, 6.5);
  is ($href->{'x2'}, 7.5);
  is ($href->{'y2'}, 8.5);
  is ($href->{'stroke'}, $colour);
}


#------------------------------------------------------------------------------
# diamond()

{
  my $colour = '#000000';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->diamond (2,3, 4,8, $colour, 1); # filled
  
  #   2   3   4   5
  #   +---+---+---+3
  #   |   |   |   |
  #   |   |   |   |
  #   +---+---+---+4
  #   |   |   |   |
  #   |   |   |   |
  #   +---+---+---+5
  #   |   |   |   |
  #   |   |   |   |
  #   +---+---+---+6
  #   |   |   |   |
  #   |   |   |   |
  #   +---+---+---+7
  #   |   |   |   |
  #   |   |   |   |
  #   +---+---+---+8
  #   |   |   |   |
  #   |   |   |   |
  #   +---+---+---+9

  my $polygon = find_elem($image,'polygon');
  my $href = $polygon->getAttributes;
  ### $href
  is ($href->{'points'}, '3.5,3 2,6 3.5,9 5,6');
  is ($href->{'fill'}, $colour);
}
{
  my $colour = '#000000';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->diamond (2,3, 4,8, $colour); # unfilled

  my $polygon = find_elem($image,'polygon');
  my $href = $polygon->getAttributes;
  is ($href->{'points'}, '3.5,3.5 2.5,6 3.5,8.5 4.5,6');
  is ($href->{'stroke'}, $colour);
}
{
  my $colour = '#000000';
  my $image = Image::Base::SVG->new (-width => 20,
                                                     -height => 10);
  $image->diamond (2,3, 2,3, $colour); # unfilled

  #   2   3
  #   +---+3
  #   |   |
  #   |   |
  #   +---+4

  my $polygon = find_elem($image,'polygon');
  my $href = $polygon->getAttributes;
  is ($href->{'points'}, '2.5,3 2,3.5 2.5,4 3,3.5');
  is ($href->{'fill'}, $colour);
}


#------------------------------------------------------------------------------
# get('-file')

{
  my $image = Image::Base::SVG->new (-width => 10,
                                     -height => 10);
  is (scalar ($image->get ('-file')), undef);
  is_deeply  ([$image->get ('-file')], [undef]);
}

#------------------------------------------------------------------------------
# add_colours

{
  my $image = Image::Base::SVG->new (-width  => 100, -height => 100);
  if (! $image->can('add_colours')) {
    diag "skip no add_colours()";
  } else {
    $image->add_colours ('#FF00FF', 'None', '#FFaaaa');
  }
}

exit 0;
