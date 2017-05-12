use strict;
use warnings;

use Test::More;
use JDBIx;
$|= 1;

#plan tests => 18;
my $number_of_tests_2run = 18;

use lib 't', '.';

my $dbname = 'test.sqlite';
my $logfile = 'dbixlogt.txt';
unlink $dbname  if (-e $dbname);
unlink $logfile  if (-e $logfile);

ok(&jdbix_setlog($logfile), 'Successfully opened log file');

my $dbh;
eval {$dbh = new JDBIx("SQLite:$dbname",
                      { RaiseError => 1, PrintError => 1, AutoCommit => 0 });};
if ($@) {
    #diag $@;
    #plan skip_all => 'Skipping database tests - no database - DBD::SQLite not available for tests.';
    diag '****** Skipping database tests - no database - DBD::SQLite not available for tests, please install and retest!';
    $number_of_tests_2run = 1;
} else {
	ok(defined($dbh), "Connected to database");
	eval{ $dbh->do1('CREATE TABLE test (keyfield INTEGER, field1, field2, field3, field4, primary key (keyfield))') };
	ok(!$@, 'Created test database table.');
	diag $@ if $@;

	my $res;
	eval { $res = $dbh->do1("insert into test (field1, field2, field3, field4) values ('val1', 'val2', 'val3', 'val4')") };
	ok((!$@ && $res == 1), 'do1() insert row into table.');
	diag $@ if $@;

	our (@f1, @f2, @f3, @f4);
	for (my $i=0;$i<10;$i++) {
		push @f1, "f1val$i";
		push @f2, "f2val$i";
		push @f3, "f3val$i";
		push @f4, "f4val$i";
	}
	eval { $res = $dbh->do("insert into test (field1, field2, field3, field4) values (:f1, :f2, :f3, :f4)") };
	ok((!$@ && $res == 10), 'do() vector insert row into table.');
	diag $@ if $@;

	ok($dbh->commit(), 'commit() successful.');

	my $newestkey;
	eval { $newestkey = $dbh->fetchseq('keyfieldname'); };
	ok(($newestkey==11), 'fetseq() returned last sequence# (11).');

	our @k1 = (qw(4 5 6 7));
	eval { $res = $dbh->do("select field3, field4 into :f3, :f4 from test where keyfield = :k1") };
	ok(($res==4 && $f4[1] eq 'f4val3'), 'do() selected 4 records into vectors based on a 4-element vector.');

	my $csr;
	eval { $csr = $dbh->opencsr("select field3, field4 from test where keyfield = ?") };
	ok($csr, 'opencsr() successfully opened a select cursor.');

	my @res;
	@f3 = ();
	for (my $i=0;$i<=$#k1;$i++) {
		$res = $csr->bind($k1[$i]);
		ok($res, 'bind() succeeded.')  if ($i == $#k1);
		@res = $csr->fetchall();
		if ($i == $#k1) {
			ok((!$#res), 'fetchall() fetched 1 record.');
			ok(($res[0]->[0] eq 'f3val5'), 'fetchall() returned correct values.');
		}
	}
	ok($csr->closecsr(), 'closecsr() successful.');
	
	eval { $csr = $dbh->opencsr("select field3, field4 into :f3, :f4 from test where keyfield = ?") };
	ok($csr, 'opencsr() successfully opened a select cursor.');

	@f3 = ();
	for (my $i=0;$i<=$#k1;$i++) {
		$res = $csr->bind($k1[$i]);
		ok(($res==1), 'bind() succeeded.')  if ($i == $#k1);
		if ($i == $#k1) {
			ok(($f4[0] eq 'f4val5'), 'bind() returned correct vector values.');
		}
	}

	ok $dbh->disconnect();
	my @stat = stat($logfile);
	ok(($stat[7]>=1163), 'Log file successfully created.');
}
done_testing( $number_of_tests_2run );
