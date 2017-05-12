#!/usr/bin/env perl
use strict;
use warnings;

use File::Path;
use File::Temp;
use File::chdir;
use FindBin;
use Gerrit::Client::Test;
use Gerrit::Client;
use Test::More;

sub test_patchset_creation {
  my ($gerrit)    = @_;
  my $giturl_base = $gerrit->giturl_base();
  my $giturl      = "$giturl_base/perl-gerrit-client-test";

  if ( $gerrit->git( 'ls-remote', $giturl ) ) {
    $gerrit->gerrit_ok( 'create-project', '--empty-commit',
      'perl-gerrit-client-test' )
      || return;
  }

  if ( -d 'perl-gerrit-client-test' ) {
    rmtree('perl-gerrit-client-test');
  }

  my $workdir =
    File::Temp->newdir( 'perl-gerrit-client-for-each-patchset.XXXXXX',
    TMPDIR => 1 );
  $gerrit->git_ok( 'clone', $giturl ) || return;
  push @CWD, 'perl-gerrit-client-test';

  my $cv = AE::cv();
  Gerrit::Client::query(
    'status:open',
    url               => $giturl_base,
    current_patch_set => 1,
    on_success        => sub { $cv->send(@_) },
  );

  # get all the changes which exist prior to this test starting
  my @exist = $cv->recv();
  my %exist_revisions = map { $_->{currentPatchSet}{revision} => 1 } @exist;

  my $pushed       = 0;
  my $stop_count   = scalar @exist;
  my $review_score = 0;
  my $review_output;
  my @events;
  my %review_events;

  $cv = AE::cv();

  my $stream = Gerrit::Client::stream_events(
    url      => $giturl_base,
    on_event => sub {
      my ( $event ) = @_;
      if ( $event->{type} eq 'comment-added' ) {
        $review_events{ $event->{patchSet}{revision} } = $event;
      }
    }
  );
  my $guard = Gerrit::Client::for_each_patchset(
    url         => $giturl_base,
    workdir     => "$workdir",
    review      => 1,
    on_patchset => sub {
      my $revision = qx(git rev-parse HEAD);
      chomp $revision;
      push @events,
        {
        revision => $revision,
        wd       => "$CWD",
        pushed   => $pushed,
        };
      if ( defined($stop_count) && scalar(@events) >= $stop_count ) {
        $cv->send();
      }
      if ($review_output) {
        print $review_output;
      }
      return $review_score;
    },
  );

  my $ssh_pid = $guard->{stream}{stash}{pid};
  ok( $ssh_pid, 'got an $ssh_pid' );
  is( kill( 0, $ssh_pid ), 1, 'ssh is running' );

  if ($stop_count) {
    $cv->recv();
    $cv = AE::cv();
  }

  my $commit1;
  {
    $gerrit->git_test_commit(
      "commit 1\n\nChange-Id: " . Gerrit::Client::random_change_id() )
      || return;
    $commit1 = qx(git rev-parse HEAD);
    chomp $commit1;
    $gerrit->git_ok( 'push', '-v', 'origin', 'HEAD:refs/for/master' ) || return;
    $pushed = $commit1;
    ++$stop_count;
    $cv->recv();
    $cv = AE::cv();
  }

  my $commit2;
  {
    $gerrit->git_test_commit( { amend => 1 } ) || return;
    $commit2 = qx(git rev-parse HEAD);
    chomp $commit2;
    $gerrit->git_ok( 'push', '-v', 'origin', 'HEAD:refs/for/master' ) || return;
    $pushed = $commit2;
    ++$stop_count;
    $review_output = 'review of commit 2';
    $review_score  = -1;
    $cv->recv();
    $cv = AE::cv();
  }

  # if we kill ssh and push another commit immediately after, we should still
  # be able to find that new commit (perhaps with some delay)
  my $commit3;
  {
    $gerrit->git_test_commit(
      "commit 3\n\nChange-Id: " . Gerrit::Client::random_change_id() )
      || return;
    $commit3 = qx(git rev-parse HEAD);
    chomp $commit3;
    diag "'connection lost' warnings may be printed, don't be alarmed, this is expected...";
    is( kill( 15, $ssh_pid ), 1, 'killed ssh' );
    $gerrit->git_ok( 'push', '-v', 'origin', 'HEAD:refs/for/master' ) || return;
    $pushed = $commit3;
    ++$stop_count;
    $review_output = 'review of commit 3';
    $review_score  = 0;
    $cv->recv();
    $cv = AE::cv();
  }

  # wait a bit for the last review event to come through
  my $timer = AE::timer 2, 0, sub { $cv->send() };
  $cv->recv();

  isnt( $guard->{stream}{stash}{ssh_pid}, $ssh_pid, 'new ssh started' );

  my %seen_wd;
  foreach my $e (@events) {
    my $wd = $e->{wd};
    ok( !$seen_wd{$wd}, 'unique wd' );
    $seen_wd{$wd}++;

    # if it's not something we pushed, it should have been something existing
    # from the initial query
    if ( !$e->{pushed} ) {
      ok( $exist_revisions{ $e->{revision} }, 'revision OK' );
      next;
    }

    is( $e->{pushed}, $e->{revision}, 'revision equals what was pushed' );
  }

  # code review type may be expressed as either CRVW or Code-Review depending
  # on gerrit version
  my $type = $review_events{$commit2}{approvals}[0]{type};
  ok( $type eq 'CRVW' || $type eq 'Code-Review' );

  my $description = 'Code Review';
  if ($type eq 'Code-Review') {
    $description = $type;
  }

  like(
    $review_events{$commit2}{comment},
    qr{
      \A
      # this prefix appears on some gerrit versions
      (Patch\ Set\ 2:\ Code-Review-1\s+)?
      review\ of\ commit\ 2
      \z
    }xms,
    'commit 2 review message'
  );
  is_deeply(
    $review_events{$commit2}{approvals}[0],
    { 'description' => $description,
      'type'        => $type,
      'value'       => '-1'
    },
    'commit 2 review score'
  );

  like(
    $review_events{$commit3}{comment},
    qr{
      \A
      (Patch\ Set\ 1:\s+)?
      review\ of\ commit\ 3
      \z
    }xms,
    'commit 3 review message'
  );
  isnt( $review_events{$commit2}{approvals}, 'commit 3 no score' );

  return;
}

sub run {
  if ( !$ENV{GERRIT_WAR} ) {
    plan skip_all => 'Gerrit system tests are not enabled';
    return;
  }

  my $testdir = "$FindBin::Bin/gerrit";
  my $gerrit =
    Gerrit::Client::Test->ensure_gerrit_installed( dir => $testdir, );
  ok( $gerrit, "loaded gerrit in $testdir" ) || return;
  $gerrit->ensure_gerrit_running();

  local $CWD = $testdir;
  local %ENV = Gerrit::Client::git_environment(
    name  => $gerrit->{user},
    email => "$gerrit->{ user }\@127.0.0.1",
  );
  local @Gerrit::Client::SSH = ( $gerrit->git_ssh_wrapper() );
  local @Gerrit::Client::GIT = ( $gerrit->git_wrapper() );

  test_patchset_creation($gerrit);

  return;
}

if ( !caller ) {
  run;
  done_testing;
}
