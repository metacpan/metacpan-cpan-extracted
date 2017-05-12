#!/usr/bin/env perl

use strict;
use Carp;

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

END{
}

use InSilicoSpectro::Utils::Files;

my $iTest=shift @ARGV;

use File::Temp qw(tempfile);
eval{
  if($iTest==0){
    my $dir=$ARGV[0] or die "must provide a directory name to delete";
    InSilicoSpectro::Utils::Files::rmdirRecursive($dir, 100);
  }else{
    die "nothing to do for itest=$iTest";
  }
};
if ($@){
  print STDERR "error trapped in main\n";
  carp $@;
}
