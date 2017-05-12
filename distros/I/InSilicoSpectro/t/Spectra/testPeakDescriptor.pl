#!/usr/bin/env perl
use strict;
use Carp;

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}
END{
}

use InSilicoSpectro::Spectra::PhenyxPeakDescriptor;

$InSilicoSpectro::Utils::io::VERBOSE=1;

my $file=(dirname $0).'/a.xml';

my $t=XML::Twig->new->parsefile($file);
my @el=$t->get_xpath("ple:ItemOrder");
my @pd;
foreach(@el){
  my $pd=InSilicoSpectro::Spectra::PhenyxPeakDescriptor->new();
  $pd->readTwigEl($_);
  $pd->writeXml();
  push @pd, $pd;
}
print "comparing to first node\n";
foreach(1..$#pd){
  print "$_ -> ".(($pd[$_]->equalsTo($pd[0]))?"OK":"!=")."\n";
}

