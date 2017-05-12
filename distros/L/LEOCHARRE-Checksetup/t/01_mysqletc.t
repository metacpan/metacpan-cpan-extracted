use Test::Simple 'no_plan';
use lib './lib';
use strict;
use LEOCHARRE::Checksetup ':all';


   `whoami`=~/root/ or ok(1,"is not rot, skipping") and exit;
   
ok_root();

   

my $daemon = '/etc/init.d/mysqld';

-e $daemon or say("Missing daemon $daemon, skipping.") and exit;


ok_mysql_local_server();



