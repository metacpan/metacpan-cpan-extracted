#!/usr/bin/perl -w
#
# script to update the db
#
# $Id: moby-s-update-db.pl,v 1.2 2009/04/03 16:50:50 kawas Exp $
# Contact: Edward Kawas <edward.kawas@gmail.com>
# -----------------------------------------------------------
use strict;
use DBI;
use DBD::mysql;

BEGIN {
	use Getopt::Std;
	use vars qw/ $opt_h $opt_c /;
	getopts('hc');

	use constant MSWIN => $^O =~ /MSWin32|Windows_NT/i ? 1 : 0;

	# usage
	if ($opt_h or not $opt_c) {
		print STDOUT <<'END_OF_USAGE';
Script to help update your BioMOBY registry database.

Usage: moby-s-update-db.pl [-h] -c

	-c          ..... update the db to include cgi-async
	                  as a service category.

	-h          ..... shows this message

	You will need to know the username/password of a user
	with write access to the BioMOBY databases.
	
    Good luck!


END_OF_USAGE
		exit(0);
	}
}

if ($opt_c) {

	print "\n\n\n
\tThis script will update your mobycentral database such that
\tthe service_instance table has a category enum field of 'cgi-async'.  


\tThe login you use below MUST have administration privileges 
\ton the mobycentral database!
\n\n";

	my $go = 1;    # change this to '0' for a dry run...

	print "Central Registry Databasename [mobycentral]: ";
	my $dbname = <STDIN>;
	chomp $dbname;
	$dbname ||= 'mobycentral';
	print "\n";

	print "Central Registry Database URL [localhost]: ";
	my $url = <STDIN>;
	chomp $url;
	$url ||= 'localhost';
	print "\n";

	print "Central Registry Database Port [3306]: ";
	my $port = <STDIN>;
	chomp $port;
	$port ||= 3306;
	print "\n";

	print "Central Registry Database Username [root]: ";
	my $username = <STDIN>;
	chomp $username;
	$username ||= 'root';
	print "\n";

	print "Cenral Registry Database Password [undef]: ";
	my $password = <STDIN>;
	chomp $password;
	$password ||= undef;
	print "\n";

	my $driver = 'DBI:mysql';
	my ($dsn)  = "$driver:$dbname:$url:$port";
	my $dbh    = DBI->connect( $dsn, $username, $password, { RaiseError => 1 } )
	  or die "can't connect to database";
	die "can't connect to database\n" unless $dbh;

	# does the field already exist?
	my $results = $dbh->selectall_hashref( 'describe service_instance', 'Field' );

	my $category = $results->{category}->{Type}
	  if defined $results->{category} and $results->{category}->{Type};

	die "Database doesn't seem to be created yet." unless $category;

	unless ( $category =~ m/cgi\-async/i ) {
		$go
		  && $dbh->do(
" alter table service_instance modify category ENUM('moby','soap','wsdl','cgi','moby-async', 'cgi-async', 'doc-literal', 'doc-literal-async') default NULL"
		  );
	}

	print "\nUpdate Complete!\n";
}
