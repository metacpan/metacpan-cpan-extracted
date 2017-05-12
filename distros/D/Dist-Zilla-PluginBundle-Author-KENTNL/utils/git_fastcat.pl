#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

if ( @ARGV != 2 ) {
  warn "git_fastcat.pl commitish path";
  exit 255;
}

use Git::Wrapper;
use Cwd qw(cwd);

my ( $revision, $path ) = @ARGV;

my $git = Git::Wrapper->new(cwd);

my $sha1 = [ $git->rev_parse($revision) ]->[0];

#*STDERR->print("\e[31m SHA1: $sha1 \e[0m\n");

my $ls_r = [ $git->ls_tree( $sha1, $path ) ]->[0];

#*STDERR->print("\e[31m ls_r: $ls_r \e[0m\n");

my ( $left, $right ) = $ls_r =~ /^([^\t]+)\t(.*$)/;

#*STDERR->print("\e[31m left: $left \e[0m\n");

my ( $flags, $type, $sha ) = split / /, $left;

#*STDERR->print("\e[31m sha: $sha \e[0m\n");

for my $line ( $git->cat_file( '-p', $sha ) ) {
  print "$line\n";
}

