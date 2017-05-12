#!/usr/bin/env perl
use strict;
use warnings;

use Errno qw(ESRCH);
use File::Path;
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
  $gerrit->git_ok( 'clone', $giturl ) || return;
  push @CWD, 'perl-gerrit-client-test';
  $gerrit->git_test_commit(
    "commit 1\n\nChange-Id: " . Gerrit::Client::random_change_id() )
    || return;

  my $cv     = AE::cv();
  my $stream = Gerrit::Client::stream_events(
    url      => $giturl_base,
    on_event => sub {
      $cv->send(@_);
    },
  );
  my $ssh_pid = $stream->{stash}{pid};
  ok( $ssh_pid, 'got an $ssh_pid' );
  is( kill( 0, $ssh_pid ), 1, 'ssh is running' );

  {
    $gerrit->git_ok( 'push', '-v', 'origin', 'HEAD:refs/for/master' ) || return;
    my ( $event1 ) = $cv->recv();
    $cv = AE::cv();
    is( $event1->{type}, 'patchset-created', 'on_event patchset-created 1' );
    is( $event1->{patchSet}{number}, 1, 'PS1' );
  }

  {
    $gerrit->git_test_commit( { amend => 1 } ) || return;
    $gerrit->git_ok( 'push', '-v', 'origin', 'HEAD:refs/for/master' ) || return;
    my ( $event2 ) = $cv->recv();
    $cv = AE::cv();
    is( $event2->{type}, 'patchset-created', 'on_event patchset-created 2' );
    is( $event2->{patchSet}{number}, 2, 'PS2' );
  }

  # check abortion
  {
    undef $stream;
    $gerrit->git_test_commit( { amend => 1 } ) || return;
    $gerrit->git_ok( 'push', '-v', 'origin', 'HEAD:refs/for/master' ) || return;
    my $timer = AE::timer( 2, 0, sub { $cv->send('timeout') } );
    my ( $event3 ) = $cv->recv();
    if ( !is( $event3, 'timeout', 'no events after undef' ) ) {
      diag( 'event3:',  explain($event3) );
    }
    is( kill( 0, $ssh_pid ), 0, 'ssh is no longer running' );
  }
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

  test_patchset_creation($gerrit);

  return;
}

if ( !caller ) {
  run;
  done_testing;
}
