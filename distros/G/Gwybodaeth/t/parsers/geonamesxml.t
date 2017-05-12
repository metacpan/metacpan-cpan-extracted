#!/usr/bin/env perl

use strict;
use warnings;

use lib '../../lib';

use XML::Twig;
use Test::More qw{no_plan};

my $twig = XML::Twig->new();

BEGIN{ use_ok( 'Gwybodaeth::Parsers::GeoNamesXML' ); }

my $gnx = new_ok( 'Gwybodaeth::Parsers::GeoNamesXML' );

my $xml = [ '<root>',
            '<child1>foo</child1>',
            '<child2>bar</child2>',
            '</root>'
          ];

$twig = $gnx->parse(@{ $xml });

ok( $twig->isa('XML::Twig'), 'returns twig' );

# Garbage input test
my $cruft = [ 'this is some', '<a href="cruft">', 'to trip',
              'up the', 'PaRsEr!!' ];

$twig = $gnx->parse(@{ $cruft });

is( $twig, 0, 'returns 0 on cruft' );

# More garbage testing with some CSV

my $csv = [ [ 'NAME', 'YEAR', 'COUNTRY'],
            [ 'Plato', '400 BC', 'Greece'],
            [ 'Nietzsche', '1889 AD', 'Switzerland' ],
          ];

$twig = $gnx->parse( @{ $csv } );

is( $twig, 0, 'returns 0 on CSV');
