use Forks::Super::Job;
use Test::More tests => 57;
use strict;
use warnings;

### exercise some of the methods and attributes of Forks::Super::Job

my $TOL = $Forks::Super::SysInfo::TIME_HIRES_TOL || 1.0E-6;

my $job = Forks::Super::Job->new( {abc => 'def', ghi => 'jkl'} );
ok(defined $job, 'F::S::Job created');
ok($job->{created}, 'job has creation timestamp');
ok($job->{state} eq 'NEW', 'new job has NEW state');
ok($job->state, 'new job has a state');
ok(!defined($job->status), 'new job does not have a status');
ok($job->{ppid}, 'new job has ppid field');
ok($job->{abc} eq 'def' && $job->{ghi} eq 'jkl',
   'new job respects its options')
    or diag($job->{abc}, $job->{ghi});

ok(!$job->is_complete, 'new job is not complete');
ok(!$job->is_started, 'new job is not started');
ok(!$job->is_active, 'new job is not active');
ok(!$job->is_suspended, 'new job is not suspended');
ok(!$job->is_deferred, 'new job is not deferred');
ok(!$job->is_daemon, 'job is not a daemon');

$job->{state} = 'DEFERRED';
ok(!$job->is_complete, 'deferred job is not complete');
ok(!$job->is_started, 'deferred job is not started');
ok(!$job->is_active, 'deferred job is not active');
ok(!$job->is_suspended, 'deferred job is not suspended');
ok($job->is_deferred, 'deferred job is deferred');

$job->suspend;
ok(!$job->is_complete, 'suspended-deferred job is not complete');
ok(!$job->is_started, 'suspended-deferred job is not started');
ok(!$job->is_active, 'suspended-deferred job is not active');
ok($job->is_suspended, 'suspended-deferred job is suspended');
ok($job->is_deferred, 'suspended-deferred job is deferred');

$job->{state} = 'ACTIVE';
$job->{start} = Time::HiRes::time();
ok(!$job->is_complete, 'active job is not complete');
ok($job->is_started, 'active job is started');
ok($job->is_active, 'active job is active');
ok(!$job->is_suspended, 'active job is not suspended');
ok(!$job->is_deferred, 'active job is not deferred');

$job->{state} = 'SUSPENDED';
ok(!$job->is_complete, 'suspended job is not complete');
ok($job->is_started, 'suspended job is started');
ok(!$job->is_active, 'suspended job is not active');
ok($job->is_suspended, 'suspended job is suspended');
ok(!$job->is_deferred, 'suspended job is not deferred');
ok(!$job->{end}, 'incomplete job no end time');
ok(!$job->{elapsed}, 'incomplete job no end time');

$job->{status} = 0;
$job->_mark_complete;
ok($job->is_complete, 'complete job is complete');
ok($job->is_started, 'complete job is started');
ok(!$job->is_active, 'complete job is not active');
ok(!$job->is_suspended, 'complete job is not suspended');
ok(!$job->is_deferred, 'complete job is not deferred');
ok($job->{end} + $TOL > $job->{created}, 'complete job has end time');
ok(!$job->{reaped}, 'complete job has no reap time');

$job->_mark_reaped;
ok($job->is_complete, 'reaped job is complete');
ok($job->is_started, 'reaped job is started');
ok(!$job->is_active, 'reaped job is not active');
ok(!$job->is_suspended, 'reaped job is not suspended');
ok(!$job->is_deferred, 'reaped job is not deferred');
ok($job->{reaped} + $TOL >= $job->{end}, 'reaped job has an end time');

$Forks::Super::MAX_PROC = 4;
$Forks::Super::MAX_LOAD = 0.50;
ok($job->_max_proc == 4, '_max_proc defaults to \$F::S::MAX_PROC');
ok($job->_max_load == 0.50, '_max_load defaults to \$F::S::MAX_LOAD');
$job->{max_proc} = 7;
$job->{max_load} = 0.99;
ok($job->_max_proc == 7, '_max_proc uses max_proc attribute')
    or diag($job->_max_proc);
ok($job->_max_load == 0.99, '_max_load uses max_load attribute')
    or diag($job->_max_load);

$job->{status} = 13 + 256 * 9;
ok($job->status == $job->{status}
   && $job->status == 13 + 256 * 9, 'status returns status attr');
ok(scalar $job->exit_status == -13, 'scalar exit status returns signal');
my @r = $job->exit_status;
ok($r[0]==9 && $r[1]==13 && $r[2]==0, 'exit status in list context');
$job->{status} = 9 * 256;
ok(scalar $job->exit_status == 9, 'scalar exit status returns >>8');

$job->{pid} = $job->{real_pid} = 999;
$job->dispose;
ok($job->{disposed}, 'dispose sets disposed attribute');

# get? getOrMock? getByName? getByPid?     
