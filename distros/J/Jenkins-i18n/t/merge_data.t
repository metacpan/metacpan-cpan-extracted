use warnings;
use strict;
use Test::More;
use Test::Exception;

use Jenkins::i18n qw(merge_data);

my $expected_error = 'Got the expected exception message';

dies_ok { merge_data() } 'Dies with missing Jelly keys parameter';
like( $@, qr/Jelly\skeys\sis\srequired/, $expected_error );

dies_ok { merge_data(1) } 'Dies with invalid Jelly keys parameter';
like( $@, qr/Jelly\stype/, $expected_error );

dies_ok { merge_data( {} ) } 'Dies with missing Properties keys parameter';
like( $@, qr/Properties\skeys\sis\srequired/, $expected_error );

dies_ok { merge_data( {}, 2 ) } 'Dies with invalid Jelly keys parameter';
like( $@, qr/Properties\stype/, $expected_error );

my @fixtures = (
    {
        test_case  => 'Best scenario',
        jelly      => { user => 1, shutdown => 1, warn => 1 },
        properties => {
            user     => 'Hello user!',
            shutdown => 'The system is going down!',
            warn     => 'A serious warning'
        },
        expected => {
            user     => 'Hello user!',
            shutdown => 'The system is going down!',
            warn     => 'A serious warning'
        },
    },
    {
        test_case  => 'No Jelly',
        jelly      => {},
        properties => {
            user     => 'Hello user!',
            shutdown => 'The system is going down!',
            warn     => 'A serious warning'
        },
        expected => {
            user     => 'Hello user!',
            shutdown => 'The system is going down!',
            warn     => 'A serious warning'
        },
    },
    {
        test_case => 'Partial translation',
        jelly     => {
            user                  => 1,
            'A\ serious\ warning' => 1,
            shutdown              => 1
        },
        properties => {
            user     => 'Hello user!',
            shutdown => 'The system is going down!'
        },
        expected => {
            user                  => 'Hello user!',
            shutdown              => 'The system is going down!',
            'A\ serious\ warning' => 'A\ serious\ warning',
        },
    },
    {
        test_case => 'Only Jelly',
        jelly     => {
            'Hello\ User'                  => 1,
            'A\ serious\ warning'          => 1,
            'The\ system\ is\ going\ down' => 1
        },
        properties => {},
        expected   => {
            'Hello\ User'                  => 'Hello\ User',
            'A\ serious\ warning'          => 'A\ serious\ warning',
            'The\ system\ is\ going\ down' => 'The\ system\ is\ going\ down'
        },
    }
);

foreach my $test_case (@fixtures) {
    note( $test_case->{test_case} );
    my $current_ref
        = merge_data( $test_case->{jelly}, $test_case->{properties} );
    is( ref($current_ref), 'HASH', 'merge result is a hash reference' );
    is_deeply(
        $current_ref,
        $test_case->{expected},
        (
                  'Have the expected Properties for "'
                . $test_case->{test_case}
                . '" test case'
        )
    ) or diag( explain($current_ref) );
}

done_testing;
