use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;
use File::Temp ();
use File::Spec::Functions qw/catfile/;

use Metabase::Archive::SQLite;

has tempdir => (
  is => 'ro',
  isa => 'Object',
  default => sub {
    return File::Temp->newdir;
  },
);

sub _build_archive {
  my $self = shift;
  my $archive = Metabase::Archive::SQLite->new(
    filename => catfile( $self->tempdir, "test" . int(rand(2**31)) ),
  );
  $archive->initialize;
  return $archive;
}

before 'clear_archive' => sub {
  my $self = shift;
  my $dbis = $self->archive->dbis;
  $dbis->query("DROP TABLE " . $self->archive->_table_name . ";");
  return;
};

run_tests(
  "Run Archive tests on Metabase::Archive::SQLite",
  ["main", "Metabase::Test::Archive"]
);

done_testing;
