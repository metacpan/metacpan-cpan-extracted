package Log::Mini::Logger::STDERR;

use strict;
use warnings;

use base 'Log::Mini::Logger::Base';


sub _print
{
    print STDERR $_[1];
}

1;
