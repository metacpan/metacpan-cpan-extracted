use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();

use LEOCHARRE::Debug;



ok( defined $DEBUG );

warnf( "%20s %s\n", qw/this is/);

warnf( "%20s %s", qw/this was/);
