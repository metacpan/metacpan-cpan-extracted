use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use HTTP::Command::Wrapper::Curl;

subtest basic => sub {
    my $curl = HTTP::Command::Wrapper::Curl->new;
    cmp_deeply [ $curl->_headers(['User-Agent: TEST']) ], [ '-H "User-Agent: TEST"' ];
};

done_testing;
