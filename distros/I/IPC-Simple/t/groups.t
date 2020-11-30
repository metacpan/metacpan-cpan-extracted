use strict;
use warnings;

BEGIN{ $ENV{PERL_ANYEVENT_MODEL} = 'Perl' }

use Test::More;
use AnyEvent;
use Carp;
use IPC::Simple qw(spawn process_group);

BAIL_OUT 'OS unsupported' if $^O eq 'MSWin32';

my $proc_a = spawn(['perl', '-e', '$|=1; print("from process a\n"); exit 0'], name => 'a');
my $proc_b = spawn(['perl', '-e', '$|=1; print("from process b\n"); exit 0'], name => 'b');

my $group = process_group $proc_a, $proc_b;
$group->launch;

# Start a timer to ensure a bug doesn't cause us to run indefinitely
my $timeout = AnyEvent->timer(
  after => 10,
  cb => sub{
    diag 'timeout reached';
    $group->signal('KILL');
    die 'timeout reached';
  },
);

my @msgs_a;
my @msgs_b;
my @other;

while (my $msg = $group->recv) {
  if ($msg->source->name eq 'a') {
    push @msgs_a, $msg if $msg->stdout;
    $proc_a->terminate if $msg->error;
  } elsif ($msg->source->name eq 'b') {
    push @msgs_b, $msg if $msg->stdout;
    $proc_b->terminate if $msg->error;
  } else {
    push @other, $msg;
  }
}

ok((grep{ $_ eq 'from process a' } @msgs_a), 'recv: msg from process a');
ok((grep{ $_ eq 'from process b' } @msgs_b), 'recv: msg from process b');
is_deeply \@other, [], 'no unrecognized messages';

$group->terminate;
$group->join;
undef $timeout;

done_testing;
