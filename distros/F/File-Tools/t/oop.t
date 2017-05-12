#!/usr/bin/perl -w
use strict;

use Test::More skip_all => 'Not implemented yet.';
use Test::NoWarnings;

use File::Tools;


{
  my $shell = File::Tools->new;
  $shell->copy("old", "new");
}


{
  my $shell = File::Tools->new;
  $shell->things([qw(.)]);  # things are directories, files
  $shell->recoursive(1);
  $shell->chown("username", "groupname");
}


{
  my $shell = File::Tools->new(file => "filename");
  grep /regex/, $shell->cat;
}




