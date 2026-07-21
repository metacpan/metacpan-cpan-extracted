#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use Test::Lib;
use Test::More tests => 3;
use Sample;

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

my $dataname = File::Spec->catfile( @localdir, 'unusual-station-name.xml' );
my $tube = Sample->new( xml => $dataname );

eval { $tube->as_image(); };
is( $@, '' );

my ($dot, undef) = $tube->render( format => 'dot' );
like( $dot, qr(Nice station name),     'Nice output to GraphViz' );
like( $dot, qr(S:trange station name), 'Strange output to GraphViz' );

