use strict;
use warnings;

use Class::Load qw/try_load_class/;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

use Metabase::Index::PostgreSQL;

plan skip_all => 'No $ENV{METABASE_TEST_PG_DBNAME}'
  unless $ENV{METABASE_TEST_PG_DBNAME};

plan skip_all => 'DBD::Pg not installed'
  unless try_load_class("DBD::Pg");

sub _build_index {
  my $self = shift;
  my $index = Metabase::Index::PostgreSQL->new(
    db_name => $ENV{METABASE_TEST_PG_DBNAME},
  );
  $index->initialize(
    [ qw/Metabase::Test::Fact/ ],
    [ qw/Metabase::Resource::cpan::distfile/ ],
  );
  return $index;
}

before 'clear_index' => sub {
  my $self = shift;
  my $dbis = $self->index->dbis;
  for my $table ( $self->index->_all_tables ) {
    $dbis->query("DROP TABLE $table;");
  }
  return;
};

run_tests(
  "Run index tests on Metabase::Index::PostgreSQL",
  ["main", "Metabase::Test::Index"]
);

done_testing;
