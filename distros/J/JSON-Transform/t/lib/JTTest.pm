package JTTest;

my @IMPORT;
BEGIN {
@IMPORT = qw(
  strict
  warnings
  Test::More
  Test::Snapshot
);
do { eval "use $_; 1" or die $@ } for @IMPORT;
}

use parent 'Exporter';
use Import::Into;

# nothing yet
our @EXPORT = qw(
);

sub import {
  my $class = shift;
  my $target = caller;
  $class->export_to_level(1);
  $_->import::into(1) for @IMPORT;
}

1;
