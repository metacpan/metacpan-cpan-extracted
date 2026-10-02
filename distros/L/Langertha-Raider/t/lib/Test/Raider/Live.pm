package Test::Raider::Live;
# ABSTRACT: Opt-in live tasks that drive bin/raider like a user

use strict;
use warnings;
use Carp qw( croak );
use Exporter 'import';
use File::Temp qw( tempdir );
use JSON::MaybeXS;
use Path::Tiny;
use POSIX qw( WNOHANG );
use Test2::V0;
use Test::Raider::Env qw( clear_engine_env isolate_home );

our @EXPORT_OK = qw( live_opt_in run_raider_task check_journal );

my $REPO = path(__FILE__)->absolute->parent(5);

=func live_opt_in

    use Test::Raider::Live qw( live_opt_in );
    live_opt_in();    # at BEGIN time, before anything else

Calls C<skip_all> unless C<RAIDER_LIVE_TASKS=1>. Merely having an API key
set is never enough: these tasks cost real money. Once opted in, nothing
skips any more: a missing key, an unusable provider or a failed run is a
test failure.

=cut

sub live_opt_in {
  skip_all('live tasks cost real money: set RAIDER_LIVE_TASKS=1 to run them')
    unless $ENV{RAIDER_LIVE_TASKS};
  return;
}

=func run_raider_task

    my $run = run_raider_task( flags => ['--perl'], prompt => '...',
      seed => sub { my ($workspace) = @_; ... } );

Builds a fresh workspace and a fresh isolated C<HOME>, lets C<seed> fill
the workspace, then runs C<bin/raider> as a subprocess the way a user
would (C<-e ENGINE -m MODEL -r WORKSPACE FLAGS PROMPT>). Provider comes
from the environment: C<RAIDER_LIVE_ENGINE> (default C<minimax>),
C<RAIDER_LIVE_MODEL> (default C<MiniMax-M3>); the key is read from
C<< uc(ENGINE)_API_KEY >> and is the only engine key the child sees.

The child gets C<-I> for this dist's F<lib> and for a Langertha checkout
(C<RAIDER_LIVE_LANGERTHA_LIB>, default F<../langertha/lib> next to this
repo when present), so the run does not depend on the installed Langertha.

Returns C<< { workspace, home, exit, output, timed_out } >>.

=cut

sub run_raider_task {
  my (%arg) = @_;
  my $engine = $ENV{RAIDER_LIVE_ENGINE} // 'minimax';
  my $model  = $ENV{RAIDER_LIVE_MODEL}  // 'MiniMax-M3';
  my $key_env = uc($engine).'_API_KEY';
  my $key = $ENV{$key_env};
  croak('opted into live tasks, but '.$key_env.' is not set for engine '.$engine)
    unless defined $key && length $key;

  my @inc = ( '-I'.$REPO->child('lib') );
  my $lg = $ENV{RAIDER_LIVE_LANGERTHA_LIB}
    // ( $REPO->parent->child('langertha', 'lib')->is_dir
         ? $REPO->parent->child('langertha', 'lib')->stringify : undef );
  unshift @inc, '-I'.$lg if defined $lg;

  my $workspace = path(tempdir(CLEANUP => 1));
  $arg{seed}->($workspace) if $arg{seed};
  my $log = path(tempdir(CLEANUP => 1))->child('output.log');

  my @cmd = ( $^X, @inc, $REPO->child('bin', 'raider')->stringify,
    '-e', $engine, '-m', $model, '-r', $workspace->stringify,
    @{ $arg{flags} // [] }, $arg{prompt} );

  my $pid = fork // croak('fork: '.$!);
  if (!$pid) {
    clear_engine_env();
    my $home = isolate_home();
    $ENV{$key_env} = $key;
    $ENV{NO_COLOR} = 1;
    chdir $workspace->stringify or exit 126;
    open STDIN,  '<', '/dev/null'         or exit 126;
    open STDOUT, '>', $log->stringify     or exit 126;
    open STDERR, '>&', \*STDOUT           or exit 126;
    exec @cmd or exit 127;
  }

  my ($status, $timed_out);
  my $deadline = time + ( $ENV{RAIDER_LIVE_TIMEOUT} // 300 );
  while (1) {
    my $r = waitpid($pid, WNOHANG);
    if ($r == $pid) { $status = $?; last }
    if (time > $deadline) {
      kill 'KILL', $pid; waitpid($pid, 0);
      $status = $?; $timed_out = 1; last;
    }
    select undef, undef, undef, 0.25;
  }

  return {
    workspace => $workspace,
    exit      => $status >> 8,
    output    => $log->slurp_utf8,
    timed_out => $timed_out,
  };
}

=func check_journal

    check_journal($run);

Asserts on the session journal the run left in the workspace
(F<.raider/sessions/*.jsonl>): exactly one session inside the workspace, a
C<run.finished> with status C<completed> and no error, every C<tool.call>
answered by exactly one C<tool.result>, and no error/failed/refusal event.
A C<tool.result> that failed because the tool itself exited non-zero (the
agent's own C<prove> going red mid-iteration) is tolerated and reported
with C<diag>; C<cancelled> or unknown result statuses are not.

=cut

sub check_journal {
  my ($run) = @_;
  my $sdir = $run->{workspace}->child(q(.raider), q(sessions));
  my @files = $sdir->is_dir ? $sdir->children(qr/\.jsonl\z/) : ();
  is(scalar @files, 1, 'one session journal inside the workspace') or return;
  my $json = JSON::MaybeXS->new;
  my @events = map { $json->decode($_) } $files[0]->lines_utf8({ chomp => 1 });

  my @finished = grep { $_->{type} eq 'run.finished' } @events;
  is(scalar @finished, 1, 'exactly one run.finished') or return;
  is($finished[0]{status}, 'completed', 'run.finished status is completed');
  ok(!defined $finished[0]{error}, 'run.finished carries no error')
    or diag $finished[0]{error};

  my @bad = grep { $_->{type} =~ /error|fail|refus/i } @events;
  is(scalar @bad, 0, 'no error/failed/refusal event') or diag(JSON::MaybeXS->new(canonical => 1)->encode(\@bad));

  my (%call, %result);
  $call{ $_->{run}.'/'.$_->{call} }++   for grep { $_->{type} eq 'tool.call' }   @events;
  $result{ $_->{run}.'/'.$_->{call} }++ for grep { $_->{type} eq 'tool.result' } @events;
  ok(scalar(keys %call) >= 1, 'the run made at least one tool call');
  is(\%result, \%call, 'every tool.call has exactly one tool.result');

  my @odd = grep { $_->{type} eq 'tool.result'
    && $_->{status} !~ /\A(?:succeeded|failed)\z/ } @events;
  is(scalar @odd, 0, 'no cancelled/unknown tool.result') or diag(JSON::MaybeXS->new(canonical => 1)->encode(\@odd));
  my @toolfail = grep { $_->{type} eq 'tool.result' && $_->{status} eq 'failed' } @events;
  diag scalar(@toolfail).' tool call(s) exited non-zero along the way' if @toolfail;
  return;
}

1;
