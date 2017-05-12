use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Image::Magick::Thumbnail::PDF 'create_thumbnail';
use Cwd;
use Smart::Comments '###';
use File::Path;
use File::Copy;

Image::Magick::Thumbnail::PDF::DEBUG = 1;
my $abs_pdf = cwd().'/t/test/linux_quickref.pdf';

File::Path::rmtree(cwd().'/t/test');
mkdir cwd.'/t/test';

ok( -d cwd.'/t/test','test dir exists');
ok( File::Copy::cp( cwd().'/t/file1.pdf', $abs_pdf), 'copied test file to test dir' );

my $out;
ok( $out = create_thumbnail($abs_pdf,'all_pages'),'create_thumbnail() all pages');
### $out








