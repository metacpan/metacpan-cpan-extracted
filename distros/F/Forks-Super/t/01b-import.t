use Forks::Super MAX_PROC => 18, ON_BUSY => "queue", MAX_LOAD => 0.50;
use Test::More tests => 3;
use strict;
use warnings;

ok($Forks::Super::MAX_PROC == 18);
ok($Forks::Super::ON_BUSY eq "queue");
ok($Forks::Super::MAX_LOAD == 0.5);


