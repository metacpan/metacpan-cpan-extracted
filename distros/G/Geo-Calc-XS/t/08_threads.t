use strict;
use warnings;

use Test::More;
BEGIN {
    my $needed_modules = [ 'threads' ];
    foreach my $module ( @{ $needed_modules } ) {
        eval "use $module";
        if ($@) {
            plan skip_all => join( ', ', @{ $needed_modules } ). " is needed";
        }
    }
}

plan skip_all => "skipping as it's failing threadding tests";

use_ok 'Geo::Calc::XS';

my $sub_lon_ny = sub {
    print Geo::Calc::XS->new(
        lat => 51.490277,
        lon => -0.181274,
    )->distance_to( {
        lat => 40.712778,
        lon => -74.005833, }
    );
};

foreach ( 0..5 ) {
    threads->create( $sub_lon_ny, $_ );
}

foreach ( threads->list() ) {
    $_->join();
}

done_testing();
