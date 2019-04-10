#!perl

use constant test_count => 3;

use strict;
use warnings;
use Test::More tests => test_count;

sub GetPoints();

use_ok( 'Geo::Index' );

my $index = Geo::Index->new( { levels=>20, quiet=>1 } );
isa_ok $index, 'Geo::Index', 'Geo::Index object';

my %config = $index->GetConfiguration();

is( $config{c_code_version}, $config{module_version}, "Perl and C version numbers" );

done_testing;
