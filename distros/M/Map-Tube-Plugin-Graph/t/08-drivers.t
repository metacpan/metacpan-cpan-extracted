#!/usr/bin/perl
use 5.014;
use strict;
use warnings;
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
  diag(" $driver");
  my $diagram;
  eval { ($diagram, undef) = $tube->render( driver => $driver ); };
  if ( $@ ne '' ) {
    diag( "It seems the GraphViz binary (dot) does not fully support\n" .
          "non-overlapping node placement for driver $driver.\n" .
          "Use 'overlap => 1' in your own applications if necessary."
        );
    eval { ($diagram, undef) = $tube->render( driver => $driver, overlap => 1 ); };
    if ( $@ ne '' ) {
      diag( "Strangely, it seems the GraphViz binary (dot) does not fully support\n" .
            "overlapping node placement for driver $driver, either.\n" .
            "I'm stymied."
          );
    }
  }
  isnt( $diagram, '', "$driver driver" );
}

done_testing;
