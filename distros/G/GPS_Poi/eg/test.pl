#!/usr/bin/perl -w
use GPS::Poi;
my $file =shift;
my $poi = GPS::Poi->new();
my $nb = $poi->parse({file => $file });
my  @list = $poi->all_as_list();
my  $dump = $poi->dump_list();
print $dump;


