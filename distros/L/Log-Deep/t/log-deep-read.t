#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Data::Dumper qw/Dumper/;

use Log::Deep::Read;

my $deep = Log::Deep::Read->new();
isa_ok( $deep, 'Log::Deep::Read', 'Can create a log object');

# set session colours
is( $deep->session_colour(1), $deep->session_colour(1), 'Two calls to session colour return the same value');
my %colour;
for ( 1..40 ) {
    $colour{$_} = $deep->session_colour($_);
}
is( ( scalar keys %colour ), 40, "40 sessions == 40 colours" );
done_testing();
