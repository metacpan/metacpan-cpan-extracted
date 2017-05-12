#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Imager;
my $img = Imager->new ();
$img->read (file => 'my.jpg');
my $is = load_image ($img);

