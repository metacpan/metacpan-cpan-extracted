use strict;
use warnings;
use Test::More;

use HTTP::API::Core;

is $HTTP::API::Core::VERSION, '1.08', 'distribution version is 1.07';

done_testing;
