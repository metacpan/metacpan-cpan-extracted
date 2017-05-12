#!/usr/bin/env perl
use strict;
use Dynamic::Loader;

unless (@ARGV){
  my @tmp=Dynamic::Loader::listScripts("*");
  print join("\n",@tmp)."\n";
  exit(0);
}

my $script=Dynamic::Loader::getScript(shift @ARGV);
my @tmp=(Dynamic::Loader::getExecPrefix(), $script, @ARGV);

warn "executing @tmp";
exec(@tmp);
