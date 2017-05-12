use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;

use_ok 'HTTP::Command::Wrapper';
use_ok 'HTTP::Command::Wrapper::Wget';
use_ok 'HTTP::Command::Wrapper::Curl';

done_testing;

