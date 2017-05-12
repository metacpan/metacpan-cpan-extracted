use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;
use DBI;

# $ENV{EGG_DBI_DSN}       = 'dbi:Pg;:dbname=DATABASE';
# $ENV{EGG_DBI_USER}      = 'db_user';
# $ENV{EGG_DBI_PASSWORD}  = 'db_password';
# $ENV{EGG_DBI_TEST_TABLE}= 'egg_release_dbi_test';

;my $attr= Egg::Helper->helper_get_dbi_attr;
unless ($attr->{dsn})
  { plan skip_all=> "I want setup of environment variable." } else {

plan tests=> 23;

my $p   = 'DBITEST';
my $tool= Egg::Helper->helper_tools;
my $temp= $tool->helper_tempdir;
my $root= "$temp/$p";

$tool->helper_create_files(
  [ $tool->helper_yaml_load(join '', <DATA>) ],
  { root=> $root, project_name=> $p, dbi=> $attr },
  );

$attr->{options}= { AutoCommit=> 1 };
my $table= $attr->{table};
my $dbh= DBI->connect(@{$attr}{qw/ dsn user pasword options /});

$dbh->do(<<"END_ST");
CREATE TABLE $table (
  id     int2      primary key,
  test   varchar
  );
END_ST

eval{

my $e= Egg::Helper->run( Vtest => {
  vtest_name=> $p,
  vtest_root=> $root,
  vtest_plugins=> [qw/ DBIC /],
  MODEL=> ['DBIC'],
  });

can_ok $e, 'commit_ok';
  ok $e->commit_ok( schema=> 1 ),  q{$e->commit_ok( schema=> 1 )};
  ok $e->commit_ok('schema'), q{$e->commit_ok('schema')};
  ok ! $e->commit_ok( schema => 0 ), q{! $e->commit_ok( schema => 0 )};
  ok ! $e->commit_ok('schema'), q{! $e->commit_ok('schema')};

can_ok $e, 'rollback_ok';
  ok $e->rollback_ok( schema=> 1 ),  q{$e->rollback_ok( schema=> 1 )};
  ok $e->rollback_ok('schema'), q{$e->rollback_ok('schema')};
  ok ! $e->rollback_ok( schema => 0 ), q{! $e->rollback_ok( schema => 0 )};
  ok ! $e->rollback_ok('schema'), q{! $e->rollback_ok('schema')};

can_ok $e, 'dbh';
  ok my $dbh= $e->dbh('schema'), q{my $dbh= $e->dbh('schema')};
  ok my $handlers= $e->dbh, q{my $handlers= $e->dbh};
  isa_ok $handlers, 'ARRAY';
  is $dbh, $handlers->[0], q{$dbh, $handlers->[0]};

can_ok $e, "schema_schema";
  ok my $schema= $e->schema_schema, q{my $schema= $e->schema_schema};
  isa_ok $schema, "${p}::Model::DBIC::Schema";

can_ok $e, 'commit_schema';

can_ok $e, 'rollback_schema';

can_ok $e, 'begin_schema';

can_ok $e, 'dbic_finalize_error';

can_ok $e, 'dbic_finish';

  };

$@ and warn $@;

$dbh->do("DROP TABLE $table");
$dbh->disconnect;

}

__DATA__
---
filename: <e.root>/lib/<e.project_name>/Model/DBIC/Schema.pm
value: |
  package <e.project_name>::Model::DBIC::Schema;
  use strict;
  use warnings;
  use base qw/ Egg::Model::DBIC::Schema /;
  
  our $VERSION = '0.01';
  
  __PACKAGE__->config(
    dsn      => '<e.dbi.dsn>',
    user     => '<e.dbi.user>',
    password => '<e.dbi.password>',
    options  => { AutoCommit => 1, RaiseError=> 1 },
    );
  
  __PACKAGE__->load_classes;
  
  1;
---
filename: <e.root>/lib/<e.project_name>/Model/DBIC/Schema/Moniker.pm
value: |
  package <e.project_name>::Model::DBIC::Schema::Moniker;
  use strict;
  use warnings;
  use base qw/ DBIx::Class /;
  
  our $VERSION = '0.01';
  
  __PACKAGE__->load_components("PK::Auto", "Core");
  __PACKAGE__->table("<$e.dbi.table>");
  __PACKAGE__->add_columns(
    "id", {
      data_type   => "smallint",
      is_nullable => 0,
      },
    "test", {
      data_type     => "character varying",
      default_value => undef,
      is_nullable   => 0,
      },
   );
  
  1;

