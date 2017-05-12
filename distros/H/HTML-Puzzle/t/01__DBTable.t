# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
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
# Create table support
$comp->create;
my @names = $dbh->tables;
my %tables = map {$_ => '1'} @names;
if (exists($tables{'Test'})) {
	print "ok " . ++$testid . "\n";
} else {
    exit;
}
# Fill with three items -- TO DO
foreach (qw/First Second Third Forth/) {
	my $addItem		= {
						'title'			=> "$_ title",
						'txt_short'		=> "$_ short text",
						'txt_long'		=> "$_ very long long text :-)",
						'link'			=> "http://$_.link.itm/",
						'link_img'		=> "http://$_.link.img/",
						'date'			=> '2002-07-21'
						};
	$comp->add($addItem);
}
print "ok " . ++$testid . "\n";
$comp->delete([2,4]);
print "ok " . ++$testid . "\n";
# Get  items as array
my $itm			= $comp->array_items();
print Data::Dumper::Dumper($itm);

if ( scalar(@{$itm}) == 3) {
	print "ok " . ++$testid . "\n";
} else {
    exit;
}
# Get  items as hash
$itm			= $comp->hash_items();
print Data::Dumper::Dumper($itm);

if (scalar(@{$itm}) == 2) {
	print "ok " . ++$testid . "\n";
} else {
    exit;
}
# Get items with filters
$itm		= $comp->hash_items(2,undef,{ title => 'First title' });
print Data::Dumper::Dumper($itm);

if (scalar(@{$itm}) == 1) {
	print "ok " . ++$testid . "\n";
} else {
    exit;
}

$loaded = 1;

1;