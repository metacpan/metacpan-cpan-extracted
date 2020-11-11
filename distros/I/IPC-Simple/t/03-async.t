use strict;
use warnings;

use Test::More;
use AnyEvent;
use Carp;
use IPC::Simple;
use Guard qw(scope_guard);

BAIL_OUT 'OS unsupported' if $^O eq 'MSWin32';

ok my $proc = IPC::Simple->new(
  cmd  => 'perl',
  args => ['-e', '$|=1; my $line = <STDIN>; print("$line");'],
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

ok $proc->launch, 'launch';

my $cv = AnyEvent->condvar;
$proc->send('test message');
$proc->async($cv);
is $cv->recv, 'test message';

done_testing;
