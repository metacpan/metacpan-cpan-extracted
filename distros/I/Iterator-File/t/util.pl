#!/usr/bin/perl

use strict;
use warnings;

sub slurp {
  my ($file) = @_;
  my (@data);

  open(F, "<", $file) || die("Coudn't open '$file': $!");
  @data = <F>;
  close(F) || warn("Error closing '$file': $!");

  return wantarray ? @data : join("", @data);
}


1;
