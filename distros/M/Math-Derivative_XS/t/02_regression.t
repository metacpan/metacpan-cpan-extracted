use strict;
use warnings;

use Test::More tests => 26;
use FindBin qw();
use YAML::XS qw(LoadFile);

use Math::Derivative_XS qw();
use Math::Derivative qw();

my $data = LoadFile("${FindBin::Bin}/02_regression.yml");
my $derivative2_data = $data->{Derivative2};

my $d2_test_idx = 0;
for my $args (@$derivative2_data) {

    my @xs_res = Math::Derivative_XS::Derivative2(@$args);
    my @pp_res = Math::Derivative::Derivative2(@$args);

    is_deeply(\@xs_res, \@pp_res, "Derivative2 test data index $d2_test_idx");
    $d2_test_idx++;
}
