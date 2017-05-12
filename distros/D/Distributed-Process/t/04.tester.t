#!perl -T
use Test::More tests => 2;

use Distributed::Process::Worker;
my $i = new Distributed::Process::Worker;

isa_ok($i, 'Distributed::Process::Worker');
can_ok($i, 'run');

