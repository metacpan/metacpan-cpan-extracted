#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

use lib File::Spec->catdir( dirname( __FILE__ ), '..', 'lib' );

use EPublisher;

my $yaml = File::Spec->catfile( dirname( __FILE__ ), 'testMobi.yml' );
my $publisher = EPublisher->new(
    config => $yaml,
    debug  => sub {
        print "@_\n";
    },
);

$publisher->run( [ 'Test' ] );
