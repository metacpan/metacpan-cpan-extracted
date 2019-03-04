#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";

use Test::More tests=>2;
use_ok("Mash");

my $mash = which("mash");
ok($mash, "Found Mash executable");
diag "Path for Mash: $mash";

sub which{
  my($exec)=@_;

  return undef unless $exec;

  my @path = File::Spec->path;
  for my $p(@path){
    if( -e "$p/$exec" && -x "$p/$exec"){
      return "$p/$exec";
    }
  }
  return undef;
}
