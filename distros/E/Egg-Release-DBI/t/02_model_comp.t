use Test::More;
use strict;
use warnings;
use lib qw( ../lib ./lib );
use Egg::Helper;

# $ENV{EGG_DBI_DSN}       = 'dbi:Pg;:dbname=DATABASE';
# $ENV{EGG_DBI_USER}      = 'db_user';
# $ENV{EGG_DBI_PASSWORD}  = 'db_password';
# $ENV{EGG_DBI_TEST_TABLE}= 'egg_release_dbi_test';

eval{ require DBI };
if ($@) {
	plan skip_all=> "DBI is not installed."
} else {
	my $env= Egg::Helper->helper_get_dbi_attr;
	unless ($env->{dsn}) {
		plan skip_all=> "I want setup of environment variable.";
	} else {
		test($env);
	}
}

sub test {

plan tests=> 38;

my($attr)= @_;
$attr->{options}{AutoCommit}= 1;

my $pname= 'DBITEST';
my $tool = Egg::Helper->helper_tools;
my $temp = $tool->helper_tempdir;

my $param= {
  project_name => $pname,
  comp_path => "$temp/$pname/lib/$pname/Model/DBI/Test.pm",
  dbi=> {
    dsn      => $attr->{dsn},
    user     => $attr->{user},
    password => $attr->{password},
    options  => join ",\n",
       map{"'$_' => '$attr->{options}{$_}'"}keys %{$attr->{options}},
    },
  };

$tool->helper_create_file($tool->helper_yaml_load(join '', <DATA>), $param);

my $e= Egg::Helper->run( Vtest => {
  vtest_name=> $pname,
  vtest_root=> "$temp/$pname",
  MODEL=> ['DBI'],
  });

ok my $reg= $e->model_manager->regists, q{my $reg= $e->model_manager->regists};
  ok $reg->{dbi}, q{$reg->{dbi}};
  ok $reg->{'dbi::test'}, q{$reg->{'dbi::test'}};

ok my $dbi= $e->model('dbi'), q{my $dbi= $e->model('dbi')};

my $base= $e->project_name. '::Model::DBI';
my $pkg = "${base}::Test";

can_ok $base, 'default';
  is $base->default, 'dbi::test', q{$base->default, 'dbi::test'};

can_ok $pkg, 'config';
  ok $pkg->config->{dsn}, q{$pkg->config->{dsn}};

ok my $handler= $e->model('dbi::test'), q{my $handler= $e->model('dbi::test')};
  isa_ok $handler, 'Egg::Model::DBI::Base';
  isa_ok $handler, 'Egg::Model';
  isa_ok $handler, 'Egg::Base';
  is $handler, $e->model, q{$handler, $e->model};
  is $handler, $dbi->test, q{$handler, $dbi->test};

can_ok $handler, 'connect_db';

can_ok $handler, 'connect';

can_ok $handler, 'disconnect';

can_ok $handler, 'dbh';
  ok my $dbh= $handler->dbh, q{my $dbh= $handler->dbh};

can_ok $dbi, 'handlers';
  isa_ok $dbi->handlers, 'HASH';
  ok $dbi->handlers->{'dbi::test'}, q{$dbi->handlers->{'dbi::test'}};
  isa_ok $dbi->handlers->{'dbi::test'}, 'Egg::Model::DBI::dbh';
  is $dbi->handlers->{'dbi::test'}, $dbh, q{$dbi->handlers->{'dbi::test'}, $dbh};

my $table= $attr->{table};
eval {

ok $dbh->do(<<"END_ST"), qq{ CREATE TABLE $table };
CREATE TABLE $table (
  id     int2      primary key,
  test   varchar
  );
END_ST

my $result;

ok my $sth= $dbh->prepare(qq{ INSERT INTO $table (id, test) VALUES (?, ?) }),
   q{ INSERT INTO $table (id, test) VALUES (?, ?) };
for my $db ([1, 'foo1'], [2, 'foo2'], [3, 'foo3']) {
	ok $sth->execute(@$db), qq{ \$sth->execute($db) };
}
ok my $count= $dbh->prepare
   (qq{ SELECT count(id) FROM $table }), q{ SELECT count(id) FROM $table };
ok $count->execute, q{ $count->execute };
ok $count->bind_columns(\$result), q{ $count->bind_columns(\$result) };
ok $count->fetch, q{ $count->fetch };
ok $count->finish, q{ $count->finish };
ok $result, q{ $result };
is $result, 3, q{ $result, 3 };

  };

ok $dbh->do(qq{ DROP TABLE $table }), qq{ DROP TABLE $table };

ok $handler->disconnect, q{$handler->disconnect};

}

__DATA__
filename: <e.comp_path>
value: |
  package <e.project_name>::Model::DBI::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::DBI::Base /;
  
  __PACKAGE__->config(
    dsn      => '<e.dbi.dsn>',
    user     => '<e.dbi.user>',
    password => '<e.dbi.password>',
    options  => { <e.dbi.options> },
    );
  
  1;

