#!/usr/bin/env perl
use strict;
use Carp;

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

END{
}

use InSilicoSpectro::Spectra::MSSpectra;
$InSilicoSpectro::Utils::io::VERBOSE=1;

my $iTest=shift @ARGV;
die "must provide a test number"unless defined $iTest;

if($iTest==1){
  my $file=shift @ARGV or die "specify a file  as first argument";
  my $format=shift @ARGV ;
  my $sp=InSilicoSpectro::Spectra::MSSpectra->new(source=>$file, format=>$format);
  $sp->format('dta') if -d $file;
  $sp->open();

  $sp->write('mgf');
  exit(0);
}


die "no test defined for argument [$iTest]";
