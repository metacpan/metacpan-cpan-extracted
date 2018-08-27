package Linux::Perl::getrandom::i686;

use strict;
use warnings;

use parent 'Linux::Perl::getrandom';

use constant {
    NR_getrandom  => 355,
};

1;
