use strict;
use warnings;
use utf8;

use t::Util;
use Example::Add;

subtest add => sub {
    can_ok 'Example::Add', qw/add/;
    is( Example::Add->add(3, 5), 8 );
};

done_testing;
