use strict;
use warnings;
use lib 't/';
require 'util/verify.pl';

use Test::More;

verify(
    rules   => { version => { from => 'version', default => 1 } },
    input   => {},
    expects => { version => 1 },
    desc    => 'default',
);

done_testing;
