use strict;
use warnings;
use Test::More;

use_ok 'HTTP::API::Core';
use_ok 'HTTP::API::Core::Response';
use_ok 'HTTP::API::Core::Error';
use_ok 'HTTP::API::Core::Pagination';
use_ok 'HTTP::API::Core::RateLimit';
use_ok 'HTTP::API::Core::Auth';

done_testing;
