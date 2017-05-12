#!/usr/bin/perl

use strict;
use warnings;

use Gentoo::Overlay;

my $overlay = Gentoo::Overlay->new( path => '/usr/portage' );

my %categories = $overlay->categories;

for my $category ( sort keys %categories ) {
  print $categories{$category}->pretty_name, "\n";

  my %packages = $categories{$category}->packages;

  for my $package ( sort keys %packages ) {
    print "   " . $packages{$package}->pretty_name . "\n";
  }
}
