use Test::Simple 'no_plan';
use strict;

use lib './lib';
use Image::Magick;
use Image::Magick::Stencilize;



opendir(DIR,'./t');
my @imgs = map { "./t/$_" } grep { !/out/ and /\.jpg$/ } readdir DIR;
closedir DIR;


my $image = new Image::Magick;
# freaking image magick's methods return on error mostly.. messed up
# at a given moment, either you code perl or you code c, you don't do
# both at the same time

for(@imgs){
   _doone($_);
}



sub _doone {
   my $abs = shift;
   my $threshold = 10;
   
   for (1 .. 3){
   
      $threshold+=10;   

      @$image=();
      my $x =  $image->Read($abs);
      ok(!$x) or die($x);

      my $out=$abs;
      $out =~s/(\.\w+)$/_out_$threshold$1/;

      ok( !$image->Stencilize($threshold,1), "Stencilize()");

   
      ok( ! $image->Write($out), " wrote $out");
     
   }
}





