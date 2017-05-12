use strict;
use warnings FATAL => 'all';
use utf8;

use Capture::Tiny qw/capture_stdout/;
use File::Slurp qw/read_file/;
use File::Spec;
use File::Temp qw/tempdir/;
use File::Which;

use lib '.';
use t::Util;
use HTTP::Command::Wrapper::Curl;
use HTTP::Command::Wrapper::Test::Server;
use HTTP::Command::Wrapper::Test::Mock;

my $server = create_test_server;

subtest mock => sub {
    my ($stdout) = create_binary_mock {
        capture_stdout {
            my $curl = HTTP::Command::Wrapper::Curl->new;
            $curl->download('uri', 'dest');
        };
    };

    chomp $stdout;
    like $stdout, qr{curl -L "?uri"? -o "?dest"?};
};

if (which('curl')) {
    subtest basic => sub {
        my $curl   = HTTP::Command::Wrapper::Curl->new;
        my $dir    = tempdir();
        my $path   = File::Spec->catfile($dir, 'test.txt');
        my $result = create_dummy_curlrc {
            $curl->download($server->uri_for('test.txt'), $path);
        };

        ok $result;
        is read_file($path), read_file($server->path_for('test.txt'));
    };
}

done_testing;
