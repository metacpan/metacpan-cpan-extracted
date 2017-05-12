use 5.010;
use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;
use Metabase::Test::Archive;

use lib 't/lib';

with 'Metabase::Test::Backend::MongoDB';

sub _build_archive {
  my $self = shift;
  return Metabase::Archive::MongoDB->new(
    db_name => $self->dbname
  );
}

after clear_archive => sub {
  my $self = shift;
  $self->mongodb->get_database( $self->dbname )->drop;
};

sub DEMOLISH { my $self = shift; $self->clear_archive; }

run_tests(
  "Run Archive tests on Metabase::Archive::MongodB",
  ["main", "Metabase::Test::Archive"],
);

done_testing;
