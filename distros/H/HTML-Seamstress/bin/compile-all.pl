#!/usr/bin/perl
use strict;

use File::Find;

my $html_regexp = qr/[.]html?$/ ;

find(\&wanted, '.');

sub wanted {

  warn "checking $_ against $html_regexp";
  /$html_regexp/ and compile();

}

sub compile {

  warn "compiling $_";
  my $syscmd = "seamc -debug $_";
  print `$syscmd`;

}
