use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin qw($Bin);
use Capture::Tiny 'capture_stderr';

push @INC, "$Bin/../samples";
$ENV{GDGRAPH_SAMPLES_PATH} = "$Bin/../samples/";

my @samples = glob("$Bin/../samples/sample*.pl");
my $test_count = 2 * @samples;
plan tests => $test_count;


# Check for known GD error message when libgd has image support disabled
use GD::Graph::bars;
my $graph = GD::Graph::bars->new;
eval {
    capture_stderr { $graph->export_format };
};

my $skip;
if ( $@ and $@ =~ /gdImageGdPtr/ ) {
    $skip = 1;
}

SKIP: {
    skip "GD image support has been disabled in installed libgd, skipping", $test_count if $skip;
    for my $sample (@samples) {
        lives_ok {
            my $stderr = capture_stderr { require $sample };
            my ($sample_name) = $sample =~ m{samples/(sample..)};
            like $stderr, qr/Processing $sample_name/;
        }
    }

    unlink $_ for glob("sample*.gif");
}


done_testing();
