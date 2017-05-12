#!perl -T
use Test::More tests => 4;

use Distributed::Process::Master;
my $m = new Distributed::Process::Master
    -worker_class => 'Distributed::Process::Worker',
    -n_workers => 1,
;

isa_ok($m, 'Distributed::Process::Master');
isa_ok($m, 'Distributed::Process::Interface');
is($m->worker_class(), 'Distributed::Process::Worker', 'attribute correctly set by constructor');
is($m->n_workers(), 1, 'attribute correctly set by constructor');
