#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-SVG.
#
# Image-Base-SVG is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
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
use Smart::Comments;

my $filename = '/tmp/x.svg';
use SVG;

{
  require Image::Base::SVG;
  my $image = Image::Base::SVG->new (
                                     -width  => 500,
                                     -height => 400,
                                    );
  # ### $image
  ### height: $image->get('-height')

  $image->set (-title  => 'Hello World',
               -width  => 501,
               -height => 402,
              );
  ### height: $image->get('-height')

  $image->xy (1,1, 'blue');
  $image->rectangle (30,40, 80,90, 'green');
  $image->rectangle (230,40, 280,90, 'green', 1);

  $image->ellipse (30,240, 80,290, 'red');
  $image->ellipse (230,240, 280,290, 'red', 1);

  $image->line (30,340, 380,390, 'white', 1);

  $image->diamond (330,40, 380,90, 'pink', 0);
  $image->diamond (330,140, 380,190, 'pink', 1);

  print $image->save($filename);
  system ("cat $filename");

  # {
  #   use SVG::Parser 'Expat';
  #   my $parser = SVG::Parser->new (-debug => 1);
  #   my $svg = $parser->parsefile ($filename);
  # }

  system ("xzgv $filename");

  $image->load($filename);
  exit 0;
}
{
  my $svg = SVG->new;
  $svg->tag('title')->cdata('hello');
  my $xml = $svg->xmlify;
  $xml =~ s/title /title/;
  print "$xml\n";
  {
    require XML::LibXML;
    my $parser = XML::LibXML->new;
    $parser->set_option(validation => 0);
    $parser->set_option(recover => 1);
    my $dom = $parser->parse_string($xml);
    print "DOM: $dom\n";
  }
  exit 0;
  {
    require SVG::Parser::SAX;
    my $parser = SVG::Parser::SAX->new (-debug=>1);
    $parser->parse(Source => {String => $xml});
  }
  exit 0;
}
{
  my $svg = SVG->new (width=>456,height=>123);
  my @elems = $svg->getElements();
  ### @elems

  $svg->comment('abc');
  $svg->comment('def');
  #   $svg->title->cdata('abcdef');
  ### $svg
  $svg = $svg->cloneNode;
  print $svg->xmlify;
  print $svg->xmlify;
  print $svg->xmlify;
  exit 0;
}

{
  require XML::SAX;
  my $parsers = XML::SAX->parsers();
  ### $parsers
  exit 0;
}

{
  require SVG;
  my $svg = SVG->new (width=>100,height=>100);
  my $tag;
  # $tag = $svg->circle(cx=>4, cy=>2, r=>1);

  $tag = $svg->ellipse(
                       cx=>10, cy=>10,
                       rx=>5, ry=>7,
                       id=>'ellipse',
                       style=>{
                               'stroke'=>'red',
                               'fill'=>'green',
                               'stroke-width'=>'4',
                               'stroke-opacity'=>'0.5',
                               'fill-opacity'=>'0.2'
                              }
                      );

  # $tag = $svg->rectangle(
  #                        x=>10, y=>20,
  #                        width=>4, height=>5,
  #                        rx=>5.2, ry=>2.4,
  #                        id=>'rect_1'
  #                       );

  print $svg->xmlify;
  exit 0;
}
