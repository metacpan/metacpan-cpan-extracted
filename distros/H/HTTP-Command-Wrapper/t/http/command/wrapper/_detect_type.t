use strict;
use warnings FATAL => 'all';
use utf8;

use Test::Mock::Guard qw/mock_guard/;

use lib '.';
use t::Util;
use HTTP::Command::Wrapper;

subtest curl => sub {
    my $guard = mock_guard('HTTP::Command::Wrapper', {
        _which => sub { $_[1] eq 'curl' },
    });
    is(HTTP::Command::Wrapper->_detect_type, 'curl');
};

subtest wget => sub {
    my $guard = mock_guard('HTTP::Command::Wrapper', {
        _which => sub { $_[1] eq 'wget' },
    });
    is(HTTP::Command::Wrapper->_detect_type, 'wget');
};

subtest invalid => sub {
    my $guard = mock_guard('HTTP::Command::Wrapper', { _which => 0 });
    is(HTTP::Command::Wrapper->_detect_type, undef);
};

done_testing;
