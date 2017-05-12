#!/usr/bin/perl -w

use strict;
use HTML::FormEngine::DBSQL;
use DBI;
use CGI;
#use POSIX;
#setlocale(LC_MESSAGES, 'german');

my $q = new CGI;
print $q->header;

my $dbh = DBI->connect('dbi:Pg:dbname=test', 'test', 'test');
my $Form = HTML::FormEngine::DBSQL->new(scalar $q->Vars, $dbh);
#$Form->dbsql_set_secret('te123st');
$Form->get_skin_obj()->set_dbsql_secret('te123st');
my %preconf = (
    "phone" => {
	SUBTITLE => [[]],
    }
);
$Form->dbsql_preconf(\%preconf);
$Form->dbsql_conf('user', 'uid IS NOT NULL');
print $q->start_html('FormEngine-dbsql example: User Administration');
$Form->make();
if($Form->ok) {
    $_ = $Form->dbsql_update();
    print "Successfully updated $_ user(s)" if($_);
}

print $Form->get,
      $q->end_html;
$dbh->disconnect;
