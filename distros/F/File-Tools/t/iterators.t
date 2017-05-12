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
  # cat "file1", "file2" > "newfile"
  # 
}
  

