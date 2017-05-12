#!/usr/bin/perl -w

#
# $Id: CloneCentralDatabases.pl,v 1.1 2008/02/21 00:21:28 kawas Exp $
# $Source: /home/repository/moby/moby-live/Perl/MOBY-Server/share/scripts/CloneCentralDatabases.pl,v $
#

use strict;
use Getopt::Std;
use MOBY::Client::Central;
use MOBY::Config;

my $master_central;

#
# Split up text in 2 pieces to prevent CVS from filling in the id and source strings overhere.
#
my $cvs_id1 = '$I';
my $cvs_id2 = 'd$';
my $cvs_source1 = '$S';
my $cvs_source2 = 'ource$';

#
# Official MOBY Central. (Currently down)
#
my $master_central_uri = 'http://moby.ucalgary.ca/MOBY/Central';
my $master_central_url = 'http://moby.ucalgary.ca/moby/MOBY-Central.pl';

#
# Get options.
#

my %opts;
getopts('mc:p:', \%opts);
unless ($opts{'m'}) {
	_Usage(); 
}
unless ($opts{'p'}) {
	print "\nPassword missing. Please specify -p [password]\n";
	_Usage();
}
my $mysql_rootpwd = $opts{'p'};
if ($opts{'c'}) {
	($master_central_uri, $master_central_url) = split '@', $opts{'c'};
}

_ExistsLocalCentralConfig();

print "Fetching data from MOBY Central:\n\t$master_central_uri @ $master_central_url\n";
print "to rebuild the local MOBY Central clone/mirror configuration.\n";

# Set this to wherever your MOBY Central is.
$master_central = MOBY::Client::Central->new(
   	Registries => {
       	mobycentral => {
			URL => $master_central_url,
			URI => $master_central_uri
		}
	}
);

#
# Create or cleanup the SQL dump dir.
#

my $dumpdir = './sqldump/';

if (-e $dumpdir && -d $dumpdir) {

	print "SQL dump directory $dumpdir exists.\n";

	#
	# Find old SQL dump files.
	#

	opendir (DUMPDIR, $dumpdir) or die "Couldn't open SQL dump directory: $!\n";
	my @sqlfiles = grep { /.+\.sql/i } readdir DUMPDIR;
	closedir DUMPDIR;

	#
	# Remove old SQL dumps.
	#

	if (scalar(@sqlfiles)) {

		print "Removing old SQL dumps...\n";
		
		foreach my $file (@sqlfiles) {

			my $path = $dumpdir .+ $file;
			print "\tRemoving $path...";
			unlink $path or die "\n\tCould not unlink $path: $!\n";
			print " done.\n";
		
		}

	} else {

		print "Can not remove old SQL dumps: No old SQL dumps found.\n";
	
	}

} else {

	print "Creating SQL dump directory $dumpdir...";
	mkdir $dumpdir,0755 or die "\n\tCouldn't create SQL dump directory $dumpdir: $!\n";
	print " done.\n";

}

#
# Fetch MOBY Central data.
#

print "MOBY Central Data Dump:\n";

# A simple MOBY_Central call to get a complete dump of registered stuff.
my ($mobycentral, $mobyobject, $mobyservice, $mobynamespace, $mobyrelationship) = $master_central->MOBY::Client::Central::DUMP();
#my ($mobycentral, $mobyobject, $mobyservice, $mobynamespace, $mobyrelationship) = $central->MOBY::Client::Central::DUMP(['mobycentral']);

_DumpSQL('mobycentral', $mobycentral);
_DumpSQL('mobyobject', $mobyobject);
_DumpSQL('mobyservice', $mobyservice);
_DumpSQL('mobynamespace', $mobynamespace);
_DumpSQL('mobyrelationship', $mobyrelationship);

#
# Create new MOBY Central.
#

print "Creating MOBY Central clone/mirror:\n";

my $config = MOBY::Config->new();
my @dbsections = ('mobycentral', 'mobyobject', 'mobyservice', 'mobynamespace', 'mobyrelationship');

my $data;

$data .= "--\n";
$data .= "-- $cvs_id1$cvs_id2\n";
$data .= "-- $cvs_source1$cvs_source2\n";
$data .= "--\n\n";

foreach my $dbsection (@dbsections)	{

	my $dbname   = ${${$config}{$dbsection}}{'dbname'};
	my $username = ${${$config}{$dbsection}}{'username'};
	my $password = ${${$config}{$dbsection}}{'password'};

 	$data .= "DELETE FROM mysql.user WHERE user=\"$username\"\;\n";
	$data .= "DROP DATABASE IF EXISTS $dbname\;\n";
    $data .= "FLUSH PRIVILEGES\;\n";
	$data .= "CREATE DATABASE IF NOT EXISTS $dbname\;\n";
	$data .= "USE $dbname\;\n";
	$data .= "GRANT ALL PRIVILEGES ON $dbname.* TO \"$username\"\@\"localhost\" identified by \"$password\"\;\n";
	$data .= "FLUSH PRIVILEGES\;\n";
	
}

$data .= "FLUSH PRIVILEGES\;\n";
$data .= "FLUSH PRIVILEGES\;\n";
$data .= "FLUSH PRIVILEGES\;\n";
			
my $sqlfile   = $dumpdir .+ 'createdatabases.sql';
open (SQLSAVE,">>$sqlfile") or die "\tERROR: can't open output file $sqlfile: $!\n";
print SQLSAVE $data or die "\tERROR: can't save output to file $sqlfile: $!\n";
print "\tCreated script to create MySQL databases.\n";
close SQLSAVE;

system("mysql -u root --password=$mysql_rootpwd < $sqlfile") == 0 or die "\n\tCan't create databases using sql file $sqlfile: $?\n";

foreach my $dbsection (@dbsections)	{

	my $dbname   = ${${$config}{$dbsection}}{'dbname'};
	my $username = ${${$config}{$dbsection}}{'username'};
	my $password = ${${$config}{$dbsection}}{'password'};
	my $host     = ${${$config}{$dbsection}}{'url'};
	my $port     = ${${$config}{$dbsection}}{'port'};

	_LoadSQL($dbsection, $dbname, $username, $password, $host, $port);

}

print "Finished!\n";

#
# Subs.
#

sub _DumpSQL {
	my ($db, $data) = @_;
	print "\tDumping $db...";
	my $pathto   = $dumpdir .+ $db .+ '.sql';
	
	open (SQLSAVE,">>$pathto") or die "\n\tERROR: can't open output file $pathto: $!";
	print SQLSAVE "--\n" or die "\n\tERROR: can't save output to file $pathto: $!";
	print SQLSAVE "-- $cvs_id1$cvs_id2\n" or die "\n\tERROR: can't save output to file $pathto: $!";
	print SQLSAVE "-- $cvs_source1$cvs_source2\n" or die "\n\tERROR: can't save output to file $pathto: $!";
	print SQLSAVE "--\n\n" or die "\n\tERROR: can't save output to file $pathto: $!";
	print SQLSAVE $data or die "\n\tERROR: can't save output to file $pathto: $!";
	print " saved $db to $dumpdir\n";
	close SQLSAVE;

	if (-z $pathto) {
		die "\tERROR: database dump $pathto for $db is empty.\n";
	}
}

sub _LoadSQL {
	my ($dbsection, $dbname, $username, $password, $host, $port) = @_;
	print "\tLoading data for $dbsection...";	
	my $sqlfilepath   = $dumpdir .+ $dbsection .+ '.sql';
	system("mysql -h $host -P $port -u $username --password=$password $dbname<$sqlfilepath") == 0 or die "\n\tCan't load data for $dbname: $!";
	print " done\n";
}

sub _ExistsLocalCentralConfig {

	my $confile = $ENV{MOBY_CENTRAL_CONFIG};
	
	unless ($confile) {

		print "ERROR:   MOBY_CENTRAL_CONFIG env var not set.\n\n";
		print "         A MOBY Central is a combination of scripts accessed through a webserver\n";
		print "         and some MySQL databases. This script will take care of the databases part\n";
		print "         provided that you have already installed the scripts and configured your\n";
		print "         webserver.\n";
		
		exit;

	}

	unless (-e $confile && -r $confile) {
	
		exit "ERROR:   MOBY_CENTRAL_CONFIG env var pointing to a missing or unreadable file.\n";
	
	} else {

		print "Found MOBY Central config file for local mirror/clone at:\n\t$confile\n"

	}
}

sub _Usage {
	print "\n";
	print "Options: -m              Mirror = clone = create a local MOBY Central mirror/clone from scratch.\n";
	print "         -c [central]    Central from which to fetch data. [central] is in format:\n";
	print "                         [centralURI]@[centralURL]\n";
	print "                         Default central is:\n";
	print "                         $master_central_uri\@$master_central_url\n";
	print "                         Edit this script to change the default MOBY Central.\n"; 
	print "         -p [password]   MySQL root password required for creating the MOBY Central databases.\n";
	print "\n";
	print "WARNING: This script will overwrite an existing local MOBY Central clone/mirror!\n";
	print "         Note that the local MOBY Central config (SOAP endpoint) might point to\n";
	print "         MySQL databases on a different machine.\n";
	print "\n";
	_ExistsLocalCentralConfig();
	print "Local MOBY Central config points to SQL databases:\n";
	
	my $config = MOBY::Config->new() or die "\tcan't find local MOBY Central config\n";
	my @dbsections = ('mobycentral', 'mobyobject', 'mobyservice', 'mobynamespace', 'mobyrelationship');

	foreach my $dbsection (@dbsections)	{

		my $dbname   = ${${$config}{$dbsection}}{'dbname'};
		my $host     = ${${$config}{$dbsection}}{'url'};
		my $port     = ${${$config}{$dbsection}}{'port'};
		
		print "\tdbname: $dbname\n";
		print "\t  host: $host\n";
		print "\t  port: $port\n";

	}

	print "\n";
	exit;
}
