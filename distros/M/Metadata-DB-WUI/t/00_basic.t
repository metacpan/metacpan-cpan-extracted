use Test::Simple 'no_plan';
use strict;
use lib  './lib';
use LEOCHARRE::Database;

my $absdb = './t/test.db';
-f $absdb or die("$absdb not on disk");

my $dbh = DBI::connect_sqlite($absdb);
ok($dbh,"got db connect $absdb") or die;








# ------------------------------

require Metadata::DB::Search::InterfaceHTML;
my $g = Metadata::DB::Search::InterfaceHTML->new({ DBH => $dbh });
ok( $g, "instanced interface");

require Metadata::DB::WUI;
my $wui = Metadata::DB::WUI->new( PARAMS => { DBH => $dbh });
ok($wui, 'instanced wui');



