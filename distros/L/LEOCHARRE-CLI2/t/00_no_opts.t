use Test::Simple 'no_plan';
use strict;
use lib './lib';
use LEOCHARRE::CLI2;


ok( ! main->can('OPT') );



ok( main->can('debug')  );




debug("this may be seen");


#BEGIN { $opt_h and print usage() and exit }
