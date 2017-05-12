#!/usr/bin/perl -Ilib -w

# $Id: install_honeyclient_db.pl 601 2007-06-21 20:37:41Z kindlund $

use strict;
use warnings;
use Carp ();

use ExtUtils::MakeMaker qw(prompt);
use Net::IP qw(ip_is_ipv4);
use DBI;
use DBI::Const::GetInfoType;
use HoneyClient::Util::Config qw(getVar);

print "************************************************\n" .
      "*** HoneyClient Database Installation Script ***\n" .
      "************************************************\n" .
      "\n" .
      "This script will install and configure the\n" .
      "HoneyClient database onto an existing MySQL server.\n" .
      "\n" .
      "Before running this script, you need to edit your\n" .
      "etc/honeyclient.xml global configuration file and\n" .
      "make sure that the <HoneyClient/><DB/> section\n" .
      "contains valid database connection information.\n" .
      "\n";

# Retrieve values from the global configuration file.
my $host = getVar(name => "host", namespace => "HoneyClient::DB");
my $user = getVar(name => "user", namespace => "HoneyClient::DB");
my $pass = getVar(name => "pass", namespace => "HoneyClient::DB");
my $database_name = getVar(name => "dbname", namespace => "HoneyClient::DB");
my ($question, $root_password);

print "The following database configuration was found:\n\n";

my $buf = sprintf("%s %s\t= '%s'", " " x 4,  "host", $host) . "\n" .
          sprintf("%s %s\t= '%s'", " " x 4,  "user", $user) . "\n" .
          sprintf("%s %s\t= '%s'", " " x 4,  "pass", $pass) . "\n" .
          sprintf("%s %s\t= '%s'", " " x 4,  "dbname", $database_name) . "\n";

print $buf . "\n";

$question = prompt("Is this correct?", "yes");
print "\n";

if ($question !~ /^y.*/i) {
    print "Please edit the etc/honeyclient.xml file\n" .
          "accordingly re-run this script.\n";
    exit;
}

# Get the root password.
system("stty -echo");
$root_password = prompt("Please enter your database 'root' password:");
system("stty echo");
print "\n";
print "\n";

my $sql = undef;
my $dsn = "DBI:mysql:database=mysql;host=" . $host;

eval {
    # Connect and Create Database
    my $dbh = DBI->connect($dsn, 'root', $root_password, {'RaiseError' => 1});
    if ($dbh eq '') {
        Carp::croak("Installation Failed: " . $DBI::errstr);
    }

    my $database_system_name = $dbh->get_info($GetInfoType{SQL_DBMS_NAME});
    my $database_system_version = $dbh->get_info($GetInfoType{SQL_DBMS_VER});

    # Extract the major version number.
    $database_system_version =~ s/^(\d.*?)\..*/$1/;

    if (($database_system_name !~ /^mysql/i) or
        ($database_system_version < 5)) {

        print "Your database does not appear to be running MySQL v5.0\n" .
              "or greater.  This code will only work properly on databases\n" .
              "with this type and version.\n";

        $dbh->disconnect() if $dbh;
        exit;
    }

    # Create the database.
    print "* Creating database name '" . $database_name . "'.\n\n";
    $sql = "CREATE DATABASE " . $database_name;
    print "Issuing SQL Command:\n" . $sql . "\n";
    proceed();
    $dbh->do($sql);

    # Get the IP address of the host system where the Manager will be
    # installed to.
    my $manager_address = "127.0.0.1";
    $question = prompt("Will the database and the HoneyClient::Manager\n" .
                       "run on the same host system?", "yes");
    print "\n";

    if ($question !~ /^y.*/i) {
        my $ip = "x";
        my $is_valid = 0;
        while (!$is_valid) {
            $manager_address = prompt("Enter the IP address of the host system\n" .
                                      "that the HoneyClient::Manager will run\n" .
                                      "from (wildcard is %):\n", "172.16.164.%");

            $ip = $manager_address;
            $ip =~ s/%/0/g;
            $is_valid = ip_is_ipv4($ip);

            if (!$is_valid) {
                print "\n";
                print "* Error: Address is not valid! Try again.\n";
            }
            print "\n";
        }
    }

    # Create a user account to access and manage the database.
    print "* Creating database user '". $user . "'.\n\n";
    $sql = "GRANT ALL PRIVILEGES ON " . $database_name .".* TO '" . $user . "\'@\'" .
           $manager_address . "' IDENTIFIED BY '" . $pass . "'";
    print "Issuing SQL Command:\n" . $sql . "\n";
    proceed();
    $dbh->do($sql);

    # Flush privileges, in order to get MySQL to re-read the GRANT table.
    print "* Flushing privileges, in order to activate the newly added user.\n\n";
    $sql = "FLUSH PRIVILEGES";
    print "Issuing SQL Command:\n" . $sql . "\n";
    proceed();
    $dbh->do($sql);
        
    $dbh->disconnect() if $dbh;
};
if ($@) {
    Carp::croak("Installation Failed: " . $@);
}

sub proceed {
    print "\n";
    my $question = prompt("Proceed?", "yes");
    print "\n";
    if ($question !~ /^y.*/i) {
        print "Aborting Installation.\n";
        exit;
    }
}

print "Database and user installed successfully.\n";
