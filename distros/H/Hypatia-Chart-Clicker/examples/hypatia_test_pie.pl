use strict;
use warnings;
use Hypatia;
use DBD::SQLite;

unlink("test.db") if (-e "test.db");

my $dbh=DBI->connect("dbi:SQLite:dbname=test.db","","") or die DBI->errstr;

$dbh->do("create table test_table
(
	a text,
	b int
)") or die $dbh->errstr;

$dbh->do("insert into test_table values ('blah',2)") or die $dbh->errstr;
$dbh->do("insert into test_table values ('blah',3)") or die $dbh->errstr;
$dbh->do("insert into test_table values ('meh',1)") or die $dbh->errstr;
$dbh->do("insert into test_table values ('meh',2)") or die $dbh->errstr;
$dbh->do("insert into test_table values ('gah',3)") or die $dbh->errstr;

$dbh->disconnect;

undef $dbh;

my $hypatia=Hypatia->new({
    back_end=>"Chart::Clicker",
    graph_type=>"Pie",
    columns=>{label=>'a',values=>'sum_b'},
    dbi=>{
        dsn=>"dbi:SQLite:dbname=test.db",
		query=>"select a,sum(b) as sum_b from test_table group by a"
    }
});


my $cc=$hypatia->graph;
$cc->write_output("pie.png");
