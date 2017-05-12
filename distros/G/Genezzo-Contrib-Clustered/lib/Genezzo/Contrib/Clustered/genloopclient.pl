#!/usr/bin/perl
#
# genloopclient.pl
#
# This client tests the locking interaction between Clustered Genezzo clients.

use strict;
use warnings;

use Genezzo::GenDBI;
use Genezzo::Contrib::Clustered;
use Genezzo::Contrib::Clustered::GLock::GLock;

my $dbh;

sub sig_handler {
    print STDERR "\nPerl USR2 handler called\n";

    if(Genezzo::Contrib::Clustered::GLock::GLock::ast_poll()){
        print STDERR "\nast_poll returned true; rolling back\n";
        die("failed rollback") unless($dbh->do("rollback"));
    }
}

$SIG{USR2} = \&sig_handler;

Genezzo::Contrib::Clustered::GLock::GLock::set_notify();

$dbh = Genezzo::GenDBI->connect();  # $gnz_home, "NOUSER", "NOPASSWORD");

unless (defined($dbh))
{
    die("could not find database");
}

die("startup failed") unless $dbh->do("startup");

die("failed initial rollback") unless($dbh->do("rollback"));

while(1){
    print STDERR ".";
    sleep(1);
}

