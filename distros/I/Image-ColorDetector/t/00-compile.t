use strict;
use Test::More tests => 1;
use FindBin;

my $base_dir;
BEGIN { $base_dir = "$FindBin::Bin/.." }
use lib "$base_dir/lib";

use_ok $_ for qw(
    Image::ColorDetector
);

done_testing;

