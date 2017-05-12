use strict;
use warnings;
use Test::More;
use Hypatia;

eval{ Hypatia->new({graph_type=>"Line",dbi=>{connect=>0,table=>"blah"}}) };
ok($@,"KABOOM! back_end not specified.");

eval{Hypatia->new({back_end=>"asfdasdf",graph_type=>"Area",dbi=>{connect=>0,table=>"blah"}}) };
ok($@,"KABOOM! nonsensical back_end");

eval{Hypatia->new({graph_type=>"asfdasdf",back_end=>"Chart::Clicker",dbi=>{connect=>0,table=>"blah"}}) };
ok($@,"KABOOM! nonsensical graph_type");

eval{Hypatia->new({graph_type=>"Line",back_end=>"Chart::Clicker",dbi=>{table=>"blah"}}) };
ok($@,"KABOOM! could not establish a database connection.");

eval{ Hypatia->new({back_end=>"Chart::Clicker",graph_type=>"Line",dbi=>{connect=>0,table=>"blah"}})->_guess_columns };
ok($@,"KABOOM! column guessing causes an explosion unless overridden.");

done_testing();