#!perl

use Test::More tests => 3;

BEGIN { require "t/test_init.pl" }

use JDBC;

JDBC->load_driver($::JDBC_DRIVER_CLASS);
pass "driver class loaded";

my $con = JDBC->getConnection($::JDBC_DRIVER_URL, "test", "test");

my $s1 = $con->createStatement();
print "Statement:  $s1\n";

$s1->executeUpdate("create table foo (foo int, bar varchar(200), primary key (foo))");
$s1->executeUpdate("insert into foo (foo, bar) values (42,'notthis')");
$s1->executeUpdate("insert into foo (foo, bar) values (43,'notthat')");
my $rs = $s1->executeQuery("select foo, bar from foo");
while ($rs->next()) {
    my $foo = $rs->getInt(1);
    my $bar = $rs->getString(2);
    print "row: foo=$foo, bar=$bar\n";
}

my $s2 = $con->createStatement(
	$java::sql::ResultSet::TYPE_FORWARD_ONLY,
	$java::sql::ResultSet::CONCUR_READ_ONLY
);
ok ref $s2, "got ref";
can_ok $s2, 'executeUpdate';

