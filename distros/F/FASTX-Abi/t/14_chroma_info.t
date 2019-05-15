use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Abi';
# THIS TEST USES A HETERO CHROMATOGRAM (contains ambiguous bases)
my $chromatogram = "$Bin/../data/hetero.ab1";

if (-e "$chromatogram") {
    my $data = FASTX::Abi->new({ filename => "$chromatogram" });
    my $info = $data->get_trace_info();
    ok( length( $info->{version}) > 0, "Got a string for VERSION");
    ok( length( $info->{instrument}) > 0, "Got a string for INSTRUMENT");
    ok( length( $info->{avg_peak_spacing}) > 0, "Got a string for avg_peak_spacing");
    ok( $info->{avg_peak_spacing} > 1, "Avg_peak_spacing is > 0");
  }




done_testing();
