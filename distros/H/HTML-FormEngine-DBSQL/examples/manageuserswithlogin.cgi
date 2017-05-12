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
$Form->get_skin_obj()->set_dbsql_secret('te123st');
#$Form->dbsql_set_write_null_fields(2);
my %preconf = (
    "user.phone" => {
	SUBTITLE => [[]],
    }
);
$Form->dbsql_preconf(\%preconf, undef, {templ => 'text', TYPE => 'password', TITLE => 'Conf. Password', NAME => 'passconf', ERROR => 'fmatch', fmatch => 'login.password'});
$Form->dbsql_conf(['user','login'], {login => 'uid IS NOT NULL', user => 'uid IN (SELECT uid FROM "login" WHERE uid IS NOT NULL)'});
print $q->start_html('FormEngine-dbsql example: User Administration');
$Form->make();
if($Form->ok) {
    $_ = $Form->dbsql_update();
    print "Successfully updated $_ user(s)" if($_);
}

print $Form->get,
      $q->end_html;
$dbh->disconnect;
