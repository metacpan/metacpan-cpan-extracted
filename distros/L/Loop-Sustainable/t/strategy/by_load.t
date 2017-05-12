use strict;
use warnings;

use Test::More;
use Loop::Sustainable::Strategy::ByLoad;

sub create_strategy {
    return Loop::Sustainable::Strategy::ByLoad->new(@_);
}

subtest 'check_strategy_interval: 1; load: 0.1' => sub {
    my $strategy = create_strategy( load => 0.1, check_strategy_interval => 1, );
    is( $strategy->wait_correction( 1, 10, [] ), 90, 'elapsed: 10, wait_time: 90' );
    is( $strategy->wait_correction( 1, 3,  [] ), 27, 'elapsed: 3, wait_time: 27' );
};

subtest 'check_strategy_interval: 10; load: 0.1' => sub {
    my $strategy = create_strategy( load => 0.1, check_strategy_interval => 10, );
    is( $strategy->wait_correction( 1, 10, [] ), 9, 'elapsed: 10, wait_time: 9' );
    is( $strategy->wait_correction( 1, 3,  [] ), 2.7, 'elapsed: 3, wait_time: 2.7' );
};

subtest 'check_strategy_interval: 1; load: 0.5' => sub {
    my $strategy = create_strategy( load => 0.5, check_strategy_interval => 1, );
    is( $strategy->wait_correction( 1, 10, [] ), 10, 'elapsed: 10, wait_time: 10' );
    is( $strategy->wait_correction( 1, 3,  [] ), 3, 'elapsed: 3, wait_time: 3' );
};

subtest 'check_strategy_interval: 10; load: 0.5' => sub {
    my $strategy = create_strategy( load => 0.5, check_strategy_interval => 10, );
    is( $strategy->wait_correction( 1, 10, [] ), 1, 'elapsed: 10, wait_time: 1' );
    is( $strategy->wait_correction( 1, 3,  [] ), 0.3, 'elapsed: 3, wait_time: 0.3' );
};

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
