use strict;
use warnings FATAL => 'all';
use utf8;

use File::Slurp qw/read_file/;
use File::Which;

use lib '.';
use t::Util;
use HTTP::Command::Wrapper::Wget;
use HTTP::Command::Wrapper::Test::Server;
use HTTP::Command::Wrapper::Test::Mock;

my $server = create_test_server;

subtest mock => sub {
    my $output = create_binary_mock {
        my $wget = HTTP::Command::Wrapper::Wget->new;
        $wget->fetch('uri');
    };

    chomp $output;
    like $output, qr{wget --quiet "?uri"? -O -};
};

if (which('wget')) {
    subtest basic => sub {
        my $wget   = HTTP::Command::Wrapper::Wget->new;
        my $result = create_dummy_wgetrc {
            $wget->fetch($server->uri_for('test.txt'));
        };

        is $result, read_file($server->path_for('test.txt'));
    };
}

done_testing;
