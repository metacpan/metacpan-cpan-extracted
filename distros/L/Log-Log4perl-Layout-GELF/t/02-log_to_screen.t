#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok( 'Log::Log4perl::Layout::GELF' ); }
BEGIN { use_ok( 'Log::Log4perl' ); }


_init_logger();



sub _init_logger
{

    my %logger_conf = (
                        'log4perl.logger.test.screen'                => "DEBUG, DEFAULT",
                        'log4perl.appender.DEFAULT'                  => "Log::Log4perl::Appender::Screen",
                        'log4perl.appender.DEFAULT.stderr'           => "0",
                        'log4perl.appender.DEFAULT.layout'           => "GELF",
                        'log4perl.appender.DEFAULT.layout.PlainText' => "1",
                      );

    Log::Log4perl->init( \%logger_conf );
    my $LOGGER = Log::Log4perl->get_logger('test.screen');
    $LOGGER->debug("debug test");
    $LOGGER->error("error test");
    $LOGGER->info("info test");
    $LOGGER->warn("warn test");
    $LOGGER->fatal("fatal test");
}
