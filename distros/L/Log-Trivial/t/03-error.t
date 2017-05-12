#    $Id: 03-error.t,v 1.6 2007-08-18 20:28:16 adam Exp $

use strict;
use Test::More tests => 10;
use Log::Trivial;

my $logger = Log::Trivial->new();
ok( $logger,                                 'We got a logger object');

ok(! $logger->write("This shouldn't log" ),          'Should not log');
is( $logger->get_error(), "No Log file specified yet",
                                         'We got a No Log File error');

ok(! $logger->write(),                          'We can not log yet' );
is( $logger->get_error(), 'Nothing message sent to log',
                                                  'Noting messgae ?' );

ok( ! $logger->set_log_file(),        'filed to set a null log file' );
is( $logger->get_error(), 'File error: No file name supplied',
                                  'Did we get the right File error?' );

ok( $logger->set_log_level(),                    'Log level was set' );
is( $logger->{_level}, 3,                           'Log Level is 3' );

is( $logger->{_debug}, undef,                       'Debug is undef' );
