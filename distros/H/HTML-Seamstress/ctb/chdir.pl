#!/usr/bin/perl

use Cwd;



{
  warn cwd;
  die if cwd eq '/';
  die if (-e 'seamc.cfg') ;
  chdir '..';
  redo;
}
