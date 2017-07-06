#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Image::PNG::Libpng qw(read_png_file write_png_file) ;
my $pngin = read_png_file ("$Bin/../t/tantei-san.png");
my $pngout = $pngin->copy_png ();
$pngout->set_text ([{key => 'Name', text => 'Shunsaku Kudo'}]); 
# $pngout->write_png_file ('copy.png');
