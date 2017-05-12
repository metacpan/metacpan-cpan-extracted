#!/usr/bin/env perl
use strict;

use Carp;

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

END{
}

#$InSilicoSpectro::Utils::io::VERBOSE=1;
use InSilicoSpectro::InSilico::CleavEnzyme;
use InSilicoSpectro;
eval{
  InSilicoSpectro::init(@ARGV);

  print "\n ******* list of every enzyme *********\n";
  foreach (InSilicoSpectro::InSilico::CleavEnzyme::getList()){
    print;
  }
};
if ($@){
  print STDERR "error trapped in main\n";
  carp $@;
}
