#!/usr/bin/env perl

use strict;
use warnings;

use lib '../../lib';

use Test::More qw{no_plan};

BEGIN { use_ok( 'Gwybodaeth::Parsers::N3' ); }

my $n3 = new_ok('Gwybodaeth::Parsers::N3');

my @data;
my $struct;

# Simple map test
@data = ( '[] a foaf:Person ;',
          'foaf:mbox "Ex:$3" ;' );

$struct = [ { 'foaf:Person' => {
                             obj => ['"Ex:$3"'],
                             predicate => ['foaf:mbox'],
                            }
            }, {} ];

is_deeply($n3->parse(@data), $struct, 'simple map');

# Inline triple test
$n3 = undef;
$n3 = new_ok('Gwybodaeth::Parsers::N3');

@data = ( '[] a foaf:Person ;',
          'foaf:office',
          '     [ a foaf:Place ;',
          '         foaf:addy "Ex:$4"',
          '     ] .' );

$struct = [ { 'foaf:Person' => {
                            obj => [
                                { 'foaf:Place' => {
                                       obj => ['"Ex:$4"'],
                                       predicate => ['foaf:addy'],
                                       }
                                } ],
                            predicate => ['foaf:office'],
                            }
            }, {} ];         

is_deeply($n3->parse(@data), $struct, 'inline triple');

# function recording test
$n3 = undef;
$n3 = new_ok('Gwybodaeth::Parsers::N3');

@data = ( '<Ex:$4>',
          '  a foaf:Person ;',
          '  foaf:name "Ex:$4" .' );

$struct = [ {}, {
                '<Ex:$4>' => { 'foaf:Person' => {
                                obj => ['"Ex:$4"'],
                                predicate => ['foaf:name']
                               } 
                             } 
                } ];
is_deeply($n3->parse(@data), $struct, 'function record');
