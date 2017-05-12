use Test::More;
use DBI;
use HTML::DBTable;

my $reason = "You haven't configure a db connection during Makefile creation.";


if (-e 't/dbInfo.pl') {
	plan tests => 10;
} else {
	plan skip_all => $reason
}

BEGIN { use_ok('HTML::DBTable') }


ok( -e 't/dbInfo.pl',		 'db configuration file created by makefile');
require 't/dbInfo.pl';
# Open the db handle
my $conn_string     = "DBI:" . &driver . ":database=" . &db . ";host=" . &host
                        . ";port=" . &port;
my $dbh         = DBI->connect($conn_string, &user, &pw)
                                            or die "Unable to open db handle";

my $sql;

$sql = <<EOF;
CREATE TABLE DBTable_test (
column1 VARCHAR(64) NOT NULL ,
column2 INT NOT NULL ,
column3 DATE NOT NULL ,
PRIMARY KEY (column1)
)
EOF

ok($dbh->do($sql),'creating testing table');

$sql=<<EOF;
INSERT INTO DBTable_test (column1, column2, column3) VALUES ('test1', 1, '2003-01-01')
EOF
ok($dbh->do($sql),'filling with examples data');

$sql=<<EOF;
INSERT INTO DBTable_test (column1, column2, column3) VALUES ('test2', 2, '2003-02-02')
EOF
ok($dbh->do($sql),'filling with examples data');

$sql = "select * from DBTable_test where column1='test1'";


my $item = $dbh->selectrow_hashref($sql) or die("Recupero elemento non riuscito");

my $pd = new HTML::DBTable();
isa_ok( $pd,'HTML::DBTable', 'testing object ISA');
isa_ok( $pd->dbh($dbh),'DBI::db','testing DBI usage' );
ok($pd->tablename('DBTable_test') eq 'DBTable_test','testing DB table usage');
ok($pd->html(values=>$item)=~/column3/m,'printing html output');	
ok($pd->html(values=>$item)=~/2003\-01\-01/m,'printing html output with values');	

END {
	if ($dbh) {
		$sql = 'DROP TABLE DBTable_test';
		ok($dbh->do($sql),'dropping testing table');
	}
}


