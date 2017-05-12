use strict;
use warnings;
use lib 't/';
require 'util/verify.pl';

use Test::More;

verify(
    rules   => { updated_at => { define => 1111111111 } },
    input   => { },
    expects => { updated_at => 1111111111 },
    desc    => 'define',
);

done_testing;
