
# $Id: tabledbi.t,v 1.1 2005/06/09 16:03:46 lem Exp $

# Check the DBI table lookup

use DBI;
use Test::More;
use NetAddr::IP;
use Mail::Abuse::Reader;
use Mail::Abuse::Report;
use Mail::Abuse::Incident;

use Data::Dumper;

my $dsn = 'dbi:CSV:f_dir=.';
our @incidents = ( ['127.0.0.1/32', 1000],
		   ['127.0.0.1/32', 1001],
		   ['10.0.0.1/32', 1000],
		   );
				# Some funny helper classes
package myReader;
our $index = 0;
use base 'Mail::Abuse::Reader';
sub read { my $text = "All your base are belong to us!";
	   $_[1]->text(\$text); return 1 }

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
	$I->ip(NetAddr::IP->new($i->[0]));
	$I->time($i->[1]);
	push @incidents, $I;
    }

    return @incidents;
};

package main;

my $config	= "config$$";	# Fake config

sub _create
{
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1});
    my $ip = new NetAddr::IP '127.0.0.1/32';
    $dbh->do(q{CREATE TABLE StaticData	(CIDR_Start INTEGER,
					 CIDR_End INTEGER,
					 TIME_Start INTEGER,
					 TIME_End INTEGER,
					 Info CHAR(64))});
    $dbh->do(q{INSERT INTO StaticData 
	       (CIDR_Start, CIDR_End, TIME_Start, TIME_End, Info)
	       VALUES (} . scalar($ip->network->numeric) . ',' .
	       scalar($ip->broadcast->numeric) . ',' .
	       1000 . ',' . 1000 . q{, 'Test ok')});

    $dbh->disconnect;
#    diag `cat StaticData`;
}

sub _drop
{
    my $dbh = DBI->connect($dsn, '', '', { PrintError => 0,
					   RaiseError => 0});
    $dbh->do('DROP TABLE StaticData');
    $dbh->disconnect;
}

sub write_config 		# Produce a suitable config file for testing
{
    _create;
    my $fh = new IO::File;
    $fh->open($config, "w")
	or diag "Failed to create test config file: $!";
    print $fh "dbi table dsn: $dsn\n";
    print $fh "dbi table name: StaticData\n";
    print $fh "# debug dbi table: 1\n";
    $fh->close;
}

END { unlink $config; _drop };

plan tests => 7;

diag "Failed to use Mail::Abuse::Processor::ArchiveDBI\n", 
    "The rest of the tests in this suite will fail"
    unless use_ok('Mail::Abuse::Processor::TableDBI');

my $rep;

# Start with a clean state and config
_drop;
write_config;

$rep = new Mail::Abuse::Report
{
    config	=> $config,
    reader	=> new myReader,
    parsers	=> [ new myParser ],
    processors	=> [ new Mail::Abuse::Processor::TableDBI ],
};

isa_ok($rep, 'Mail::Abuse::Report');
$rep->next;

# Now we must verify that our incidents are properly matched

is(scalar @{$rep->{incidents}}, scalar @incidents, 
   'Correct number of incidents');

# First incident must be a match
ok($rep->incidents->[0]->tabledbi,
   "First incident seems to match as expected");
is($rep->incidents->[0]->tabledbi->{Info}, 'Test ok',
   "Correct information returned");

# Second incident must not match
diag "Incident 2 matched incorrectly: ", $rep->incidents->[1]
    unless ok(! defined $rep->incidents->[1]->tabledbi,
	      "2nd incident must not have matched");

# Third incident must not match
diag "Incident 3 matched incorrectly: ", $rep->incidents->[2]
    unless ok(! defined $rep->incidents->[2]->tabledbi,
	      "3rd incident must not have matched");
