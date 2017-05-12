#!/usr/bin/perl 
# take a latex file and show the authors and laboratories

use LaTeX::Authors;
use strict;

  my $file = shift;

  if ($file eq "")
  { 
   print "Latex file name?\n";
   exit;
  }
  my $tex_string = load_file_string($file);
  my @article = router($tex_string);
  my $string_xml =  string_byauthors_xml(@article);
  print $string_xml;

