#!perl
use Test::More tests => 10;
use Linux::Pidfile;
use Test::MockObject::Universal;

BEGIN { use_ok( 'Linux::Pidfile' ); }

my $tmu = Test::MockObject::Universal::->new();

my $PID1 = Linux::Pidfile::->new({ logger => $tmu, pidfile => '/tmp/linux-pidfile-test.pid', });
isa_ok $PID1, 'Linux::Pidfile';

ok($PID1->create(),'Created pidfile');

my $pid_from_file = $PID1->this_script_is_running();
ok($pid_from_file,'Got a PID');
like($pid_from_file,qr/^\d+$/,'Valid pid');
is($pid_from_file,$$,'This script is running');
ok($PID1->pid_is_running($pid_from_file),'This pid is running');

my $PID2 = Linux::Pidfile::->new({ logger => $tmu, pidfile => '/tmp/linux-pidfile-test.pid', });
isa_ok $PID2, 'Linux::Pidfile';
my $old_cmdline = $0;
ok($PID2->create(),'Created another pidfile');

ok($PID1->remove(),'Removed pidfile');

