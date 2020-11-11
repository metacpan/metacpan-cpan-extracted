use strict;
use warnings;

use Test::More;
use AnyEvent;
use Carp;
use Guard qw(scope_guard);
use IPC::Simple;

BAIL_OUT 'OS unsupported' if $^O eq 'MSWin32';

ok my $proc = IPC::Simple->new(
  cmd  => 'perl',
  args => ['-e', 'sleep 10'],
), 'ctor';

# Start a timer to ensure a bug doesn't cause us to run indefinitely
my $timeout = AnyEvent->timer(
  after => 10,
  cb => sub{
    diag 'timeout reached';
    $proc->terminate;
    die 'timeout reached';
  },
);

scope_guard{
  $proc->terminate; # send kill signal
  $proc->join;      # wait for process to complete
  undef $timeout;   # clear timeout so it won't go off
};

ok !$proc->is_running, 'is_running is initially false';
ok $proc->launch, 'launch';
ok $proc->is_running, 'is_running is true after launch';

$proc->terminate; # send kill signal
$proc->join;      # wait for process to complete
undef $timeout;   # clear timeout so it won't go off

done_testing;
