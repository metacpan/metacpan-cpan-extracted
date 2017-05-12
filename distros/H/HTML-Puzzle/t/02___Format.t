BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok " . ++$testid . "\n" unless $loaded;}

use DBI;
use HTML::Puzzle;

use Data::Dumper;

require "t/dbInfo.pl";

# Open the db handle
my $conn_string 	= "DBI:" . &driver . ":database=" . &db . ";host=" . &host
						. ";port=" . &port;
my $dbh 		= DBI->connect($conn_string, &user, &pw) 
											or die "Unable to open db handle";

# Create DBTable obj
my $comp		= new HTML::Puzzle::DBTable(	dbh			=> $dbh,
												name		=> 'Test'
						);
					
# Get  items as hash
$itm			= $comp->hash_items();

# Create test obj

my $fmtHtml		= new HTML::Puzzle::Format(
											items => $itm,
											filename => 'templates/format_simple.tmpl',
											opt_items => {
															'section_title' =>
															'PUZZLE Test'
														}
										);

$_ = $fmtHtml->html;

print;

if (m/First title/ms && m/Third short text/ms && m/PUZZLE Test/ms && 
	!m/\<body/i) {
	print "ok " . ++$testid . "\n";
} else {
    exit;
}

# test internal DBTable access

$fmtHtml		= new HTML::Puzzle::Format(
											dbh			=> $dbh,
											tablename	=> 'Test',
											filename => 'templates/format_simple.tmpl',
											opt_items => {
															'section_title' =>
															'PUZZLE Test'
														}
										);

$_ = $fmtHtml->html;

print;

if (m/First title/ms && m/Third short text/ms && m/PUZZLE Test/ms && 
	!m/\<body/i) {
	print "ok " . ++$testid . "\n";
} else {
    exit;
}

$loaded = 1;

1;
