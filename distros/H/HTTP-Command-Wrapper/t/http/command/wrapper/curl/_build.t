use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use HTTP::Command::Wrapper::Curl;

subtest basic => sub {
    my $curl = HTTP::Command::Wrapper::Curl->new;
    is $curl->_build([], 0), 'curl -L';
    is $curl->_build([], 1), 'curl -L --silent';
    is $curl->_build(['HEADER'], 1, ['--opt']), 'curl -L -H "HEADER" --silent --opt';

};

subtest verbose => sub {
    subtest '# false' => sub {
        my $curl = HTTP::Command::Wrapper::Curl->new({ verbose => 0 });
        is $curl->_build([], 0), 'curl -L';
    };

    subtest '# true' => sub {
        my $curl = HTTP::Command::Wrapper::Curl->new({ verbose => 1 });
        is $curl->_build([], 0), 'curl -L --verbose';
    };
};

subtest quiet => sub {
    subtest '# false' => sub {
        my $curl = HTTP::Command::Wrapper::Curl->new({ quiet => 0 });
        is $curl->_build([], 0), 'curl -L';
    };

    subtest '# true' => sub {
        my $curl = HTTP::Command::Wrapper::Curl->new({ quiet => 1 });
        is $curl->_build([], 0), 'curl -L --silent';
    };
};

done_testing;
