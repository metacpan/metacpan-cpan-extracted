use strict;
use warnings FATAL => 'all';
use utf8;

use Test::MockObject;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov;

sub get_request_url {
    Devel::Cover::Report::Codecov::get_request_url(@_);
}

subtest basic => sub {
    is
        get_request_url('http://example.com/path', { key => 'value' }),
        'http://example.com/path?key=value';
};

done_testing;
