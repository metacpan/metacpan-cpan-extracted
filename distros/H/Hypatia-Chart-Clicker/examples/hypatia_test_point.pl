use strict;
use warnings;
use Hypatia;
use DBD::SQLite;

unlink("test.db") if (-e "test.db");

my $dbh=DBI->connect("dbi:SQLite:dbname=test.db","","") or die DBI->errstr;

$dbh->do("create table test_table
(
    col1 real,
    col2 real,
    col3 real
)") or die $dbh->errstr;

$dbh->do("insert into test_table values (1,2.71828,0.3)") or die $dbh->errstr;
$dbh->do("insert into test_table values (0,2.1,3)") or die $dbh->errstr;
$dbh->do("insert into test_table values (2,6,4.111)") or die $dbh->errstr;
$dbh->do("insert into test_table values (3,8,5)") or die $dbh->errstr;
$dbh->do("insert into test_table values (4.1,9,6)") or die $dbh->errstr;

$dbh->disconnect;

undef $dbh;

my $hypatia=Hypatia->new({
    back_end=>"Chart::Clicker",
    graph_type=>"Point",
    columns=>{x=>"col1",y=>[qw(col2 col3)]},
    dbi=>{
        dsn=>"dbi:SQLite:dbname=test.db",
        query=>"select col1,col2,col3 from test_table"
    }
});

my $cc=$hypatia->graph;
my $dc=$cc->get_context("default");
$dc->domain_axis->label("blarg");
$cc->write_output("point.png");