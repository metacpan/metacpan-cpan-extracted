package Linux::Perl::eventfd::arm;

use strict;
use warnings;

use parent 'Linux::Perl::eventfd';

use constant {
    NR_eventfd  => 351,
    NR_eventfd2 => 356,
};

1;
