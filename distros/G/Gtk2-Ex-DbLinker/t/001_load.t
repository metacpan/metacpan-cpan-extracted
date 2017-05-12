# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;
use Log::Log4perl  qw(:easy);
use lib "../lib";
use Gtk2::Ex::DbLinker::DbiDataManager;
use Test::More tests => 4;
use DBI;

BEGIN { use_ok( 'DBI' ); }
BEGIN { use_ok( 'Gtk2::Ex::DbLinker::DbiDataManager' ); }
Log::Log4perl->easy_init($ERROR);



my $dbfile ="./examples/data/ex1";
my $dbh = DBI->connect ("dbi:SQLite:dbname=$dbfile","","", {  
		RaiseError       => 1,
        PrintError       => 1,
        }) or die $DBI::errstr;


my $object = Gtk2::Ex::DbLinker::DbiDataManager->new ({dbh =>$dbh, 
		sql=>{
			select => "country",
	       		from => "countries",
			where => "countryid=1",	
		      },
		 primary_keys => ["countryid"], 
		});
isa_ok ($object, 'Gtk2::Ex::DbLinker::DbiDataManager');
ok( $object->row_count == 1, " got one row in table countries");


