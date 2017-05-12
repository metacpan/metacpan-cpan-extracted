#!/usr/bin/perl

use strict;
use warnings;

use Games::Backgammon;

use Test::More tests => 8;
use Data::Dumper;
local $Data::Dumper::Indent = undef;

use constant POSITIONS => (
    #[{whitepoints}, {blackpoints}, {atroll}, {positionid}]
    [{6 => 5, 8 => 3, 13 => 5, 24 => 2},
     {6 => 5, 8 => 3, 13 => 5, 24 => 2},
     'white',
     "4HPwATDgc/ABMA"
    ],
    
    [{6 => 5, 8 => 4, 13 => 4, 22 => 1, 24 => 1},
     {6 => 5, 8 => 3, 13 => 5, 24 => 2},
     'black',
     '4PPgASTgc/ABMA'
    ],
    
    [{5 => 1, 6 => 4,  8 => 4, 13 => 4, 20 => 1, 22 => 1},
     {6 => 5, 8 => 3, 10 => 1, 13 => 4, 24 => 1, bar => 1},
     'black',
     '0PPgAQngc+IBUA'
    ],
    
    [{6 => 4, 8 => 4, 13 => 4, 20 => 1, 22 => 1, bar => 1},
     {6 => 5, 8 => 4, 13 => 4, 20 => 1, 23 => 1},
     'white',
     '4PPgARHgefCARA'
    ],
    
    [{4 => 2, 6 => 3, 7 => 3, 8 => 3, 18 => 2, bar => 2},
     {2 => 2, 4 => 2, 5 => 1, 6 => 2, 8 => 1, 13 => 2, 15 => 1, 20 => 3, 22 => 1},
     'white',
     'Zk0wwQmYuwMwYA'
    ],
    
    [{1 => 3, 2 => 1, 3 => 1, 4 => 3},
     {7 => 1, 6 => 2, 4 => 3, 3 => 2, 2 => 2, 1 => 5},
     'black',
     'VwcAAL7tLAAAAA'
    ],
    
    [{1 => 3, 2 => 1, 3 => 1, 4 => 3},
     {6 => 2, 4 => 2, 3 => 2, 2 => 3, 1 => 5},
     'white',
     '320GAICrAwAAAA'
    ],
    
    [{1 => 2},
     {1 => 5},
     'white',
     'HwAAwAAAAAAAAA'
    ]
);

my $game = Games::Backgammon->new(position => {whitepoints => {},
                                               blackpoints => {},
                                               atroll      => 'white'});

foreach (POSITIONS) {
    my ($white, $black, $atroll, $id) = @$_;
    my %pos = (
        whitepoints => $white, 
        blackpoints => $black, 
        atroll => $atroll
    );
    $game->set_position(%pos);
    is $game->position_id, $id, "Same position id"
    or diag "Position: " . Dumper(\%pos);
}
