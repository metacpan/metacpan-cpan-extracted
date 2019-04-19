package Log::Mini::LoggerNULL;

use strict;
use warnings;

use base 'Log::Mini::LoggerBase';

sub _log {
    return;
}

1;
