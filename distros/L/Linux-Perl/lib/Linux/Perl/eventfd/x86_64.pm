package Linux::Perl::eventfd::x86_64;

use strict;
use warnings;

use parent 'Linux::Perl::eventfd';

use constant {
    NR_eventfd  => 284,
    NR_eventfd2 => 290,
};

1;
