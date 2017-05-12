use 5.010;
use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;
use Test::Fatal;
use File::Temp ();
use File::Spec::Functions qw/catfile/;
use SQL::Translator;

use lib "t/lib";

use Metabase::Index::SQLite;

with 'Metabase::Test::Index::SQLite';

has index => (
  is => 'ro',
  does => 'Metabase::Index',
  lazy_build => 1,
);

sub _build_index {
  my $self = shift;
  my $index = Metabase::Index::SQLite->new(
    filename => catfile( $self->tempdir, "test" . int(rand(2**31)) ),
  );
#  $index->initialize;
  return $index;
}

test "core only init" => sub {
  my $self = shift;
  $self->clear_index;
  is( exception {$self->index->initialize}, undef, "init core only didn't die" );

#  my $existing = SQL::Translator->new(
#    parser => 'DBI',
#    parser_args => {
#      dsn => "dbi:SQLite:dbname=" . $self->index->filename,
#    },
#    producer => 'YAML',
#  );
#  say $existing->translate();

  is( exception {$self->index->initialize}, undef, "repeat init didn't die" );
};

test "init with facts" => sub {
  my $self = shift;
  $self->clear_index;
  my @classes = qw(
    Metabase::Test::Fact
    Metabase::User::Profile
  );
  is(
    exception { $self->index->initialize(\@classes) },
    undef,
    "init core + classes didn't die"
  );
};

#  my @resources = qw(
#    Metabase::Resource::cpan::distfile
#    Metabase::Resource::metabase::user
#  );

run_me;

done_testing;
