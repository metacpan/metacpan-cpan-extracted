use strict;
use warnings;

use Benchmark qw(cmpthese);
use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);
use lib "$Bin/../lib";

use GraphQL::Houtou qw(parse parse_with_options);

my $file = 't/kitchen-sink.graphql';
my $count = -5;

GetOptions(
  'file=s'  => \$file,
  'count=s' => \$count,
) or die "Usage: $0 [--file path] [--count Benchmark-count]\n";

open my $fh, '<', $file or die "Failed to open $file: $!";
my $source = do { local $/; <$fh> };

sub run_graphql_perl_default {
  return parse($source);
}

sub run_graphql_perl_noloc {
  return parse_with_options($source, {
    no_location => 1,
  });
}

run_graphql_perl_default();
run_graphql_perl_noloc();

print "Benchmark target: $file\n";
print "Benchmark count: $count\n";

cmpthese($count, {
  graphql_perl_default => \&run_graphql_perl_default,
  graphql_perl_noloc   => \&run_graphql_perl_noloc,
});
