use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Requires qw(
  DBI
  DBD::Mock
);

use DBI;
use DBD::Mock;
use Loop::Sustainable::Strategy::MySQL::BalancedReplication;

sub create_strategy {
    return Loop::Sustainable::Strategy::MySQL::BalancedReplication->new(@_);
}

subtest 'check_strategy_interval: 1, capable_behind_seconds: 5; on_error_scale_factor: 5; Seconds_Behind_Master: 10' => sub {
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    $dbh->{mock_add_resultset} = +{
        sql => 'SHOW SLAVE STATUS',
        results => [
            [ qw/Seconds_Behind_Master/ ],
            [ 10 ]
        ],
    };

    my $strategy = create_strategy(
        dbh => $dbh,
        check_strategy_interval => 1,
        capable_behind_seconds => 5,
        on_error_scale_factor => 5,
        on_error_croak => 0,
    );

    is( $strategy->wait_correction( 1, 10, [] ), 5, 'elapsed: 10, wait_time: 5' );
    is( $strategy->wait_correction( 1, 3,  [] ), 5, 'elapsed: 3, wait_time: 5' );
};

subtest 'check_strategy_interval: 10, capable_behind_seconds: 5; on_error_scale_factor: 5; Seconds_Behind_Master: 10' => sub {
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    $dbh->{mock_add_resultset} = +{
        sql => 'SHOW SLAVE STATUS',
        results => [
            [ qw/Seconds_Behind_Master/ ],
            [ 10 ]
        ],
    };

    my $strategy = create_strategy(
        dbh => $dbh,
        check_strategy_interval => 10,
        capable_behind_seconds => 5,
        on_error_scale_factor => 5,
        on_error_croak => 0,
    );

    is( $strategy->wait_correction( 1, 10, [] ), 0.5, 'elapsed: 10, wait_time: 0.5' );
    is( $strategy->wait_correction( 1, 3,  [] ), 0.5, 'elapsed: 3, wait_time: 0.5' );
};

subtest 'check_strategy_interval: 10, capable_behind_seconds: 15; on_error_scale_factor: 5; Seconds_Behind_Master: 10' => sub {
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    $dbh->{mock_add_resultset} = +{
        sql => 'SHOW SLAVE STATUS',
        results => [
            [ qw/Seconds_Behind_Master/ ],
            [ 10 ]
        ],
    };

    my $strategy = create_strategy(
        dbh => $dbh,
        check_strategy_interval => 10,
        capable_behind_seconds => 15,
        on_error_scale_factor => 5,
        on_error_croak => 0,
    );

    is( $strategy->wait_correction( 1, 10, [] ), 0, 'elapsed: 10, wait_time: 0' );
    is( $strategy->wait_correction( 1, 3,  [] ), 0, 'elapsed: 3, wait_time: 0' );
};

subtest 'check_strategy_interval: 10, capable_behind_seconds: 10; on_error_scale_factor: 5; Seconds_Behind_Master: undef' => sub {
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    $dbh->{mock_add_resultset} = +{
        sql => 'SHOW SLAVE STATUS',
        results => [
            [ qw/Seconds_Behind_Master/ ],
            [ undef ]
        ],
    };

    my $strategy = create_strategy(
        dbh => $dbh,
        check_strategy_interval => 10,
        capable_behind_seconds => 10,
        on_error_scale_factor => 5,
        on_error_croak => 0,
    );

    is( $strategy->wait_correction( 1, 10, [] ), 4, 'elapsed: 10, wait_time: 4' );
    is( $strategy->wait_correction( 1, 3,  [] ), 4, 'elapsed: 3, wait_time: 4' );
};

subtest 'check_strategy_interval: 10, capable_behind_seconds: 10; on_error_scale_factor: 5; Seconds_Behind_Master: undef, on_error_croak: 0' => sub {
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    $dbh->{mock_add_resultset} = +{
        sql => 'SHOW SLAVE STATUS',
        results => DBD::Mock->NULL_RESULTSET,
        failure => [ 5, 'Mock error' ],
    };

    my $strategy = create_strategy(
        dbh => $dbh,
        check_strategy_interval => 10,
        capable_behind_seconds => 10,
        on_error_scale_factor => 5,
        on_error_croak => 0,
    );

    is( $strategy->wait_correction( 1, 10, [] ), 4, 'elapsed: 10, wait_time: 4' );
    is( $strategy->wait_correction( 1, 3,  [] ), 4, 'elapsed: 3, wait_time: 4' );
};

subtest 'check_strategy_interval: 10, capable_behind_seconds: 10; on_error_scale_factor: 5; Seconds_Behind_Master: undef, on_error_croak: 1' => sub {
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    $dbh->{mock_add_resultset} = +{
        sql => 'SHOW SLAVE STATUS',
        results => DBD::Mock->NULL_RESULTSET,
        failure => [ 5, 'Mock error' ],
    };

    my $strategy = create_strategy(
        dbh => $dbh,
        check_strategy_interval => 10,
        capable_behind_seconds => 10,
        on_error_scale_factor => 5,
        on_error_croak => 1,
    );

    dies_ok { $strategy->wait_correction( 1, 10, [] ) } 'wait_correction() dies ok';
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
