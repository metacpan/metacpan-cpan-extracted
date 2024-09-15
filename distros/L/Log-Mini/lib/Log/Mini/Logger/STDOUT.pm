package Log::Mini::Logger::STDOUT;

use strict;
use warnings;

use base 'Log::Mini::Logger::Base';


sub _print
{
    print STDOUT $_[1];
}

1;
