package Linux::Perl::eventfd::i386;

use strict;
use warnings;

use parent 'Linux::Perl::eventfd';

use constant {
    NR_eventfd  => 323,
    NR_eventfd2 => 328,
};

1;
