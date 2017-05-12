#    $Id: 04-posix-write.t,v 1.2 2007-08-19 19:15:56 adam Exp $

use strict;
use Test::More;
use Fcntl qw(:DEFAULT);

BEGIN {
    if ( $^O =~ /mswin32/i ) {
        plan( skip_all => 'Windows is not POSIX compliant.' );
    }
    else {
        plan( tests => 24 );
    }
}

use Log::Trivial;

my $logfile = './t/test.log';
my $o_sync  = './t/o_sync';
ok( 1,                                        'We got this far okay' );

#    2-6
my $logger = Log::Trivial->new;
ok( $logger->set_write_mode('s'),              'Set write mode to S' );
is( $logger->{_o_sync}, 1,                       'Read "write_mode"' );

ok( $logger,                                'We got a $logger object');
ok( $logger->set_log_file($logfile),     'Set the test file to read' );
is( $logger->{_file}, $logfile,        'Was $logfile correctly set?' );

#    7-8
ok( $logger->set_log_mode("m"),             'Set to multi/slow mode' );
is( $logger->{_mode}, 1,                           'Check mode is 1' );

#    9-11
is( $logger->{_level}, 3,                'Check the default level 3' );
ok( $logger->set_log_level(2),          'Set the logging level to 2' );
is( $logger->{_level}, 2,                          'Check it is set' );

#    12-17
ok( !-e $logfile,                'There should be no file there now' );
ok( !$logger->write( comment => "Test", level => 3 ),
                      'Write Test to the log, should not be written' );


SKIP:
{
    eval {
        sysopen my $log, $o_sync, O_WRONLY | O_CREAT | O_SYNC | O_APPEND;
    };
    if ( $@ =~ /Your vendor has not defined Fcntl macro O_SYNC/ ) {
        print STDERR <<"WARNING";

#################################################
# This module uses the POSIX open O_SYNC flag.  #
# This flag is not supported on this system.    #
# You may still use this module, but not in     #
# O_SYNC mode, please see the docs for details. #
#################################################

WARNING

    skip( 'Non POSIX Platform', 10 );

    }
    else {
        is( unlink ( $o_sync ), 1,          'Unlinked $o_sync okay?' );
        ok( $logger->write( comment => "Test-m", level => 1 ),
                          'Write Test to the log, should be written' );

    ok( $logger->write("Test-2-m"),          'Write without a level' );
    ok( -e $logfile,                    'Now there should be a file' );

    ok( $logger->set_log_mode("s"),        'Set to single/fast mode' );
    is( $logger->{_mode}, 0,                     'Check logger mode' );

    #    19-20
    ok( !$logger->write( comment => "Test", level => 3 ),
                      'Write Test to the log, should not be written' );
    ok( $logger->write( comment => "Test-s", level => 1 ),
                          'Write Test to the log, should be written' );

    #    21-22
    is( unlink ( $logfile ), 1,                    'Unlink the file' );
    ok( !-e $logfile,                               'Unlink worked?' );
    }
}
ok( !-e $o_sync,                        '$o_sync should  not exist?' );
