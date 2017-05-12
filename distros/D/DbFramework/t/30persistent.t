# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;
use t::Config;

BEGIN { plan tests => scalar(@t::Config::drivers) * 12 }

require 't/util.pl';
use DbFramework::Persistent;
use DbFramework::DataModel;
use DbFramework::Table;
use DbFramework::Util;

package Foo;
use base qw(DbFramework::Persistent);

package main;

for ( @t::Config::drivers ) { foo($_) }

sub foo($) {
  my($driver) = @_;

  my($catalog_db,$c_dsn,$c_u,$c_p) = connect_args($driver,'catalog');
  my($test_db,$dsn,$u,$p) = connect_args($driver,'test');

  my $dm  = new DbFramework::DataModel($test_db,$dsn,$u,$p);
  $dm->init_db_metadata($c_dsn,$c_u,$c_p);
  my $dbh     = $dm->dbh; $dbh->{PrintError} = 0;
  my $catalog = new DbFramework::Catalog($c_dsn);
  my $foo     = new Foo($dm->collects_table_h_byname('foo'),$dbh,$catalog);
  ok(1);

  # init
  $foo->table->delete;
  ok(1);

  # insert
  $foo->attributes_h(['foo',0,'bar','bar','baz','baz','quux',0]);
  my $pk = ($driver =~ /(mSQL|Pg)/ ) ? -1 : 1;
  ok($foo->insert,$pk);
  my %foo = ( foo => 0, bar => 'baz', baz => 'baz', quux => 1 );
  $foo->attributes_h([ %foo ]);
  $pk = ($driver =~ /(mSQL|Pg)/ ) ? -1 : 2;
  ok($foo->insert,$pk);
  my @foo = $foo->attributes_h_byname('foo','bar');
  ok($foo[1],$foo{bar});

  # update
  $pk = ($driver =~ /(mSQL|Pg)/ ) ? 0 : 2;
  $foo->attributes_h(['foo',$pk,'bar','baz','baz','quux']);
  my $rows = ($driver =~ /mSQL/ ) ? -1 : 1;
  ok($foo->update,$rows);

  # select
  $foo->attributes_h([]);
  @foo = $foo->select(undef,'bar');
  my @a = $foo[0]->attributes_h_byname('foo','bar');
  $pk = ($driver =~ /(mSQL|Pg)/ ) ? 0 : 1;
  ok("@a","$pk bar");
  @a  = $foo[1]->attributes_h_byname('foo','bar');
  $pk = ($driver =~ /(mSQL|Pg)/ ) ? 0 : 2;
  ok("@a","$pk baz");
  @foo = $foo->select(q{bar like 'b%'},'foo,bar');
  ok(@foo,2);

  # delete
  $rows = ($driver =~ /mSQL/ ) ? -1 : 1;
  ok($foo[0]->delete,$rows);

  # make persistent (sub)class
  my($class,$table) = ('Bar','bar');
  my $ok = qq{package $class;
use strict;
use base qw(DbFramework::Persistent);
};
  ok(DbFramework::Persistent->make_class($class),$ok);
  eval $ok;
  my $bar = $class->new($dm->collects_table_h_byname($table),$dbh,$catalog);
  ok($bar->table->name,$table);
}
