use 5.010;
use strict;
use warnings;

use Class::Load qw/try_load_class/;
use Test::More;
use Test::Routine;
use Test::Routine::Util;
use Test::Fatal;
use File::Temp ();
use File::Spec::Functions qw/catfile/;
use SQL::Translator;

use Metabase::Index::PostgreSQL;

plan skip_all => 'No $ENV{METABASE_TEST_PG_DBNAME}'
  unless $ENV{METABASE_TEST_PG_DBNAME};

plan skip_all => 'DBD::Pg not installed'
  unless try_load_class("DBD::Pg");

has index => (
  is => 'ro',
  does => 'Metabase::Index',
  lazy_build => 1,
);

sub _build_index {
  my $self = shift;
  my $index = Metabase::Index::PostgreSQL->new(
    db_name => $ENV{METABASE_TEST_PG_DBNAME},
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
#      dsn => "dbi:Pg:dbname=" . $ENV{METABASE_TEST_PG_DBNAME},
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

test "init with resources" => sub {
  my $self = shift;
  $self->clear_index;
  my @resources = qw(
    Metabase::Resource::cpan::distfile
    Metabase::Resource::metabase::user
  );
  is(
    exception { $self->index->initialize(undef, \@resources) },
    undef,
    "init core + resources didn't die"
  );
};


test "full init" => sub {
  my $self = shift;
  $self->clear_index;
  my @classes = qw(
    Metabase::Test::Fact
    Metabase::User::Profile
  );
  my @resources = qw(
    Metabase::Resource::cpan::distfile
    Metabase::Resource::metabase::user
  );
  is(
    exception { $self->index->initialize(\@classes, \@resources) },
    undef,
    "init core + classes + resources didn't die"
  );
};

run_me;

done_testing;
