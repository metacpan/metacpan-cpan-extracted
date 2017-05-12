use strict;
use warnings FATAL => 'all';
use utf8;

use Test::Mock::Guard qw/mock_guard/;
use File::Which;

use lib '.';
use t::Util;
use HTTP::Command::Wrapper::Wget;
use HTTP::Command::Wrapper::Test::Server;
use HTTP::Command::Wrapper::Test::Mock;

my $server = create_test_server;

subtest mock => sub {
    my $curl = HTTP::Command::Wrapper::Wget->new;

    create_binary_mock {
        ok $curl->fetch_able('200 OK');
        ok !$curl->fetch_able('404 Not Found');
    };
};

if (which('wget')) {
    subtest basic => sub {
        my $wget = HTTP::Command::Wrapper::Wget->new;

        create_dummy_wgetrc {
            ok $wget->fetch_able($server->uri_for('test.txt'));
            ok !$wget->fetch_able($server->uri_for('test2.txt'));
        };
    };
}

done_testing;
