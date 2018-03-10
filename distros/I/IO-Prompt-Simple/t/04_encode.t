use strict;
use warnings;
use Test::Requires 'Encode';
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../";
use t::Util;

test_prompt(
    input  => "\x82\xA0",
    answer => "\x{3042}",
    opts   => {
        encode => 'cp932',
    },
    prompt => 'prompt : ',
    desc   => 'encode',
);

done_testing;
