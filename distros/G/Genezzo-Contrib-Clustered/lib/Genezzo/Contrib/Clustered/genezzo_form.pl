#!/usr/bin/perl
#
# genezzo_form.pl
# Eric Rollins 2005
#
# This simple sample mod-perl script provides web access
# to Genezzo.  The form is used to submit a SQL statement,
# And the results are returned as XML.
#
# It also demonstrates the use of SQL statements nested inside a page.
# This way pages act much like a stored procedure.  The web page
# parameters are used like stored procedure parameters, and the
# processing on the page forms the transaction boundary.

# Prior to running this script a Genezzo database must be
# created.  The script currently assumes the database was
# created using
#   gendba.pl -gnz_home=/unsafe -init
#
# as user www-data.  Prior to running this command the
# directory /unsafe must be created and www-data given
# permission to write it.
#
# The /unsafe directory is unsafe since any cgi-bin script can access it.
#
use strict;
use warnings;

use Genezzo::Contrib::Clustered::ModPerlWrap;
use CGI qw(:standard escapeHTML);

my $query = param('query');

if(!defined($query)){
  PrintForm();
} else {
    StartPage();
    Connect("/unsafe");

    if($query eq "query_sample"){
	ProcessStmt("select * from t1");
    } elsif($query eq "insert_sample"){
	ProcessStmt("insert into t1 values (10, 'test10')");
	ProcessStmt("insert into t1 values (11, 'test11')");
    } else {
	ProcessStmt($query);
    }

    Commit();
    FinishPage();
}

