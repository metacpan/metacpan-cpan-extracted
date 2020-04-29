use strict;
use warnings;

use Test::More;
use AnyEvent;
use IPC::Simple;

ok my $proc = IPC::Simple->new(
  cmd  => 'perl',
  args => ['-e', 'local $|=1; warn "starting\n"; while (my $line = <STDIN>) { print("$line") }'],
), 'ctor';

# Start a timer to ensure a bug doesn't cause us to run indefinitely
my $timeout = AnyEvent->timer(
  after => 30,
  cb => sub{
    $proc->terminate;
    die 'timeout reached';
  },
);

subtest 'initial state' => sub{
  ok !$proc->is_running, 'is_running is initially false';
  ok $proc->launch, 'launch';
  ok $proc->is_running, 'is_running is true after launch';
};

subtest 'send + recv' => sub{
  ok $proc->send('hello world'), 'send';

# can't guarantee which stream will trigger a read event first, so we can test
# for existence of the messages in a list with grep
  my $msgs = [
    $proc->recv,
    $proc->recv,
  ];

  ok((grep{ $_ eq 'starting' } @$msgs), 'recv: str overload');
  ok((grep{ $_ eq 'hello world' } @$msgs), 'recv: str overload');
  ok((grep{ $_->stdout } @$msgs), 'msg->stdout');
  ok((grep{ $_->stderr } @$msgs), 'msg->stderr');
};

subtest 'async' => sub{
  my $cv = AnyEvent->condvar;
  $proc->send('test message');
  $proc->async($cv);
  is $cv->recv, 'test message';
};

subtest 'management' => sub{
  $proc->terminate;
  ok $proc->is_stopping, 'is_stopping';

  $proc->join;
  ok $proc->is_ready, 'is_ready';

  is $proc->exit_code, 0, 'exit_code';
};

# clear timeout so it won't go off
undef $timeout;

done_testing;
