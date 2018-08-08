use strict;
use Test::More 0.98;
use Test::Snapshot;
use SQL::Translator;
use File::Spec;

sub do_test {
  my ($parser) = @_;
  my $t = SQL::Translator->new();
  $t->parser($parser);
  $t->filename(File::Spec->catfile('t', 'schema', lc "$parser.sql")) or die $t->error;
  $t->producer('GraphQL');
  my $result = $t->translate or die $t->error;
  is_deeply_snapshot $result, 'schema';
}

for my $type (qw(MySQL SQLite)) {
  do_test($type);
}

done_testing;
