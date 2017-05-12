use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;
use File::Temp ();
use File::Spec::Functions qw/catfile/;
use Path::Class;

use Metabase::Archive::SQLite::Sharded;

has tempdir => (
  is => 'ro',
  isa => 'Object',
  default => sub {
    return File::Temp->newdir;
  },
);

sub _build_archive {
  my $self = shift;
  my $archive = Metabase::Archive::SQLite::Sharded->new(
    filename => catfile( $self->tempdir, "test" . int(rand(2**31)) ),
  );
  $archive->initialize;
  return $archive;
}

after 'clear_archive' => sub {
  my $self = shift;
  my $db_dir = dir( $self->tempdir );
  $_->remove for $db_dir->children;
  return;
};

run_tests(
  "Run Archive tests on Metabase::Archive::SQLite::Sharded",
  ["main", "Metabase::Test::Archive"]
);

done_testing;
