use Test::Simple 'no_plan';
use Cwd;
use strict;
use lib './lib';
use LEOCHARRE::DBI;

END { _cleanup() }

sub abs_tmps_make {
   my @abs = abs_tmps();
   for my $abs (@abs){
      print STDERR " - $abs\n";
      open(FL,'>',$abs) or die;
      print FL 'content here';
      close FL;   
   }
   return @abs;
}


sub abs_tmps {
   my @abs = map ( cwd()."/t/tmp_$_.txt", qw(a b c d e f g h)); 
   return @abs;
}

sub _cleanup {

   unlink _abs_db();
   
   for(abs_tmps()){
      unlink $_;
   }
   
   require File::Path;
   File::Path::rmtree(cwd().'/t/archive');
   
}

sub _get_new_handle {  
   my $abs_db = shift;
   $abs_db ||= _abs_db();
   
   my $dbh = DBI::connect_sqlite($abs_db)
      or die('opened dbh with connect_sqlite()');
   print STDERR " # opened sqlite handle\n";
   return $dbh;
}

sub _abs_db {
   return cwd().'/t/test.db';
}

sub _reset_db {

   unlink _abs_db();
  
   return 1;  

}

sub _get_new_handle_mysql {  
   
   
   my $dbh = DBI::connect_mysql('mdf_database','mdf_user','mdf_password')
      or die("could not open db\n # check that you do have a dmsdb_testing
database 
or 
 mysql> create database mdf_database;
 mysql> grant all on mdf_database.* to 'mdf_user'\@'localhost' identified by 'mdf_password';
");
   print STDERR " # got mysql dbh handle..\n";
   return $dbh;
}


1;
