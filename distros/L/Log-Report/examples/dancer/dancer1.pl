#!/usr/bin/env perl
# Daemon at localhost:3000

use Dancer;
use Dancer::Logger::LogReport;
use Log::Report import => 'dispatcher';

dispatcher FILE => 'logfile'     # open additional log destination
# , mode => 'DEBUG'              # extended information
  , to => '/tmp/dancer-demo.log';

dispatcher close => 'default';   # closes warn/die default dispatcher

set logger        => 'log_report';
set log           => 'debug';
set logger_format => 'LOG: %i%m';

get '/' => sub {
    error "we reached the log";   # use Dancer's error() syntax!
    notice "one more";            # additional levels, same syntax
    return "Hello World!\n";
};

start;
