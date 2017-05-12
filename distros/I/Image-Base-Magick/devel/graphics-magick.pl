#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-Magick.
#
# Image-Base-Magick is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Magick is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Magick.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Graphics::Magick;

use Smart::Comments;

use lib 't';
use MyTestImageBase;


{
  my $m = Graphics::Magick->new (
                                 # width => 20, height => 10,
                                 size => '20x10',
                                 # size => '20x',
                                );
  { my $err = $m->ReadImage('xc:black');
    if ($err) { die $err; }
  }
  require Image::Base::Magick;
  my $image = Image::Base::Magick->new
    (-imagemagick => $m);
  $image->rectangle (0,0, 19,9, 'black', 1);

  $m->Draw(stroke=>'white',
           primitive=>'ellipse',
           points=>'5,5, 4,4, 0,360');

  $m->Write ('xpm:-');
  $image->save('/dev/stdout');
  exit 0;
}

{
  my $m = Graphics::Magick->new (
                              # width => 20, height => 10,
                              size => '20x10',
                              # size => '20x',
                             );
  ### initial width: $m->Get('width')
  ### initial size: $m->Get('size')
  ### format: $m->Get('format')
  ### magick: $m->Get('magick')

  ### ReadImage xc-black
  my $err = $m->ReadImage('xc:black');
  if ($err) { die $err; }
  ### $m

  ### now width: $m->Get('width')
  ### now size: $m->Get('size')
  ### now format: $m->Get('format')
  ### now magick: $m->Get('magick')

  @$m = ();
  my $filename = '/usr/share/emacs/23.2/etc/images/icons/hicolor/16x16/apps/emacs.png';
  $filename = '/tmp/x';
  ### Read: $filename
  require Fcntl;
  sysopen FH, $filename, Fcntl::O_RDONLY() or die;
  binmode FH or die;
  $m->Read(file => \*FH);

  # $m->Read($filename);

  # $m->Set(size=>'20x10');
  # $m->Set (width => 18);
  ### png width: $m->Get('width')
  ### png size: $m->Get('size')

  $m->Set (size => '6x8');
  ### setsize width: $m->Get('width')
  ### setsize size: $m->Get('size')

  ### format: $m->Get('format')
  ### magick: $m->Get('magick')
  ### filename: $m->Get('filename')

  $m->Set(filename => '/tmp/zz.png');
  $m->Write;
  exit 0;
}

{
  my $m = Graphics::Magick->new or die;
  my $filename = '/tmp/foo.png';

  my $image = Graphics::Magick->new or die;
  $image->Set(size=>'100x100');
  $image->ReadImage('xc:white');
  $image->Set('pixel[49,49]'=>'red');

  $image->Set(magick=>'png');

  open(IMAGE, ">$filename");
  my $status = $image->Write (file => \*IMAGE,
                              #   filename=>$filename,
                             );
  close(IMAGE);
  ### $status

  system ("ls -l $filename");
  exit 0;
}


{
  use strict;
  use warnings;
  use Graphics::Magick;

  unlink "/tmp/out.png";
  my $m = Graphics::Magick->new (size => '1x1');
  if (!$m) { die; }
  ### $m

  my $err = $m->ReadImage('xc:black');
  if ($err) { die $err; }
  ### $m

  my $filename = "/tmp/x%d.blah";
   $filename = "/tmp/xx.png";
  $m->Write (filename => $filename,
             # quality => 75,
            );

  $m = Graphics::Magick->new; #  (size => '64x64');
  if (!$m) { die; }
  ### $m

  # $err = $m->SetAttribute (debug => 'all,trace');
  # $err = $m->SetAttribute (debug => 'all');
  # if ($err) { die $err; }

  # $m->set(filename => "/tmp/x%d.png");
  # $m->ReadImage('xc:black');
  #  $err = $m->Read ();

  open FH, "< $filename" or die;
  $err = $m->Read (file => \*FH,
                   # filename => $filename.'xx',
                  );
  ### $err
  ### $m
  ### magick: $m->Get('magick')
  ### width: $m->Get('width')
  ### size: $m->Get('size')

  $m->Write ("/tmp/out.png");
  exit 0;
}




{
  my $m = Graphics::Magick->new;
  ### m: $m->Get('magick')
  $m->Read('/usr/share/emacs/23.2/etc/images/icons/hicolor/16x16/apps/emacs.png');
  ### magick: $m->Get('magick')
  ### width: $m->Get('width')
  ### height: $m->Get('width')
  ### size: $m->Get('size')
  # $m->Set(magick => '');
  ### m: $m->Get('magick')
  $m->Read('/usr/share/webcheck/favicon.ico');
  ### m: $m->Get('magick')

  $m->Write(filename => '/tmp/image%%03d.data');
  exit 0;
}

{
  my $m = Graphics::Magick->new;
  # $m->Set(width=>10, height => 10);
  $m->Set(size=>'20x10');
  $m->ReadImage('xc:black');

  say $m->Get('width');
  say $m->Get('height');
  say $m->Get('size');

  # $m->Draw(fill=>'white',
  #          primitive=>'rectangle',
  #          points=>'5,5 5,5');
  $m->Draw(fill=>'white',
           primitive=>'point',
           points=>'5,5');

  #   $m->Draw(stroke=>'red', primitive=>'rectangle',
  #            points=>'5,5, 5,5');

  #   $m->Draw(fill => 'black',
  #            primitive=>'point',
  #            point=>'5,5');

  # $m->Set('pixel[5,5]'=>'red');
  say $m->GetPixel (x => 5, y => 5);
  say $m->Get ('Pixel[5,5]');

  $m->Write ('xpm:-');
  exit 0;

  $m->Set (size=>'20x10');
  $m->Set (magick=>'xpm');
  $m = Graphics::Magick->new;
  $m->Set(size=>'20x10');
  $m->ReadImage('xc:white');

  # #$m->Read ('/usr/share/emacs/22.3/etc/images/icons/emacs_16.png');
  #   $m->Draw (primitive => 'rectangle',
  #             points => '0,0, 19,9',
  #             method => 'Replace',
  #             stroke => 'black',
  #             fill => 'black',
  #            );

  $m->Draw (primitive => 'point',
            points => '0,0, 2,2',
            method => 'Replace');

  $m->Quantize(colours => 4);
  exit 0;
}



{
  use strict;
  use warnings;
  use Graphics::Magick;

  my $m = Graphics::Magick->new (size => '20x10');
  if (!$m) { die; }
  ### $m

  my $err = $m->ReadImage('xc:black');
  if ($err) { die $err; }
  ### $m

  $err = $m->SetPixel (x=>3, y=>4, color=>'#AABBCC');
  if ($err) { die $err; }

  exit 0;
}
