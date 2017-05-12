use 5.010;
use strict;
use warnings;
package Metabase::Test::Backend::MongoDB;

use Test::Routine;

use MongoDB;
use Metabase::Index::MongoDB;
use Metabase::Archive::MongoDB;
use Try::Tiny;

has mongodb => (
  is => 'ro',
  isa => 'MongoDB::Connection',
  lazy_build => 1,
);

has dbname => (
  is => 'ro',
  isa => 'Str',
  default => sub { 'test' . int(rand(2**31)) },
);

sub _build_mongodb {
  my $conn = try{ MongoDB::Connection->new };
  BAIL_OUT("No local mongod running for testing") unless $conn;
  return $conn;
}


1;
