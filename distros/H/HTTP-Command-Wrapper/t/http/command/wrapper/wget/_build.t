use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use HTTP::Command::Wrapper::Wget;

subtest basic => sub {
    my $wget = HTTP::Command::Wrapper::Wget->new;
    is $wget->_build([], 0), 'wget';
    is $wget->_build([], 1), 'wget --quiet';
    is $wget->_build(['HEADER'], 1, ['--opt']), 'wget --header="HEADER" --quiet --opt';
};

subtest verbose => sub {
    subtest '# false' => sub {
        my $wget = HTTP::Command::Wrapper::Wget->new({ verbose => 0 });
        is $wget->_build([], 0), 'wget';
    };

    subtest '# true' => sub {
        my $wget = HTTP::Command::Wrapper::Wget->new({ verbose => 1 });
        is $wget->_build([], 0), 'wget --verbose';
    };
};

subtest quiet => sub {
    subtest '# false' => sub {
        my $wget = HTTP::Command::Wrapper::Wget->new({ quiet => 0 });
        is $wget->_build([], 0), 'wget';
    };

    subtest '# true' => sub {
        my $wget = HTTP::Command::Wrapper::Wget->new({ quiet => 1 });
        is $wget->_build([], 0), 'wget --quiet';
    };
};

done_testing;
