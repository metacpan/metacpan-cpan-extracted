use strict;
use warnings FATAL => 'all';
use utf8;

use Cwd qw/abs_path/;
use File::Basename qw/basename/;
use File::Spec;
use Test::Mock::Guard qw/mock_guard/;

use lib '.';
use t::Util;
use HTTP::Command::Wrapper;
use HTTP::Command::Wrapper::Test::Mock;

{
    subtest found => sub {
	    create_binary_mock {
            ok(HTTP::Command::Wrapper->_which('http_command_wrapper'));
        };
    };

    subtest not_found => sub {
        ok(!HTTP::Command::Wrapper->_which('__invalid_http_command_wrapper'));
    };
};

done_testing;
