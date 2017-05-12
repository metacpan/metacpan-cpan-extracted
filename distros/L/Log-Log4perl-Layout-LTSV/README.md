Log::Log4perl::Layout::LTSV
===========================

A Log4perl layout that spits out [LTSV](http://ltsv.org/).

Usage:
```perl
use Log::Log4perl;
use Log::Log4perl::Layout::LTSV;
my $logger_conf = {
      'log4perl.logger.test'                              => 'DEBUG, SERVER',
      'log4perl.appender.SERVER'                          => 'Log::Log4perl::Appender::Socket',
      'log4perl.appender.SERVER.PeerAddr'                 => '10.1.2.3',
      'log4perl.appender.SERVER.PeerPort'                 => '514',
      'log4perl.appender.SERVER.Proto'                    => 'tcp',
      'log4perl.appender.SERVER.layout'                   => 'LTSV',
      'log4perl.appender.SERVER.layout.field.facility'    => 'Custom facility',
      'log4perl.appender.SERVER.layout.field.application' => 'Awesome application',
      'log4perl.appender.SERVER.layout.field.datacenter'  => 'DC12'
};
Log::Log4perl->init($logger_conf);
my $LOGGER = Log::Log4perl->get_logger('test');
$LOGGER->debug('Debug log');
```
