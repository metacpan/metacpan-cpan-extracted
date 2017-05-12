use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();

use LEOCHARRE::Debug;

ok( defined $DEBUG );



ok( debug("IF YOU SEE ME I SUCK"));

$DEBUG = 1;


ok( debug("YOU SHOULD SEE ME") );
$DEBUG = 0;
ok debug("YOU SHOULD NOT SEE ME");


$TestD::DEBUG=1;
TestD::testme();













sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}





package TestD;

use LEOCHARRE::Debug;


sub testme {
   debug('AM I HERE FROM./...');
}
1;
