use Forks::Super ':test', DEBUG => 1, ON_BUSY => "bogus";
use Test::More tests => 2;
use strict;
use warnings;


ok($Forks::Super::DEBUG == 1);
ok($Forks::Super::ON_BUSY ne "bogus");



