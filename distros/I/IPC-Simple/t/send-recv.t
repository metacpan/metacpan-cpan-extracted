use strict;
use warnings;

BEGIN{ $ENV{PERL_ANYEVENT_MODEL} = 'Perl' }

use Test::More;
use AnyEvent;
use Carp;
use IPC::Simple qw(spawn);

BAIL_OUT 'OS unsupported' if $^O eq 'MSWin32';

my $proc = spawn ['perl', '-e', '$|=1; warn "starting\n"; my $line = <STDIN>; print("$line");'];

# Start a timer to ensure a bug doesn't cause us to run indefinitely
my $timeout = AnyEvent->timer(
  after => 10,
  cb => sub{
    diag 'timeout reached';
    $proc->terminate;
    die 'timeout reached';
  },
);

ok $proc->launch, 'launch';
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

$proc->terminate; # send kill signal
$proc->join;      # wait for process to complete
undef $timeout;   # clear timeout so it won't go off

done_testing;
