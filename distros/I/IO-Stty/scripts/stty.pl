#!/usr/local/perl/bin/perl

require IO::Stty;

foreach $param (@ARGV) {
  push (@params,split(/\s/,$param));
}
$stty = IO::Stty::stty(\*STDIN,@params);
if ($stty ne '0 but true') {
  print $stty;
}
