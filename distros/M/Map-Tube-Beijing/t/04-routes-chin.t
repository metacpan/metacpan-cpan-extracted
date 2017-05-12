#!perl

use strict;
use utf8;
use Test::More tests => 9;
use Map::Tube::Beijing;

my $map = new_ok( 'Map::Tube::Beijing' );

eval { $map->get_shortest_route(); };
like($@, qr/ERROR: Either FROM\/TO node is undefined/);

eval { $map->get_shortest_route('éåå®«'); };
like($@, qr/ERROR: Either FROM\/TO node is undefined/);

eval { $map->get_shortest_route('XYZ', 'éåå®«'); };
like($@, qr/\QMap::Tube::get_shortest_route(): ERROR: Received invalid FROM node 'XYZ'\E/);

eval { $map->get_shortest_route('éåå®«', 'XYZ'); };
like($@, qr/\QMap::Tube::get_shortest_route(): ERROR: Received invalid TO node 'XYZ'\E/);

{
    my $ret = $map->get_shortest_route('éåå®«', 'å»ºå½é¨');
    isa_ok( $ret, 'Map::Tube::Route' );
    # my $str = $ret; utf8::encode($str);       print STDERR "encode   :$str\n";
    is( $ret,
        'éåå®« (äºå·çº¿, äºå·çº¿), ä¸ç´é¨ (äºå·çº¿, åä¸å·çº¿, æºåºå¿«è½¨), ä¸ååæ¡ (äºå·çº¿), æé³é¨ (äºå·çº¿, å ­å·çº¿), å»ºå½é¨ (ä¸å·çº¿, äºå·çº¿)',
        'éåå®« - å»ºå½é¨'
      );
}

{
    my $ret = $map->get_shortest_route('éåå®«', 'éå°å¤ç §');
    isa_ok( $ret, 'Map::Tube::Route' );
    # my $str = $ret; utf8::encode($str);       print STDERR "encode   :$str\n";
    is( $ret,
        'éåå®« (äºå·çº¿, äºå·çº¿), ä¸ç´é¨ (äºå·çº¿, åä¸å·çº¿, æºåºå¿«è½¨), ä¸ååæ¡ (äºå·çº¿), ' . 
        'æé³é¨ (äºå·çº¿, å ­å·çº¿), ä¸å¤§æ¡¥ (å ­å·çº¿), å¼å®¶æ¥¼ (å ­å·çº¿, åå·çº¿), éå°å¤ç § (åå·çº¿)',
        'éåå®« - éå°å¤ç §'
      );
}

