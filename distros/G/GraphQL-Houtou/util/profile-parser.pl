use strict;
use warnings;

use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);
use lib "$Bin/../lib";

use GraphQL::Houtou qw(parse_with_options);

my $file = 't/kitchen-sink.graphql';
my $iterations = 200;
my $no_location = 0;

GetOptions(
  'file=s'       => \$file,
  'iterations=i' => \$iterations,
  'no-location!' => \$no_location,
) or die "Usage: $0 [--file path] [--iterations N] [--no-location]\n";

open my $fh, '<', $file or die "Failed to open $file: $!";
my $source = do { local $/; <$fh> };

for (1 .. $iterations) {
  parse_with_options($source, {
    no_location => $no_location,
  });
}

print "profiled parser=graphql-perl-xs no_location=$no_location file=$file iterations=$iterations\n";
