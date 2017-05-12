# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;
use t::Config;
require 't/util.pl';

BEGIN { plan tests => scalar(@t::Config::drivers) * 4 + 1 }

use DbFramework::Template;
ok(1);
use DbFramework::DataModel;

for ( @t::Config::drivers ) { foo($_) }

sub foo($) {
  my $driver = shift;

  my($catalog_db,$c_dsn,$c_u,$c_p) = connect_args($driver,'catalog');
  my($test_db,$dsn,$u,$p) = connect_args($driver,'test');

  my $dm  = new DbFramework::DataModel($test_db,$dsn,$u,$p);
  $dm->init_db_metadata($c_dsn,$c_u,$c_p);
  my $dbh = $dm->dbh; $dbh->{PrintError} = 0;

  my $t  = new DbFramework::Template("(:&db_value(foo.bar):)",
				     $dm->collects_table_l);
  ok(1);

  my $filling = 'bar';
  ok($t->fill({'foo.bar' => $filling}),$filling);

  $t->template->text("(:&db_html_form_field(foo.bar,,int):)");
  my $ok = '<INPUT NAME="bar" VALUE="" SIZE=10 TYPE="text">';
  ok($t->fill,$ok);

  $t->template->text("(:&db_fk_html_form_field(bar.f_foo):)");
  if ( $driver =~ /(mSQL|Pg)/ ) {
    $ok = qq{<SELECT NAME="foo_foo,foo_bar">
<OPTION  VALUE="">** Any Value **
<OPTION  VALUE="NULL">NULL
<OPTION  VALUE="0,baz">baz
</SELECT>
};
  } else {
    $ok = qq{<SELECT NAME="foo_foo,foo_bar">
<OPTION  VALUE="">** Any Value **
<OPTION  VALUE="NULL">NULL
<OPTION  VALUE="2,baz">baz
</SELECT>
};
  }
  ok($t->fill,$ok);
}
