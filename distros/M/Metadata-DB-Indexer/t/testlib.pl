use strict;
use lib './lib';
use DBI;
use Cwd;

sub _get_new_handle {
   my $abs = shift;
   $abs ||= _abs_db();

   my $dbh = DBI->connect("dbi:SQLite:dbname=$abs","","");
   $dbh or die('cant open db connection, still open?');
   print STDERR "\n\n ++ OPENED SQLITE $abs\n\n";
   return $dbh;


}

sub _abs_db {
   cwd().'/t/indexing_test.db';

}

















1;
