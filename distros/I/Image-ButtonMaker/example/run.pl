#!/usr/bin/perl

#### Run this script to see Image::ButtonMaker in action
##   The results can be viewed in the 'buttons' directory.

use strict;

use lib '../lib';
use Image::ButtonMaker;

my $TARGET_DIR = 'buttons';
my $PIECES_DIR = 'pieces';


my $bmaker = Image::ButtonMaker->new();

#### Add paths for ButtonMaker to look after fonts and images
$bmaker->add_font_dir($PIECES_DIR);
$bmaker->add_image_dir($PIECES_DIR);

#### Read class file and then the button list
$bmaker->read_classfile('classes.pl');
$bmaker->read_buttonfile('buttons.pl');

mkdir ($TARGET_DIR)
  unless(-d $TARGET_DIR);

$bmaker->set_target_dir($TARGET_DIR);

$bmaker->generate();

exit(0);
