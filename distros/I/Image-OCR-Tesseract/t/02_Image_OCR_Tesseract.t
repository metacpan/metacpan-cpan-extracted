use Test::Simple 'no_plan';

BEGIN {
   ok 1, 'started.. will check for command dependencies..';
   deps_cli() or exit;

   sub deps_cli {
      for my $bin ( qw(convert tesseract) ){      
         warn("# Testing for command dep: $bin ..");
         require File::Which;

         File::Which::which($bin) or warn("# Missing path to executable: $bin")
            and return 0;
         ok 1,"have path to executable $bin, good.. ";
      }
      1;
   }
}

use lib './lib';
use Image::OCR::Tesseract ':all';
use File::Path;
# Smart::Comments '###';





$Image::OCR::Tesseract::DEBUG=1;

ok(1,"module loaded");

my $tmp1 ='./t/text.tmp';
my $content = 'This is text content
It is present.';
open(TMP,'>',$tmp1) or die("Cant write '$tmp1', $!");
print TMP  $content;
close TMP;
-f $tmp1 or die;

my $slurped = Image::OCR::Tesseract::_slurp($tmp1);
ok( $slurped,'_slurp()');
ok( $slurped=~/\Q$content\E/, "_slurp() has what we expected");





my $abs_tmp = './t/tmp';
File::Path::rmtree($abs_tmp);
mkdir $abs_tmp;


my $abs_small = './t/img_small.jpg';
my $abs_med = './t/img_med.jpg';
my $abs_big = './t/img_big.jpg';

my @imgs =('./t/paragraph.jpg',$abs_small, $abs_med, $abs_big);

for my $abs (@imgs){
   printf "\n%s\ntesting image: '%s'\n", '-'x80, $abs;
   my($text,$at,$tx,$length);

   ok( $at = convert_8bpp_tif($abs, './t/tmp/outtif.tif'), "convert_8bpp_tif()");
   ### $at
   ok( $tx = tesseract($at), 'tesseract()');
   $length = length $tx;
   ok( $length,'output had length');
   ### output from tesseract: $tx
   ### length of output: $length

   ok( $text = get_ocr($abs,$abs_tmp),"get_ocr()");
   ### text output is: $text
   
   
}







