
# $Id: arcdbi.t,v 1.3 2007/06/22 20:41:36 lem Exp $

# Check the DBI archiving

use DBI;
use Text::CSV_XS;
use IO::File;
use Test::More;
use NetAddr::IP;
use Mail::Abuse::Reader;
use Mail::Abuse::Report;
use Mail::Abuse::Incident;

use Data::Dumper;

my $dsn = "dbi:CSV:f_dir=.;csv_sep_char=,;csv_eol=\n";

@incidents = 
    (
     ['172.16.64.25/32', 1000, 'test/foobar'],
     ['172.16.64.25/32', 1000, 'test/foobaz'],
     ['172.16.64.25/32', 1000, 'test/bazbar'],
     );

				# Some funny helper classes
package myReader;
our $index = 0;
use base 'Mail::Abuse::Reader';
sub read { my $text = "All your base are belong to us!";
	   $_[1]->text(\$text); $_[1]->score(1); 
	   $_[1]->store_file($index++); return 1 }

package myIncident;
use base 'Mail::Abuse::Incident';
sub new { bless {}, ref $_[0] || $_[0] };

package myParser;
use base 'Mail::Abuse::Incident';
sub parse {
    my @incidents = ();

    for my $i (@main::incidents)
    {
	my $I = new myIncident;
	$I->ip		(new NetAddr::IP $i->[0]);
	$I->time	($i->[1]);
	$I->type	($i->[2]);
	push @incidents, $I;
    }

    return @incidents;
};

package main;

my $config	= "config$$";	# Fake config

sub _create
{
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1});
    $dbh->do(q{CREATE TABLE Reports	(File VARCHAR, Num INTEGER, 
					 Score VARCHAR, Time INTEGER)});
    $dbh->do(q{CREATE TABLE Incidents	(File VARCHAR, Num INTEGER, 
					 Time INTEGER, Type VARCHAR, 
					 IP VARCHAR)});
    $dbh->disconnect;
}

sub _drop
{
    my $dbh = DBI->connect($dsn, '', '', { PrintError => 0,
							RaiseError => 0});
    $dbh->do('DROP TABLE Reports');
    $dbh->do('DROP TABLE Incidents');
    $dbh->disconnect;
}

sub write_config 		# Produce a suitable config file for testing
{
    _create;
    my $fh = new IO::File;
    $fh->open($config, "w")
	or diag "Failed to create test config file: $!";
    print $fh "archive dsn: $dsn\n";
    print $fh 'archive reports columns: File:not_here File:store_file '
      . 'Score:score Time:$time Num:$num' . "\n";
    print $fh 'archive incident columns: Num:$num Time:time '
      . 'Type:type IP:ip' . "\n";
    print $fh "archive incident foreign key: File\n";
    print $fh "# debug archive: 1\n";
    $fh->close;
}

END { unlink $config; _drop };

plan tests => 33;

diag "Failed to use Mail::Abuse::Processor::ArchiveDBI\n", 
    "The rest of the tests in this suite will fail"
    unless use_ok('Mail::Abuse::Processor::ArchiveDBI');

my $rep;

# Start with a clean state and config
_drop;
write_config;

$rep = new Mail::Abuse::Report
{
    config	=> $config,
    reader	=> new myReader,
    parsers	=> [ new myParser ],
    processors	=> [ new Mail::Abuse::Processor::ArchiveDBI ],
};

isa_ok($rep, 'Mail::Abuse::Report');
$rep->next;

# XXX - We should be testing by using the DBI interface,
# however it seems that the SQL parsers are not doing a good-enough
# work as of this writing.

# At this point, the data files must be read to verify the correct
# info is being stored.

# Test that the "tables" exist

ok(-f 'Reports', 'Report table exists - More of a test harness issue');
ok(-f 'Incidents', 'incidents table exists - More of a test harness issue');

# Test Reports first

my $csv = Text::CSV_XS->new({
    sep_char	=> ',',
    eol		=> "\n",
});

my $fh = new IO::File 'Reports';
diag "Failed to open 'Reports': $!"
    unless ok($fh, "Opening of 'Reports'");

my $cols = $csv->getline($fh);
is(ref $cols, 'ARRAY', "->getline returned an arrayref (titles)");

$cols = $csv->getline($fh);
is(ref $cols, 'ARRAY', "->getline returned an arrayref (first row)");
is($cols->[0], 0, "Correct file name");
is($cols->[1], 3, "Corrent number of incidents");
is($cols->[2], 1, "Correct score");
ok($cols->[3] <= time && $cols->[3] >= 1000, "Apparently correct time");

$cols = $csv->getline($fh);
is($cols, undef, "Correct number of rows in the table"); 
$fh->close;

$fh = new IO::File 'Incidents';
diag "Failed to open 'Incidents': $!"
    unless ok($fh, "Opening of 'Incidents'");

$cols = $csv->getline($fh);
is(ref $cols, 'ARRAY', "->getline returned an arrayref (titles)");

my $idx = 0;
for my $r (@incidents)
{
    $cols = $csv->getline($fh);
    is(ref $cols, 'ARRAY', "->getline returned an arrayref");

    is($cols->[0], 0, 'Correct report file name');
    is($cols->[1], $idx, 'Correct incident number');
    is($cols->[2], $r->[1], 'Correct incident time');
    is($cols->[3], $r->[2], 'Correct incident type');
    is($cols->[4], $r->[0], 'Correct incident IP address');
    $idx ++;
    
}

$cols = $csv->getline($fh);
is($cols, undef, "Correct number of rows in the table"); 
$fh->close;
