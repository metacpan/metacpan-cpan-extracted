#!perl
use strict;
use warnings;


BEGIN
{
    eval "require DBD::SQLite";
    if($@)
    {
	require Test::More;
	Test::More::plan(skip_all=>"DBD::SQLite is required to run these tests.")
    }
}

use Test::More tests => 5;
use Hypatia::DBI;
use DBI;
use Scalar::Util qw(blessed);
use Cwd;
use Path::Class;

my $cwd = getcwd();
my $dir = $ENV{TEMP} ? $ENV{TEMP} : $cwd;

my $file = file($dir,"hypatia_test.db");

unlink $file if -e $file;

open(my $fh,">",$file) or die $!;
close($fh);

my $dbh=DBI->connect("dbi:SQLite:dbname=$file","","");

ok(blessed($dbh) eq 'DBI::db');

$dbh->do("create table dbi_test (x real,y real)") or die $dbh->errstr;


my $dbi = Hypatia::DBI->new({dbh=>$dbh,table=>"dbi_test"});

ok(blessed($dbi) eq 'Hypatia::DBI');
ok(blessed($dbi->dbh) eq 'DBI::db');
ok($dbi->dbh->{Active});

my $query = $dbi->_build_query('x','y');
ok($query =~ /select\s+x,y\s+from\s+dbi_test\s+where\s+x\s+is\s+not\s+null\s+and\s+y\s+is\s+not\s+null\s+group\s+by\s+x,y\s+order\s+by\s+x,y/);
$dbi->dbh->disconnect;