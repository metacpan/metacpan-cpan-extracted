use Test::More tests => 9;

use File::Spec;

my @classes;
BEGIN {
  @classes = qw/
    IRC::Indexer::Output::JSON
    IRC::Indexer::Output::YAML
    IRC::Indexer::Output::Dumper
  /;
  
  use_ok($_) for @classes;
}

for my $class (@classes) {
  my $obj = new_ok( $class => [ Input => {} ] );
  can_ok( $obj, qw/dump write/);
}
