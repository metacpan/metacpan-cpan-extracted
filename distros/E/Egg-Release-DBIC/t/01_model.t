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

plan tests=> 11;

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

my $e= Egg::Helper->run( Vtest => {
  vtest_name=> $p,
  vtest_root=> $root,
  MODEL=> ['DBIC'],
  });

eval{

ok my $model= $e->model('dbic::schema'),
   q{my $model= $e->model('dbic::schema')};
isa_ok $model, "${p}::Model::DBIC::Schema";
isa_ok $model, 'Egg::Model::DBIC::Schema';

ok my $moniker= $e->model('dbic::schema::moniker'),
   q{my $moniker= $e->model('dbic::schema::moniker')};
isa_ok $moniker, 'DBIx::Class::ResultSet';

ok $moniker->create({ id => 1, test => 'OK1' }),
   q{$moniker->create({ id => 1, test => 'OK1' })};
ok $moniker->create({ id => 2, test => 'OK2' }),
   q{$moniker->create({ id => 2, test => 'OK2' })};
ok $moniker->create({ id => 3, test => 'OK3' }),
   q{$moniker->create({ id => 3, test => 'OK3' })};

is $moniker, 3, q{$moniker, 3};

ok my $data= $moniker->search({ id => 2 })->first,
   q{my $data= $moniker->search({ id => 2 })->first};
is $data->test, 'OK2', q{$data->test, 'OK2'};

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

