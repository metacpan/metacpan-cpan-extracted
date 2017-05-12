#!perl
#
# $Id$

use strict;

package My_Growth_Test;

require Test::More;

sub run_data_tests {
    my $measure_class_handle = shift;
    my $callpkg              = caller(0);
    my $fh                   = do { no strict 'refs'; \*{"${callpkg}::DATA"}; };

    # We test value_for_pct and pct_for_value only
    # because they subsume the z-score variants
    while (<$fh>) {
        next if /^(?:#.*|\s*)$/;
        my ( $age, $pctile, $value ) = split;
        my $p = $measure_class_handle->pct_for_value( $value, $age );
        $p = $pctile if abs( $pctile - $p ) < 0.1;
        Test::More::is( $p, $pctile,
            "pct_for_value: age: $age, pct: $pctile, value: $value" );

        my $v = $measure_class_handle->value_for_pct( $pctile, $age );
        $v = $value if abs( $value - $v ) < 0.01;
        Test::More::is( $v, $value,
            "value_for_pct: age: $age, value: $value, pct: $pctile" );
    }

}

1;
