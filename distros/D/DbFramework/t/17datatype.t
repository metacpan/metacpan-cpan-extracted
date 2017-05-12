# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;
use t::Config;

BEGIN { 
  my $tests;
  my %tests = ( 'mSQL' => 1, 'mysql' => 3, 'Pg' => 0 );
  for ( @t::Config::drivers ) { $tests += $tests{$_}; }
  plan tests => $tests;
}

require 't/util.pl';
use DbFramework::DataType::ANSII;
use DbFramework::DataType::Mysql;
use DbFramework::Util;
use DbFramework::DataModel;

for ( @t::Config::drivers ) { foo($_) }

sub foo($) {
  my $driver = shift;

  my($catalog_db,$c_dsn,$c_u,$c_p) = connect_args($driver,'catalog');
  my($test_db,$dsn,$u,$p) = connect_args($driver,'test');
  my $dm = new DbFramework::DataModel($test_db,$dsn,$u,$p);
  $dm->init_db_metadata($c_dsn,$c_u,$c_p);
  my $dbh = $dm->dbh; $dbh->{PrintError} = 0;
  my $t = $dm->collects_table_h_byname('foo');

  my $dt;

  if ( $driver eq 'mSQL' ) {
    # mapping of mSQL => ANSII types
    ok($t->as_sql,'CREATE TABLE foo (
	foo INT(4) NOT NULL,
	bar CHAR(10) NOT NULL,
	baz CHAR(10),
	quux INT(4),
	foobar TEXT(10),
	PRIMARY KEY (foo,bar),
	KEY foo (bar,baz),
	KEY bar (baz,quux)
)');
  } elsif ( $driver eq 'mysql' ) {    
    # mapping of Mysql => ANSII types
    ok($t->as_sql,'CREATE TABLE foo (
	foo INTEGER UNSIGNED(11) NOT NULL AUTO_INCREMENT,
	bar VARCHAR(10) NOT NULL,
	baz VARCHAR(10) NOT NULL,
	quux INTEGER UNSIGNED(11) NOT NULL,
	foobar TEXT(65535),
	PRIMARY KEY (foo,bar),
	KEY bar (baz,quux),
	KEY foo (bar,baz)
)');

    # valid Mysql type
    my $mdt = new DbFramework::DataType::Mysql($dm,253,12,50);
    ok($mdt->name,'VARCHAR');
    
    # invalid Mysql type
    $mdt = eval { new DbFramework::DataType::Mysql($dm,69,12,undef) };
    ok($@,'Invalid Mysql data type: 69
');
  }

  $dbh->disconnect;
}
