#!/usr/bin/perl

use Test::More qw(no_plan);

BEGIN { use_ok("Image::Filter"); }

my $image = Image::Filter::newFromJpeg("munich.jpg");
ok($image);

my $imagebw = $image->filter("greyscale");
$imagebw->Jpeg("munichbw.jpg",100);
ok($imagebw,"Loaded from JPEG");

#Black & White filters

for(qw(emboss edge posterize))
{ my $image2 = $imagebw->filter($_);
  $image2->Jpeg("munich$_.jpg",100);
  ok($image2,"Applying $_");
  $image2->Destroy;
  ok($image2,"Destroyed Image");
}

for((32,64,128))
{ my $image2 = $imagebw->filter("floyd",$_);
  $image2->Jpeg("munichfloyd$_.jpg",100);
  ok($image2,"Applying Floyd $_");
  $image2->Destroy;
  ok($image2,"Destroyed Image");
}

#TrueColor filters

for(qw(rotate invert pixelize sharpen blur gaussian twirl swirl))
{ my $image2 = $image->filter($_);
  $image2->Jpeg("munich$_.jpg",100);
  ok($image2,"Applying $_");
  $image2->Destroy;
  ok($image2,"Destroyed Image");
}

my $image2 = $image->filter("blur",1);
$image2->Jpeg("munichblurbw.jpg",100);
ok($image2,"Applying BW Blur");
$image2->Destroy;
ok($image2,"Destroyed Image");

my $image2 = $image->filter("level",100);
$image2->Jpeg("munichlevel.jpg",100);
ok($image2,"Applying level");
$image2->Destroy;
ok($image2,"Destroyed Image");

for(1..10)
{ my $image2 = $image->filter("eraseline",$_,0);
  $image2->Jpeg("municheraseh$_.jpg",100);
  ok($image2,"Applying eraseline");
  $image2->Destroy;
  ok($image2,"Destroyed Image");
}

for(1..10)
{ my $image2 = $image->filter("eraseline",$_,1);
  $image2->Jpeg("municherasev$_.jpg",100);
  ok($image2,"Applying eraseline");
  $image2->Destroy;
  ok($image2,"Destroyed Image");
}

for(1..3)
{ $image2 = $image->filter("channel",$_);
  $image2->Jpeg("munichchannel$_.jpg",100);
  ok($image2,"Extracting layer $_");
}

for(2,4,6,8,10)
{ $image2 = $image->filter("ripple",$_);
  $image2->Jpeg("munichripple$_.jpg",100);
  ok($image2,"Rippling $_ waves");
}

for(32,64,96,128,160,192,224)
{ $image2 = $image->filter("solarize",$_);
  $image2->Jpeg("munichsolarize$_.jpg",100);
  ok($image2,"Solarizing with $_ ");
}

#
#for(5,6,7,8)
#{ $image2 = $image->filter("oilify",$_);
#  $image2->Jpeg("munichoilify$_.jpg",100);
#  ok($image2,"Oilifying $_");
#}

$image->Destroy;
$imagebw->Destroy;