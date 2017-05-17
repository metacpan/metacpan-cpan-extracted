use strict;
use warnings FATAL => 'all';
use utf8;

use Module::Find;

use lib '.';
use t::Util;

use_ok $_ for findallmod 'Devel::Cover::Report::Codecov';

done_testing;

