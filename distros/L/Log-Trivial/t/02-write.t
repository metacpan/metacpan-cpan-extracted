#    $Id: 02-write.t,v 1.7 2007-09-01 17:39:36 adam Exp $

use strict;
use Test::More tests => 43;

use Log::Trivial;

my $logfile = "./t/test.log";
BEGIN { use_ok( 'Log::Trivial' ); }

#    2-6
my $logger = Log::Trivial->new;
ok( $logger->set_write_mode('a'),              'Set write mode to a' );
is( $logger->{_o_sync}, 0,                        'Is o_sync unset?' );

ok($logger,                           'Do we have a $logger object?' );
ok( $logger->set_log_file($logfile), 'Set the test file to $logfile' );
is( $logger->{_file}, $logfile,         'Is $logfile set correctly?' );

#    7-8
ok( $logger->set_log_mode("m"),                'Set multi/slow mode' );
is( $logger->{_mode}, 1,                        'Is multi mode set?' );

#    9-11
is( $logger->{_level}, 3,             'Check the default level is 3' );
ok( $logger->set_log_level(2),          'Set the logging level to 2' );
is( $logger->{_level}, 2,                     'Check it is set to 2' );

#    12-17
ok( ! -e $logfile,               'There should be no file there yet' );
ok( ! $logger->write( comment => 'Test', level => 3 ),
                      'Write Test to the log, should not be written' );
ok( $logger->write( comment => 'Test', level => undef ),
                                'Uses default level so should write' );
$logger->{_level} = undef;
ok( $logger->write( comment => 'Test', level => undef ),
            'Uses default level so should write which is also undef' );
$logger->{_level} = 2;    # Put level back
ok( $logger->write( comment => 'Test-m', level => 1 ),
                          'Write Test to the log, should be written' );
ok( $logger->write( level => 1 ),               'Should write a dot' );
ok( $logger->write('Test-2-m'),              'Write without a level' );
ok( -e $logfile,                        'Now there should be a file' );

#    18-19
ok( $logger->set_log_mode("s"),            'Set to single/fast mode' );
is( $logger->{_mode}, 0,             'Check single/fast mode is set' );

#    21-23
ok( ! $logger->write( comment => "Test", level => 3 ),
                                                    'Should not log' );
ok( $logger->write( comment => "Test-s", level => 1 ),
                          'Write Test to the log, should be written' );
ok( $logger->write( comment => "Test-s2", level => 1 ),
                          'Write Test to the log, should be written' );

#   24-25
$logger = Log::Trivial->new( log_file => $logfile );
is( $logger->{_file}, $logfile,            'Is the logfile $logfile' );

$logger = Log::Trivial->new( log_level => 5 );
is( $logger->{_level}, 5,                'Is the log level set to 5' );

#   25-36
$logger = Log::Trivial->new(
    log_tag  => 'test_tag',
    log_file => $logfile
);
ok( $logger,                              'We have a $logger object' );
ok( $logger->set_write_mode('a'),              'Set write mode to a' );
is( $logger->{_o_sync}, 0,                        'Is o_sync unset?' );
ok( $logger->write('tagged entry'),                    'Write okay?' );

SKIP:
{
    if ( ! -e $logfile ) {
        skip( "Log file does not exist, skipping this test...", 12);
    }
    else {
        open my $test_log, "<",
            $logfile || die "Unable to read test log file: $logfile";
        ok($test_log,                            '$test_log is true' );

        my $line = <$test_log>;
        like( $line, qr/Test/,        'Is there a Test in the file?' );
        $line = <$test_log>;
        like( $line, qr/Test/,  'Is there another Test the in file?' );
        $line = <$test_log>;
        like( $line, qr/Test-m/,    'Is there a Test-m in the file?' );
        $line = <$test_log>;
        like( $line, qr/./,              'Is there a . in the file?' );
        $line = <$test_log>;
        like( $line, qr/Test-2-m/,'Is there a Test-2-m in the file?' );
        $line = <$test_log>;
        like( $line, qr/Test-s/,               'Test-s in the file?' );
        $line = <$test_log>;
        like( $line, qr/Test-s2/,             'Test-s2 in the file?' );
        $line = <$test_log>;
        like( $line, qr/test_tag/,           'test_tag in the file?' );
        like( $line, qr/tagged entry/,   'tagged entry in the file?' );
        ok ( close $test_log,                   'Did it close okay?' );
        is( unlink ( $logfile ), 1,      'Did the file unlink okay?' );
    }
}
#    41

ok( ! -e $logfile,                      'Did it really get deleted?' );
