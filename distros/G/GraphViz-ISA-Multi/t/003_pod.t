# -*- perl -*-

# t/003_pod.t - Test the POD

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::Pod (tests => 1);

my $dir = "$FindBin::RealBin/../lib/GraphViz/ISA";

pod_file_ok( "$dir/Multi.pm", "POD Documentation" );

