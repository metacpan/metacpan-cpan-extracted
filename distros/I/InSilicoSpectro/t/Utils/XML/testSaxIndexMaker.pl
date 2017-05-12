#!/usr/bin/env perl
use strict;

use Carp;

BEGIN{
  use File::Basename;
  
  push @INC, (dirname $0).'/../../../lib';
}

END{
}

use InSilicoSpectro::Utils::XML::SaxIndexMaker;
eval{

  my $sim=InSilicoSpectro::Utils::XML::SaxIndexMaker->new();
  $sim->readXmlIndexMaker($ARGV[0]);
  $sim->makeIndex($ARGV[1]);

  $sim->printIndex();
};
if ($@){
  print STDERR "error trapped in main\n";
  carp $@;
}
