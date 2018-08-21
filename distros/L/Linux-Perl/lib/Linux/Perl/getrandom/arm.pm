package Linux::Perl::getrandom::arm;

use strict;
use warnings;

use parent 'Linux::Perl::getrandom';

use constant {
    NR_getrandom  => 384,
};

1;
