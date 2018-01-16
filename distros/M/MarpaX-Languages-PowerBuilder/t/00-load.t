#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 9;

use_ok( 'MarpaX::Languages::PowerBuilder' )       || print "Bail out!\n";
for my $package(qw(base SRD SRJ SRQ PBR PBT PBW PBG)){
    use_ok( 'MarpaX::Languages::PowerBuilder::'.$package ) || print "Bail out!\n";
}

diag( "Testing MarpaX::Languages::PowerBuilder $MarpaX::Languages::PowerBuilder::VERSION, Perl $], $^X" );
