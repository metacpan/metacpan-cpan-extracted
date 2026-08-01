#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use Test::Lib;
use Test::More;
use Sample;

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

my $dataname = File::Spec->catfile( @localdir, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );

my @drivers = grep { $_ !~ /^nop/ } $tube->list_drivers( );

for my $driver(@drivers) {
  my ($diagram, undef) = $tube->render( driver => $driver );
  isnt( $diagram, '', "$driver driver" );
}

done_testing;
