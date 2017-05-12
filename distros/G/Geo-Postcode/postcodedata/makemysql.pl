#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use DBI;
$|++;

my $database = 'amnesty';
my $csvdata = './postcodes.csv';
my $tablename = 'postcode_locations';
my $user = 'amnesty';
my $password = 'sus1e';

open( INPUT, $csvdata) || die("can\'t open file $csvdata: $!");
print "found postcode data ok\n";

my $dbh = DBI->connect("dbi:mysql:database=$database",$user,$password);
print "connected to database ok\n" if $dbh;

my @cols = split(",",<INPUT>);
chomp @cols;
my $columns = join(", ", map { "$_ varchar(255)" } grep { $_ ne "postcode" } @cols);
print "data columns:\n$columns\n";

my $maketable = "create table $tablename (postcode varchar(12) NOT NULL, $columns, primary key(postcode));";
print "creating table with\n$maketable\n";

$dbh->do($maketable);
print "created $tablename table.\nInserting location data.";

my $counter;
my $insert = "INSERT INTO $tablename( " . join(",",@cols) . " ) values ( " . join(",", map { "?" } @cols) . ")";
my $sth = $dbh->prepare($insert);
while (<INPUT>) {
    chomp;
    my @data = split(/,/);
    $sth->execute( @data );
    $counter++;
    print ".";
}

$sth->finish;
$dbh->disconnect;
print "\n\ndone.\n$counter points imported into sample data set.\n\n";
