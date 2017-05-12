use Test::Simple 'no_plan';
use strict;
use lib './lib';
use GD::SecurityImage::Utils;
use Cwd;

my $abs_captcha_table_file = cwd().'/t/captcha_table.txt';
my $abs_font = cwd().'/t/luxisr.ttf';
unlink $abs_captcha_table_file;



# 1) CREATE A LIST OF IMAGES TO CREATE
my $max = 20; # how many?
my @abs_captchas;
while( $max-- ){
   push @abs_captchas, cwd()."/t/captcha_$max.png";
}


# 2) GENERATE IMAGES AND SAVE CODES
# save codes in a text file for lookup

open( CAPTCHA_TABLE_FILE, '>>',$abs_captcha_table_file) or die($!);

# for each in the list, make a image, and record the right code
for my $abs_out ( @abs_captchas ){
   
      unlink $abs_out; # just in case

      # create the captcha image and find out what the code is
      my $correct_code = write_captcha($abs_out,{font=>$abs_font});
   
      # save it in the file for later lookups
      print CAPTCHA_TABLE_FILE "$correct_code=$abs_out\n";

      ok(-f $abs_out, "saved $abs_out") or die;
   
}

close CAPTCHA_TABLE_FILE;



