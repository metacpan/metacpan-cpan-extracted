use strict;
use warnings;

use Test::More tests => 4;

use FindBin;
use Path::Tiny qw(path);
use MetaPOD::Extractor;

my $corpus = path($FindBin::Bin)->parent->parent->child('corpus')->child('basic');

my ($expected) = {
  '01_format_basic.pm' => {
    format     => 'Test::Basic',
    data       => qq{Test Data\n},
    start_line => 4,
  },
  '02_format_basic_version.pm' => {
    format     => 'Test::Basic',
    data       => qq{Test Data\n},
    version    => 'v0.1',
    start_line => 4,
  },
  '03_format_basic_for.pm' => {
    format     => 'Test::Basic',
    data       => qq{Test Data\n},
    start_line => 4,
  },
  '04_format_basic_for_version.pm' => {
    format     => 'Test::Basic',
    data       => qq{Test Data\n},
    version    => 'v0.1',
    start_line => 4,
  },
};

for my $child ( $corpus->children ) {
  my $expected_data = $expected->{ $child->basename };
  my $extractor     = MetaPOD::Extractor->new();
  $extractor->read_file( $child->stringify );
  my $result = $extractor->segments;
  is_deeply( $result, [$expected_data], $child->basename );
}
