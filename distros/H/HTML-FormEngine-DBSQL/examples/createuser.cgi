#!/usr/bin/perl -w

use strict;
use HTML::FormEngine::DBSQL;
use DBI;
use CGI;
#use POSIX; #for setlocale
#setlocale(LC_MESSAGES, 'german'); #for german error messages

my $q = new CGI;
print $q->header;

my $dbh = DBI->connect('dbi:Pg:dbname=test', 'test', 'test');
my $Form = HTML::FormEngine::DBSQL->new(scalar $q->Vars, $dbh);
$Form->dbsql_conf('user');
$Form->make();
print $q->start_html('FormEngine-dbsql example: User Administration');
if($Form->ok) {
    if($_ = $Form->dbsql_insert()) {
	print "Sucessfully added $_ user(s)!<br>";
	$Form->clear;
    }
}
print $Form->get,
      $q->end_html;
$dbh->disconnect;
