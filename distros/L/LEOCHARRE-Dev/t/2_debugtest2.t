use Test::Simple 'no_plan';
use strict;
use lib './t';
use Test2;

my $o = new Test2;

$Test2::DEBUG = 1;

ok( $o->debug_is_on ,'debug is on');


$o->DEBUG(0);

ok( !($o->debug_is_on) ,'debug is off');

print STDERR "    [Test2::DEBUG $Test2::DEBUG]\n";

Test2::DEBUG(1);
ok( $o->debug_is_on ,'debug is on via class');




$o->_show_symbol_table;




