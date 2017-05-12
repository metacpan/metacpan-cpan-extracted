use Test::Simple 'no_plan';
use lib './lib';
use base 'Dyer::CLI';

ok( _scriptname(),'scriptname returns');

#ok( yn('please enter y to confirm this works..'),'yn works');

