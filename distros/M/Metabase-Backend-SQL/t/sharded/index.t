use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;
use File::Temp ();
use File::Spec::Functions qw/catfile/;

use Metabase::Index::SQLite::Sharded;

use lib 't/lib';

with 'Metabase::Test::Index::SQLite';

sub _build_index {
  my $self = shift;
  my $index = Metabase::Index::SQLite::Sharded->new(
    filename => catfile( $self->tempdir, "test-metabase.sqlite" ),
    shard_digits => 1,
  );
#  diag "Initializing index shards (please wait)";
  $index->initialize(
    [ qw/Metabase::Test::Fact/ ],
    [ qw/Metabase::Resource::cpan::distfile/ ],
  );
  return $index;
}

after 'clear_index' => sub { shift->clear_tempdir };

run_tests(
  "Run index tests on Metabase::Index::SQLite::Sharded",
  ["main", "Metabase::Test::Index"]
);

done_testing;
