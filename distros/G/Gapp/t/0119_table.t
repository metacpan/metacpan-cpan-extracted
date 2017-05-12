#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More qw( no_plan );

use Gtk2 '-init';

{
    use_ok 'Gapp::TableMap';

    my $map = Gapp::TableMap->new(
        string => '
            +--------------+>>>>>>>>>>>>+
            | 1            | 2          |
            +--------------+            |
            | 3            |            |
            +-------+------+------------+     
            > 4     | 5    | 6          |     
            >       |      +------------+     
            >       |      | 7          |     
            +-------+------+------------+     
            > 8     |      | 9          |      
            >       |      +------------+     
            >       |      | 10         |      
            >       +------+------------+      
            >       | 11                |     
            +-------+-------------------+    
        ',
    );
    isa_ok $map, q[Gapp::TableMap];
    is scalar @{$map->cells}, 11, 'created map with 11 cells';
}


{
    use Gapp::Label;
    use_ok 'Gapp::Table';

    my $t = Gapp::Table->new(
        map => '
            +--------------+>>>>>>>>>>>>+
            | 1            | 2          |
            +--------------+            |
            | 3            |            |
            +-------+------+------------+     
            > 4     | 5    | 6          |     
            >       |      +------------+     
            >       |      | 7          |     
            +-------+------+------------+     
            > 8     |      | 9          |      
            >       |      +------------+     
            >       |      | 10         |      
            >       +------+------------+      
            >       | 11                |     
            +-------+-------------------+    
        ',
        content => [
            Gapp::Label->new( text => 1 ),
            Gapp::Label->new( text => 2 ),
            Gapp::Label->new( text => 3 ),
            Gapp::Label->new( text => 4 ),
            Gapp::Label->new( text => 5 ),
            Gapp::Label->new( text => 6 ),
            Gapp::Label->new( text => 7 ),
            Gapp::Label->new( text => 8 ),
            Gapp::Label->new( text => 9 ),
            Gapp::Label->new( text => 10 ),
            Gapp::Label->new( text => 11 ),
        ]
    );

    isa_ok $t, q[Gapp::Table];
}
