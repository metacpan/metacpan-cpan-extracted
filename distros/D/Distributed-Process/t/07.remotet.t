#!perl -T
use Test::More tests => 22;

use Distributed::Process::Worker;
use Distributed::Process::RemoteWorker;
my $t = new Distributed::Process::RemoteWorker;

isa_ok($t, 'Distributed::Process::RemoteWorker');

@Test::A::ISA = qw/ Distributed::Process::Worker /;
Test::A::->go_remote();
@Test::B::ISA = qw/ Test::A /;
@Test::C::ISA = qw/ Test::B Test::A /;

ok(Test::A->isa($_), "Test::A is a $_") foreach qw/ Distributed::Process::Worker Distributed::Process::RemoteWorker Distributed::Process::BaseWorker Distributed::Process Exporter Distributed::Process::Interface /;
ok(Test::B->isa($_), "Test::B is a $_") foreach qw/ Test::A Distributed::Process::Worker Distributed::Process::RemoteWorker Distributed::Process::BaseWorker Distributed::Process Exporter Distributed::Process::Interface /;
ok(Test::C->isa($_), "Test::C is a $_") foreach qw/ Test::B Test::A Distributed::Process::Worker Distributed::Process::RemoteWorker Distributed::Process::BaseWorker Distributed::Process Exporter Distributed::Process::Interface /;
