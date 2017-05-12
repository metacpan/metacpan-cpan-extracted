use 5.010;
use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;
use Metabase::Test::Index;

use lib 't/lib';

with 'Metabase::Test::Backend::MongoDB';

sub _build_index {
  my $self = shift;
  return Metabase::Index::MongoDB->new(
    db_name => $self->dbname
  );
}

after clear_index => sub {
  my $self = shift;
  $self->mongodb->get_database( $self->dbname )->drop;
};

sub DEMOLISH { my $self = shift; $self->clear_index; }

run_tests(
  "Run Index tests on Metabase::Index::MongodB",
  ["main", "Metabase::Test::Index"],
);

done_testing;
