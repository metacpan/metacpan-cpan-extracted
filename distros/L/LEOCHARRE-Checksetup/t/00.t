use Test::Simple 'no_plan';
use lib './lib';
use strict;
use LEOCHARRE::Checksetup ':all';

ok(1,'started');


   `whoami`=~/root/ or ok(1,"is not rot, skipping") and exit;

ok_root();

ok_os();

`touch ./t/test.conf`;
ok -f './t/test.conf';

ok_conf( './t/test.conf' );


ok_app('ls');

ok_perldeps();

say 'hello';

