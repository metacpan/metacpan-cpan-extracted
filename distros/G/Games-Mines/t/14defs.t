#! perl

use Test::More tests=>18;
use strict;

use Games::Mines::Play;

my(%op);
my(@results);

##################

%op = (small =>1, foo=>'whatever', bar=>'yahoo');
@results = Games::Mines::Play->default(%op);
is($results[0],8);
is($results[1],8);
is($results[2],10);

%op = (medium =>1, foo=>'whatever', bar=>'yahoo');
@results = Games::Mines::Play->default(%op);
is($results[0],16);
is($results[1],16);
is($results[2],40);

%op = (large =>1, foo=>'whatever', bar=>'yahoo');
@results = Games::Mines::Play->default(%op);
is($results[0],16);
is($results[1],30);
is($results[2],99);

%op = (small =>1, foo=>'whatever', height=> 34, bar=>'yahoo');
@results = Games::Mines::Play->default(%op);
is($results[0],34);
is($results[1],8);
is($results[2],10);

%op = (medium =>1, foo=>'whatever', width=>55,bar=>'yahoo');
@results = Games::Mines::Play->default(%op);
is($results[0],16);
is($results[1],55);
is($results[2],40);

%op = (large =>1, foo=>'whatever', mines=>234,bar=>'yahoo');
@results = Games::Mines::Play->default(%op);
is($results[0],16);
is($results[1],30);
is($results[2],234);


