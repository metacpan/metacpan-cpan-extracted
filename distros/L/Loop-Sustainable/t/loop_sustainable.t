use strict;
use warnings;

use Test::More;
use Test::Requires qw(
  DBI
  DBD::Mock
);

use DBI;
use List::Util qw(sum);
use Time::HiRes;
use Loop::Sustainable;

subtest 'strategy: ByLoad' => sub {
    my %expected_wait_interval = (
        1  => 0.1,
        2  => 0.1,
        3  => 0.1,
        4  => 0.1 + ( 1 + 2 + 3 ) * 0.01 / 3,
        5  => 0.1 + ( 1 + 2 + 3 ) * 0.01 / 3,
        6  => 0.1 + ( 1 + 2 + 3 ) * 0.01 / 3,
        7  => 0.1 + ( 4 + 5 + 6 ) * 0.01 / 3,
        8  => 0.1 + ( 4 + 5 + 6 ) * 0.01 / 3,
        9  => 0.1 + ( 4 + 5 + 6 ) * 0.01 / 3,
        10 => 0.1 + ( 7 + 8 + 9 ) * 0.01 / 3,
        11 => 0.1 + ( 7 + 8 + 9 ) * 0.01 / 3,
        12 => 0.1 + ( 7 + 8 + 9 ) * 0.01 / 3,
        13 => 0.1 + ( 10 + 11 + 12 ) * 0.01 / 3,
        14 => 0.1 + ( 10 + 11 + 12 ) * 0.01 / 3,
        15 => 0.1 + ( 10 + 11 + 12 ) * 0.01 / 3,
    );

    my $result = loop_sustainable(
        sub {
            my ( $execute_count, $wait_interval ) = @_;

            cmp_ok $wait_interval, '>=',
              $expected_wait_interval{$execute_count},
              sprintf(
                  'executed_count: %d; got_wait_interval: %.3f, expected_wait_interval: %.3f',
                  $execute_count, $wait_interval,
                  $expected_wait_interval{$execute_count}
              );

            my $sleep_time = $execute_count * 0.011;
            Time::HiRes::sleep( $sleep_time );

            return $execute_count;
        },
        sub {
            my ( $execute_count, $time_sum, $rv ) = @_;
            ( $rv->[0] == 15 ) ? 1 : 0;
        },
        +{
            wait_interval           => 0.1,
            check_strategy_interval => 3,
            strategy => +{
                class => 'ByLoad',
                args  => +{ load => 0.5 },
            },
        }
    );

    is( $result->{executed}, 15, 'executed count' );
    cmp_ok( $result->{total_time}, '>=', sum( 1..15 ) * 0.01, 'total time' );
};

subtest 'strategy: MySQL::BalancedReplication' => sub {
    my %expected_wait_interval = (
        1 => 0.1,
        2 => 0.1,
        3 => 0.1,
        4 => 0.1,
        5 => 0.1,
        6 => 0.1,
        7 => 0.1,
        8 => 0.1,
        9 => 0.1,
        10 => 0.1 + ( 4.5 - 3 ) / 3,
        11 => 0.1 + ( 4.5 - 3 ) / 3,
        12 => 0.1 + ( 4.5 - 3 ) / 3,
        13 => 0.1 + ( 6 - 3   ) / 3,
        14 => 0.1 + ( 6 - 3   ) / 3,
        15 => 0.1 + ( 6 - 3   ) / 3,
    );

    my $expected_total_time = sum(values %expected_wait_interval);
    
    my $dbh = DBI->connect('dbi:Mock:', '', '');

    my $result = loop_sustainable(
        sub {
            my ( $execute_count, $wait_interval ) = @_;

            cmp_ok $wait_interval, '>=',
              $expected_wait_interval{$execute_count},
              sprintf(
                  'executed_count: %d; got_wait_interval: %.3f, expected_wait_interval: %.3f',
                  $execute_count, $wait_interval,
                  $expected_wait_interval{$execute_count}
              );

            if ( $execute_count % 3 == 0 ) {
                $dbh->{mock_add_resultset} = +{
                    sql => 'SHOW SLAVE STATUS',
                    results => [
                        [ qw/Seconds_Behind_Master/ ],
                        [ $execute_count * 0.5 ]
                    ],
                };
            }

            Time::HiRes::sleep( 0.01 );

            return $execute_count;
        },
        sub {
            my ( $execute_count, $time_sum, $rv ) = @_;
            ( $rv->[0] == 15 ) ? 1 : 0;
        },
        +{
            wait_interval           => 0.1,
            check_strategy_interval => 3,
            strategy => +{
                class => 'MySQL::BalancedReplication',
                args  => +{
                    dbh => $dbh,
                    capable_behind_seconds => 3,
                },
            },
        }
    );

    is( $result->{executed}, 15, 'executed count' );
    cmp_ok( $result->{total_time}, '>=', 0.01 * 15 );
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
