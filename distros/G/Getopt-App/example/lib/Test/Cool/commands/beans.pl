#!/usr/bin/env perl
package Test::Cool::beans;
use Getopt::App;
run(sub {
  shift;
  print join('|', grep { !ref } $Getopt::App::DEPTH, @{$Getopt::App::SUBCOMMAND}, __FILE__, @_), "\n";
  return 11;
});
