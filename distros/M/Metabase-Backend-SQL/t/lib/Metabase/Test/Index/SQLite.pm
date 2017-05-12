use strict;
use warnings;
package Metabase::Test::Index::SQLite;

use Test::More;
use Test::Routine;
use Test::Routine::Util;
use File::Temp ();
use File::Spec::Functions qw/catfile/;

use Metabase::Index::SQLite;

has tempdir => (
  is => 'ro',
  isa => 'Any',
  lazy_build => 1,
);

sub _build_tempdir {
#    "$ENV{HOME}/tmp",
    return File::Temp->newdir;
}

1;
