#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use Test::More qw(no_plan);
use Test::Exception;

BEGIN { use_ok( 'Gwybodaeth::Triples' ); }

my $triple = new_ok( 'Gwybodaeth::Triples' );

# Check it stores the data structure correctly
my $triple_struct = { Subject => { obj => ['Object'], 
                                   predicate => ['Predicate']}
                    }; 

is_deeply( $triple->store_triple('Subject', 'Predicate', 'Object'),
           $triple_struct, 'stores triple struct');

#
# Check garbage as input
#

# Undefined inputs
dies_ok { $triple->store_triple(undef, undef, undef) } 'undefined subject';
dies_ok { $triple->store_triple('Subject', undef, undef) } 
        'undefined predicate';
dies_ok { $triple->store_triple('Subject', 'Predicate', undef) }
        'undefined object';
