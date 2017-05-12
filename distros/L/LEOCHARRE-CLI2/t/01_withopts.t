use Test::Simple 'no_plan';
use strict;
use lib './lib';

use LEOCHARRE::CLI2 qw/hab/;




ok( ! main->can('OPT') );

$opt_a ||= 1;
ok($opt_a);

ok $OPT{a};

my $ost= $OPT_STRING;
ok $ost, "have opt string '$ost'";


ok( main->can('debug')  );


$opt_d = 1;

debug('hi there, this can be seen if -d flag is on');

