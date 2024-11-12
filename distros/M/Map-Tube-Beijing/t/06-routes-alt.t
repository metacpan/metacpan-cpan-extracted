#!perl

use strict;
use Test::More tests => 11;
use Map::Tube::Beijing;

my $map = new_ok( 'Map::Tube::Beijing' => [ 'nametype' => 'alt' ] );

eval { $map->get_shortest_route( ); };
like( $@, qr/ERROR: Missing Station Name\./, 'No stations for get_shortest_route( )' );

eval { $map->get_shortest_route('Yonghegong Lama Temple'); };
like( $@, qr/ERROR: Missing Station Name\./, 'Just one station for get_shortest_route( )'  );

eval { $map->get_shortest_route( 'XYZ', 'Yonghegong Lama Temple' ); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Must specify two existing stations for get_shortest_route( )' );

eval { $map->get_shortest_route('Yonghegong Lama Temple', 'XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Must specify two existing stations for get_shortest_route( )' );

{
    my $ret = $map->get_shortest_route('Yonghegong Lama Temple', 'Beijing Zoo');
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Yonghegong Lama Temple (Line 2, Line 5), Andingmen (Line 2), Guloudajie (Line 2, Line 8), Jishuitan (Line 2), ' .
        'Xizhimen (Daxing Line, Line 13, Line 2, Line 4), Beijing Zoo (Daxing Line, Line 4)',
        'Yonghegong Lama Temple - Beijing Zoo'
      );
}

{
    my $ret = $map->get_shortest_route('Yonghegong Lama Temple', 'Beijing Zoo')->preferred( );
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Yonghegong Lama Temple (Line 2), Andingmen (Line 2), Guloudajie (Line 2), Jishuitan (Line 2), ' .
        'Xizhimen (Daxing Line, Line 2, Line 4), Beijing Zoo (Daxing Line, Line 4)',
        'Yonghegong Lama Temple - Beijing Zoo preferred route'
      );
}

{
    my $ret = $map->get_shortest_route('yonghegong lama temple', 'JINTAIXIZHAO');
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Yonghegong Lama Temple (Line 2, Line 5), Dongzhimen (Airport Express, Line 13, Line 2), '.
        'Dongsi Shitiao (Line 2), Chaoyangmen (Line 2, Line 6), Dongdaqiao (Line 6), ' .
        'Hujialou (Line 10, Line 6), Jintaixizhao (Line 10)',
        'yonghegong lama temple - JINTAIXIZAHO case-insensitive'
      );
}

