use strict;
use warnings;
use lib 't/';
require 'util/verify.pl';

use Test::More;

verify_hash(
    rules   => { created_at => { from => 'time' } },
    input   => { time => '10000' },
    expects => { created_at => '10000' },
    desc    => 'single',
);

verify_hash(
    rules   => { price => { from => [qw/cost tax/], via => sub { $_[0] * (1+$_[1]) } } },
    input   => { cost => 100, tax => 0.05 },
    expects => { price => 105 },
    desc    => 'multi',
);

done_testing;
