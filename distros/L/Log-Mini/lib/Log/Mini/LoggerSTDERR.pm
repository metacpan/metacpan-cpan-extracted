package Log::Mini::LoggerSTDERR;

use strict;
use warnings;

use base 'Log::Mini::LoggerBase';

sub _print {
    print STDERR $_[1];
}

1;
