use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Image::Magick::Thumbnail::PDF 'create_thumbnail';
use Cwd;
use File::Path;
use File::Copy;
use File::Which 'which';





sub _ghostscript_version_ok {

   my $gbin = which('ghostscript') or return 0;
   my $v = `$gbin -v`;
   chomp $v;
   
   defined $v or return 0;
   $v or return 0;
   
   ok($v," ghostscript version [$v]") or return 0;
   
   my $ver=0;
   if ( $v=~/(ESP Ghostscript 8[\.\d]*)/ ){
      $ver = $1;
   }
   elsif( $v=~/(GNU Ghostscript 7[\.\d]*)/ ){
      $ver = $1;
   }
   else {
      ok(1,"version is [$ver], but it's not ok") and return 0;
   }   
   
   ok( $ver,' version is ok' ) or return 0;
   
   return $ver;   
}





#ok( _ghostscript_version_ok() , 'ghostscript version is ok');





$Image::Magick::Thumbnail::PDF::DEBUG = 1;
my $abs_pdf = cwd().'/t/test0/file1.pdf';

File::Path::rmtree(cwd().'/t/test0');
File::Path::rmtree(cwd().'/t/test1');
File::Path::rmtree(cwd().'/t/test2');
File::Path::rmtree(cwd().'/t/test3');

ok( mkdir (cwd.'/t/test0'),'made test dir');
ok( File::Copy::cp( cwd().'/t/file1.pdf', $abs_pdf), 'copied test file to test dir' );



my $out;

my $ok_create = create_thumbnail($abs_pdf,1);

my $continue_testing=1;

if (!$ok_create){

   ok(1,'seems like there is s a problem creating a thumbnail, checking for correct ESP Ghostscript...');

   if ( my $v = _ghostscript_version_ok() ){
      
      ok( 0, " correct ghostscript version IS installed [$v], BUT we cant make thumbnail- back to the drawing board");
      exit;   
   }

   else {
      $continue_testing = 0;
      ok( 1, "You do NOT have the correct Ghostscript version, you need GNU Ghostscript or ESP Ghostscript");
   }

}

else {
   ok(1,"created just fine.");
}



if( $continue_testing ){



   ok( $out = create_thumbnail($abs_pdf,1),'create_thumbnail()');
   
   ok( $out eq cwd().'/t/test0/file1-001.png','create_thumbnail() returns as expected '.$out );





   ok(1,"\nVARIATIONS");
   
   ok( $out = create_thumbnail($abs_pdf, cwd().'/t/test0/filepage2.png',  2),'create_thumbnail() named outfile');
   ok(1," out now: $out");
   ok( $out eq  cwd().'/t/test0/filepage2.png','create_thumbnail() returns as expected 1');

   





   ok( $out = create_thumbnail($abs_pdf, { restriction => 50, frame => 2, },2),'create_thumbnail() 4');
   ok(1," out now: $out ");

   ok( $out eq  cwd().'/t/test0/file1-002.png','create_thumbnail() returns as expected 4');


   ok(1,"\n OTHER EXAMPLES");

   ok(
      create_thumbnail(
	      $abs_pdf, { 
		      restriction => 350, 
		      frame => 6, 
	   	   normalize => 0,
	      },
	      2,
      ),
      'create_thumbnail() var 1'
   );

   ok(
      create_thumbnail(
	      $abs_pdf, { 
		      restriction => 800, 
		      frame => 6, 
	   	   normalize => 0,
	      },
	      1,
      ),
      'create_thumbnail() var 2'
   );

}

else {}


