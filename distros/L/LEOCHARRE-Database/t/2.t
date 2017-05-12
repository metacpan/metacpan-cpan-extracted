use Test::Simple 'no_plan';
use warnings;
use strict;
use lib './lib';

use LEOCHARRE::DBI;
use Cwd;

my $abs_db = cwd().'/t/test.db';
unlink $abs_db if -f $abs_db;

ok( !-f $abs_db,' abs db is not there and will recreate');



my $dbh = DBI::connect_sqlite($abs_db);

ok($dbh,'connect_sqlite() handle returned') or die('cannot get a dbh handle');


 
