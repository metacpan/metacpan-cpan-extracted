# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use MMM::OracleDump;
use MMM::OracleDump::Table;
use DBI;

$|=1;
my ($user,$password, $db );  
my $table;
if (! -e "./blib/.data" ) {
	print 'username/password@db:';
		($user,$password, $db ) = split /\/|\@|\s+/,<STDIN>;
	open F, ">./blib/.data";
	print F join "\n", $user,$password, $db, $table;
	close F;	
}

open F, "./blib/.data";
my @lines = <F>;
close F;
chomp @lines;
($user,$password, $db) = @lines;

my $dbh = DBI->connect("dbi:Oracle:$db", $user, $password ,  { PrintError => 1 } );

my @tables = get_table_list( $dbh );
print join "\n", @tables;
print "\n";


print "Table: ";
$table = <STDIN>;
chomp $table;


my $tab = new MMM::OracleDump::Table($dbh,$table);

open F, ">.dump";
print "dumping $table to ./.dump\n";

print F $tab->get_create_sql();
$tab->dump_sql(\*F);

$dbh->disconnect;


$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

