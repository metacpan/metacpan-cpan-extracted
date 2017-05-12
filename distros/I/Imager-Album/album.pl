#!/usr/bin/perl -w

use Imager::Album;
use Imager::Album::GUI;
use Getopt::Std;
use Data::Dumper;


getopts("D:", \%Opts);


if ($Opts{'D'}) {
  $album = Imager::Album->new(working_dir=>$Opts{'D'});
} else {
  $album = Imager::Album->new();
}

$album->add_image($_) for @ARGV;
$album->update_previews();
#$gui = Imager::Album::GUI->new($album);
Imager::Album::GUI->new($album);
Imager::Album::GUI::boot();

