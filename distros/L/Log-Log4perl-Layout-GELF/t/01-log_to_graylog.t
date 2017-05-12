#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok( 'Log::Log4perl::Layout::GELF' ); }
BEGIN { use_ok( 'Log::Log4perl' ); }

my $layout = Log::Log4perl::Layout::GELF->new();
isa_ok($layout, "Log::Log4perl::Layout::GELF");

can_ok($layout, ("render"));

_init_logger();


sub _init_logger
{

    my %logger_conf = (
                        'log4perl.logger.test.screen' => "DEBUG, DEFAULT",
                        'log4perl.appender.DEFAULT'              => "Log::Log4perl::Appender::Screen",
                        'log4perl.appender.DEFAULT.stderr'         => "0",
                        'log4perl.appender.DEFAULT.layout'       => "GELF",
                        'log4perl.logger.test.server' => "DEBUG, SERVER",
                        'log4perl.appender.SERVER'              => "Log::Log4perl::Appender::Socket",
                        'log4perl.appender.SERVER.PeerAddr'     => '10.211.1.94',
                        'log4perl.appender.SERVER.PeerPort'     => "12201",
                        'log4perl.appender.SERVER.Proto'        => "udp",
                        'log4perl.appender.SERVER.layout'       => "GELF"
                      );

    Log::Log4perl->init( \%logger_conf );
    my $LOGGER = Log::Log4perl->get_logger('test.server');
    $LOGGER->debug("debug test");
    $LOGGER->error("error test");
    $LOGGER->info("info test");
    $LOGGER->warn("warn test");
    $LOGGER->fatal("fatal test");
}
