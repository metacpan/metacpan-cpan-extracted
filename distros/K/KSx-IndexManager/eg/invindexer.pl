#!/usr/bin/perl
# see USConManager for comments
use strict;
use warnings;

my ($lib_path, $source_dir, $path_to_invindex, $base_url);

BEGIN {
  $lib_path         = 'eg';
  $source_dir       = 'eg/us_constitution';
  $path_to_invindex = 'uscon_invindex';
}

use lib $lib_path;

use USConManager;
use File::Spec;

# in the future, I would like this to be abstracted into the manager as well
opendir my $fh, $source_dir or die "Can't opendir $source_dir: $!";
my @filenames;
for my $filename (readdir $fh) {
  next unless $filename =~ /\.html/;
  next if $filename eq 'index.html';
  push @filenames, File::Spec->catfile($source_dir, $filename);
}
closedir $fh or die "Couldn't closedir $source_dir: $!";

my $manager = USConManager->new({
  root => $path_to_invindex,
});

$manager->write(\@filenames);
