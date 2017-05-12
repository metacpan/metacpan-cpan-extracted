# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;
use t::Config;

BEGIN { plan tests => scalar(@t::Config::drivers) * 5 }

require 't/util.pl';
use DbFramework::Catalog;
use DbFramework::Util;
use DbFramework::DataModel;
use DbFramework::Table;

my($t1,$t2);

for my $driver ( @t::Config::drivers ) {
  if ( $driver eq 'mSQL' ) {
    $t1 = qq{CREATE TABLE foo (foo integer not null,
			       bar char(10) not null,
			       baz char(10),
			       quux integer,
			       foobar text(10)
			      )};
    $t2 = qq{CREATE TABLE bar (foo integer not null,
			       # foreign key (foo)
			       foo_foo integer,
			       foo_bar char(10),
			       bar integer
			      )};
  } elsif ( $driver eq 'mysql' ) {
    $t1 = qq{CREATE TABLE foo (foo integer not null auto_increment,
			       bar varchar(10) not null,
			       baz varchar(10) not null,
			       quux integer not null,
			       foobar text,
			       KEY foo(bar,baz),
			       KEY bar(baz,quux),
			       PRIMARY KEY (foo,bar)
			      )};
    $t2 = qq{CREATE TABLE bar (foo integer not null auto_increment,
			       # foreign key (foo)
			       foo_foo integer not null,
			       foo_bar varchar(10) not null,
			       bar integer,
			       KEY f_foo(foo_foo,foo_bar),
			       PRIMARY KEY (foo)
			      )};
  }  elsif ( $driver eq 'Pg' ) {
    $t1 = qq{CREATE TABLE foo (foo integer not null,
			       bar varchar(10) not null,
			       baz varchar(10) not null,
			       quux integer not null,
			       foobar text,
			       UNIQUE(bar,baz),
			       UNIQUE(baz,quux),
			       PRIMARY KEY (foo,bar)
			      )};
    $t2 = qq{CREATE TABLE bar (foo integer not null,
			       -- foreign key (foo)
			       foo_foo integer not null,
			       foo_bar varchar(10) not null,
			       bar integer,
			       UNIQUE(foo_foo,foo_bar),
			       PRIMARY KEY (foo)
			      )};
  } elsif ( $driver eq 'Sybase' ) {
    $t1 = qq{CREATE TABLE foo (foo numeric(10,0) identity not null,
			       bar varchar(10) not null,
			       baz varchar(10) not null,
			       quux integer not null,
			       foobar text,
			       UNIQUE (bar,baz),
			       UNIQUE (baz,quux),
			       PRIMARY KEY (foo,bar)
			      )};
    $t2 = qq{CREATE TABLE bar (foo numeric(10,0) identity not null,
			       -- foreign key (foo)
			       foo_foo integer not null,
			       foo_bar varchar(10) not null,
			       bar integer,
			       UNIQUE (foo_foo,foo_bar),
			       PRIMARY KEY (foo)
			      )};
  } elsif ( $driver eq 'CSV' ) {
    $t1 = qq{CREATE TABLE foo (foo integer,
			       bar varchar(10),
			       baz varchar(10),
			       quux integer,
			       foobar varchar(255)
			      )};
    $t2 = qq{CREATE TABLE bar (foo integer,
			       foo_foo integer,
			       foo_bar varchar(10),
			       bar integer
			      )};
  } else { # ODBC syntax for auto increment is IDENTITY(seed,increment)
    $t1 = qq{CREATE TABLE foo (foo integer not null identity(0,1),
			       bar varchar(10) not null,
			       baz varchar(10) not null,
			       quux integer not null,
			       foobar text,
			       KEY foo(bar,baz),
			       KEY bar(baz,quux),
			       PRIMARY KEY (foo,bar)
			      )};
    $t2 = qq{CREATE TABLE bar (foo integer not null identity(0,1),
			       # foreign key (foo)
			       foo_foo integer not null,
			       foo_bar varchar(10) not null,
			       bar integer,
			       KEY f_foo(foo_foo,foo_bar),
			       PRIMARY KEY (foo)
			      )};
  }
  foo($driver,'foo',$t1,'bar',$t2);
}

sub foo($$$$$) {
  my($driver,$t1,$t1_sql,$t2,$t2_sql) = @_;

  my($catalog_db,$c_dsn,$c_u,$c_p) = connect_args($driver,'catalog');
  my($test_db,$dsn,$u,$p) = connect_args($driver,'test');

  my $c = new DbFramework::Catalog($c_dsn,$c_u,$c_p);
  ok(1);

  my $dbh = DbFramework::Util::get_dbh($dsn,$u,$p);
  $dbh->{PrintError} = 0; # don't warn about dropping non-existent tables
  drop_create($test_db,$t1,undef,$t1_sql,$dbh);
  drop_create($test_db,$t2,undef,$t2_sql,$dbh);
  my $dm = new DbFramework::DataModel($test_db,$dsn,$u,$p);
  $dm->init_db_metadata($c_dsn,$c_u,$c_p);

  # test primary keys
  my $foo_table = $dm->collects_table_h_byname('foo');
  ok($foo_table->is_identified_by->as_sql,'PRIMARY KEY (foo,bar)');

  # test keys
  my @keys = @{$foo_table->is_accessed_using_l};
  my($bar,$foo);
  if ( $driver eq 'mSQL' ) {
    ($bar,$foo) = (1,0);
  } else {
    ($bar,$foo) = (0,1);
  }
  ok($keys[$bar]->as_sql,'KEY bar (baz,quux)');
  ok($keys[$foo]->as_sql,'KEY foo (bar,baz)');

  # test foreign keys
  my $bar_table = $dm->collects_table_h_byname('bar');
  my $fk = $bar_table->has_foreign_keys_h_byname('f_foo');
  ok($fk->as_sql,'KEY f_foo (foo_foo,foo_bar)');

  $dbh->disconnect;
}
