use strict;
use warnings;
use Test::More tests => 4;

use FCGI::ProcManager::MaxRequests;

my $m = FCGI::ProcManager::MaxRequests->new();
is($m->max_requests, 0, 'max_requests default is 0');

$m->max_requests(5);
is($m->max_requests, 5, 'max_requests can be set through accessor');

$m = FCGI::ProcManager::MaxRequests->new({max_requests => 10});
is($m->max_requests, 10, 'max_requests set in constructor');

$ENV{PM_MAX_REQUESTS} = 2;
$m = FCGI::ProcManager::MaxRequests->new();
is($m->max_requests, 2, 'max_requests default set to PM_MAX_REQUESTS env if it exists');
