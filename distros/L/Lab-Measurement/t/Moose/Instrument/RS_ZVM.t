#!perl
use warnings;
use strict;
use 5.010;

use lib 't';

use PDL::Ufunc qw/any all/;

use Lab::Test import => [qw/is_absolute_error is_pdl/];
use Test::More;
use Moose::Instrument::MockTest 'mock_instrument';
use aliased 'Lab::Moose::Instrument::RS_ZVM';
use File::Spec::Functions 'catfile';

my $log_file = catfile(qw/t Moose Instrument RS_ZVM.yml/);

my $zvm = mock_instrument(
    type     => 'RS_ZVM',
    log_file => $log_file
);

isa_ok( $zvm, 'Lab::Moose::Instrument::RS_ZVM' );

$zvm->rst( timeout => 10 );
my $catalog = $zvm->sparam_catalog();
is_deeply(
    $catalog, [ 'Re(S11)', 'Im(S11)' ],
    "reflection param in catalog"
);

$zvm->sense_sweep_points( value => 3 );

for my $i ( 1 .. 3 ) {
    my $data = $zvm->sparam_sweep( timeout => 10 );

    is_deeply( [ $data->dims() ], [ 3, 3 ], "data PDL is 3x3 array" );

    my $freqs = $data->slice(":, 0");

    is_pdl(
        $freqs, [ [ 10000000, 10005000000, 20000000000 ] ],
        "first column holds frequencies"
    );

    my $re = $data->slice(":,1");
    my $im = $data->slice(":,2");
    for my $pdl ( $re, $im ) {
        ok(
            all( abs($pdl) < 1.1 ),
            "real or imaginary part of s-param is in [-1.1,1.1]"
        ) || diag("pdl: $pdl");
    }
}

done_testing();
