#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Path::FindDev qw( find_dev );

my $hashref = {};

my $template = find_dev('./')->child('.travis-template.yml');
my $target   = find_dev('./')->child('.travis.yml');

if ( -f -e $template ) {
  require YAML::Loader;
  my $loader = YAML::Loader->new();
  $hashref = $loader->load( $template->slurp );
}

if ( not exists $hashref->{language} ) {
  $hashref->{language} = 'perl';
}
if ( not exists $hashref->{perl} ) {
  $hashref->{perl} = [ '5.18', '5.19' ];
}

use Data::Dump qw(pp);
pp($hashref);
require YAML::Dumper;
my $dumper = YAML::Dumper->new();
$target->spew( $dumper->dump($hashref) );
