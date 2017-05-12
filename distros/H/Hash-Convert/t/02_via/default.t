use strict;
use warnings;
use lib 't/';
require 'util/verify.pl';

use Test::More;

verify(
    rules   => { version => { from => 'version', via => sub { $_[0] + 100 }, default => 1 } },
    input   => {},
    expects => { version => 1 },
    desc    => 'via default',
);

done_testing;
