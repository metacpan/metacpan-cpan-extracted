use Test::Simple 'no_plan';
use strict;
use lib './lib';
use LEOCHARRE::DEBUG;

ok( ! DEBUG );

$DEBUG = 1;

ok(  DEBUG );

debug("This should print.\n");

debug("This should NOT print.\n",2);


$DEBUG = 4; 

ok( DEBUG == 4,'set debug level to 4');

debug("should print\n");
debug("should print\n",2);
debug("should print\n",4);
debug('should NOT print',6);
debug('should print','leo');



$DEBUG = 'leo'; 

ok( DEBUG eq 'leo','set debug tag to "leo"');

debug("a)should NOT print\n");
debug("b)should NOT print\n",6);
debug("c)should NOT print\n",'ralph');

debug('should print','leo');

print STDERR "\n$DEBUG\n";
print STDERR"\n============\n\n\n";


$DEBUG = 2;

debug("Should be fully loaded");
debug("another line. With dot.", 'Second line here.');


$DEBUG = 3;
$LEOCHARRE::DEBUG::USE_COLOR = 1;
debug("Should be fully color");
debug("another line. With dot.", 'Second line here.');
