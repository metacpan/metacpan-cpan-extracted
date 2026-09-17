use strict;
use warnings;
use Test::More;

use HTTP::API::Core;

is $HTTP::API::Core::VERSION, '1.01', 'distribution version is 1.01';

done_testing;
