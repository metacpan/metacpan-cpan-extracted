#!perl

use strict;
use Test::More tests => 21;
use Map::Tube::Beijing;

my $map = new_ok( 'Map::Tube::Beijing' => [ 'nametype' => 'alt' ] );

eval { $map->get_shortest_route(); };
like($@, qr/ERROR: Either FROM\/TO node is undefined/);

eval { $map->get_shortest_route('Yonghegong Lama Temple'); };
like($@, qr/ERROR: Either FROM\/TO node is undefined/);

eval { $map->get_shortest_route('XYZ', 'Yonghegong Lama Temple'); };
like($@, qr/\QMap::Tube::get_shortest_route(): ERROR: Received invalid FROM node 'XYZ'\E/);

eval { $map->get_shortest_route('Yonghegong Lama Temple', 'XYZ'); };
like($@, qr/\QMap::Tube::get_shortest_route(): ERROR: Received invalid TO node 'XYZ'\E/);

{
    my $ret = $map->get_shortest_route('Yonghegong Lama Temple', 'Dongzhimen');
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Yonghegong Lama Temple (Line 2, Line 5), Dongzhimen (Airport Express, Line 13, Line 2)',
        'Yonghegong Lama Temple - Dongzhimen'
      );
}

{
    my $ret = $map->get_shortest_route('Yonghegong Lama Temple', 'Dongsi Shitiao');
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Yonghegong Lama Temple (Line 2, Line 5), Dongzhimen (Airport Express, Line 13, Line 2), ' .
        'Dongsi Shitiao (Line 2)',
        'Yonghegong Lama Temple - Dongsi Shitiao'
      );
}

{
    my $ret = $map->get_shortest_route('Yonghegong Lama Temple', 'Chaoyangmen');
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Yonghegong Lama Temple (Line 2, Line 5), Dongzhimen (Airport Express, Line 13, Line 2), ' .
        'Dongsi Shitiao (Line 2), Chaoyangmen (Line 2, Line 6)',
        'Yonghegong Lama Temple - Chaoyangmen'
      );
}

{
    my $ret = $map->get_shortest_route('Chaoyangmen', 'Jianguomen');
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Chaoyangmen (Line 2, Line 6), Jianguomen (Line 1, Line 2)',
        'Chaoyangmen - Jianguomen'
      );
}

{
    my $ret = $map->get_shortest_route('Dongsi Shitiao', 'Jianguomen');
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Dongsi Shitiao (Line 2), Chaoyangmen (Line 2, Line 6), Jianguomen (Line 1, Line 2)',
        'Dongsi Shitiao - Jianguomen'
      );
}

{
    my $ret = $map->get_shortest_route('Dongzhimen', 'Jianguomen');
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Dongzhimen (Airport Express, Line 13, Line 2), ' .
        'Dongsi Shitiao (Line 2), Chaoyangmen (Line 2, Line 6), Jianguomen (Line 1, Line 2)',
        'Dongzhimen - Jianguomen'
      );
}

{
    my $ret = $map->get_shortest_route('Yonghegong Lama Temple', 'Jianguomen');
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Yonghegong Lama Temple (Line 2, Line 5), Dongzhimen (Airport Express, Line 13, Line 2), ' .
        'Dongsi Shitiao (Line 2), Chaoyangmen (Line 2, Line 6), Jianguomen (Line 1, Line 2)',
        'Yonghegong Lama Temple - Jianguomen'
      );
}

{
    my $ret = $map->get_shortest_route('Yonghegong Lama Temple', 'JINTAIXIZHAO');
    isa_ok( $ret, 'Map::Tube::Route' );
    is( $ret,
        'Yonghegong Lama Temple (Line 2, Line 5), Dongzhimen (Airport Express, Line 13, Line 2), '.
        'Dongsi Shitiao (Line 2), Chaoyangmen (Line 2, Line 6), Dongdaqiao (Line 6), ' .
        'Hujialou (Line 10, Line 6), Jintaixizhao (Line 10)',
        'Yonghegong Lama Temple - JINTAIXIZAHO case-insensitive'
      );
}

