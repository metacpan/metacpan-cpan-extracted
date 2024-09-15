package Log::Mini::Logger::NULL;

use strict;
use warnings;

use base 'Log::Mini::Logger::Base';


sub _log {
    return;
}

1;
