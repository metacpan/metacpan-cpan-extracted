use strict;
use warnings;
use utf8;

use lib '.';
use t::Util;
use Example::Div;

subtest div => sub {
    can_ok 'Example::Div', qw/div/;
    is( Example::Div->div(9, 3), 3);
    is( Example::Div->div(10, 3), 3);
};

done_testing;
