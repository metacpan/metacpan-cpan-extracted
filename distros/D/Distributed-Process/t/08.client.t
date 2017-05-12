#!perl -T
use Test::More tests => 2;

use lib 't';
use Distributed::Process;
use Distributed::Process::Client;
use Dummy;


my $c = new Distributed::Process::Client
    -host => 'localhost',
    -port => 8147,
    -worker_class => 'Dummy'
;
isa_ok($c, 'Distributed::Process::Client');
isa_ok($c->worker(), 'Dummy');
