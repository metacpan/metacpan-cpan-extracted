use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin qw($Bin);
use Capture::Tiny 'capture_stderr';

push @INC, "$Bin/../samples";
$ENV{GDGRAPH_SAMPLES_PATH} = "$Bin/../samples/";

my @samples = glob("$Bin/../samples/sample*.pl");
plan tests => 2 * @samples;

for my $sample (@samples) {
    lives_ok {
        my $stderr = capture_stderr { require $sample };
        my ($sample_name) = $sample =~ m{samples/(sample..)};
        like $stderr, qr/Processing $sample_name/;
    }
}

unlink $_ for glob("sample*.gif");

done_testing();
