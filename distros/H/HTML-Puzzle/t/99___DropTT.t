# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok " . ++$testid . "\n" unless $loaded;}

use DBI;
use HTML::Puzzle::DBTable;
use Data::Dumper;

require "t/dbInfo.pl";

# Open the db handle
my $conn_string 	= "DBI:" . &driver . ":database=" . &db . ";host=" . &host
						. ";port=" . &port;
my $dbh 		= DBI->connect($conn_string, &user, &pw) 
											or die "Unable to open db handle";

# Create test obj
my $comp		= new HTML::Puzzle::DBTable(	dbh			=> $dbh,
												name		=> 'Test'
						);

# Destroy table support
$comp->drop;
@names = $dbh->tables;
%tables = map {$_ => '1'} @names;
if (!exists($tables{'Test'})) {
	print "ok " . ++$testid . "\n";
} else {
    exit;
}




$loaded = 1;

1;