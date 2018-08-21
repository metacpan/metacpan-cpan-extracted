package Linux::Perl::getrandom::x86_64;

use strict;
use warnings;

use parent 'Linux::Perl::getrandom';

use constant {
    NR_getrandom  => 318,
};

1;
