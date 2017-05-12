use Test::Simple 'no_plan';
use strict;
use lib './lib';
use LEOCHARRE::DEBUG 'use_color';

ok( ! DEBUG );

DEBUG 1;

ok(DEBUG);

my $havecolor =  eval "require Term::ANSIColor;";

if (!$havecolor){
   ok(1,'we do not have Term::ANSIColor installed, skipping.');
   exit;
}


debug("This should print dark.\n");
print STDERR 'this should be normal';


debug("this should also be dark");


