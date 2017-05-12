use strict;
use lib './lib';
use DBI;
use Cwd;



sub _get_new_handle {
   my $abs = shift;
   $abs ||= './t/premade_data.db';

   my $dbh = DBI->connect("dbi:SQLite:dbname=$abs","","");
   $dbh or die('cant open db connection, still open?');
   print STDERR "\n\n ++ OPENED SQLITE $abs\n\n";
   return $dbh;


}




1;
