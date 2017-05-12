#!/usr/bin/env perl
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::Util;
use Config;
use Data::Dumper;
use Dir::Self;
use English qw( -no_match_vars );
use Env::Path;
use File::Basename;
use File::Temp;
use File::chdir;
use Gerrit::Client;
use Gerrit::Client::Test;
use JSON;
use Storable qw(dclone);
use Sub::Override;
use Test::More;
use Test::Warn;

# This would normally be loaded internally as needed, but we need to
# load it now for mocking
use Gerrit::Client::ForEach;

# Pipe ends used for communication between parent and child
my %pipe;

# hash of commits reviewed (used for mocks)
my %reviewed_commits;

sub clear_reviewed_commits {
  %reviewed_commits = ();
}

# mock git commands which succeed but don't do much
sub mock_gits_ok {
  return [
    Sub::Override->new(
      'Gerrit::Client::ForEach::_git_bare_clone_cmd' => sub {
        my ( undef, $giturl, $gitdir ) = @_;
        return ( 'git', 'init', '--bare', $gitdir );
      }
    ),
    Sub::Override->new(
      'Gerrit::Client::ForEach::_git_clone_cmd' => sub {
        my ( undef, $giturl, $gitdir ) = @_;
        return ( 'git', 'init', $gitdir );
      }
    ),
    Sub::Override->new(
      'Gerrit::Client::ForEach::_git_fetch_cmd' => sub {
        my ( undef, $giturl, $gitdir, $ref ) = @_;
        return ( 'perl', '-e1' );
      }
    ),
    Sub::Override->new(
      'Gerrit::Client::ForEach::_git_reset_cmd' => sub {
        my ( undef, $ref ) = @_;
        return ( 'perl', '-e1' );
      }
    ),
    Sub::Override->new(
      'Gerrit::Client::ForEach::_mark_commit_reviewed' => sub {
        my (undef, $event) = @_;
        my $rev = $event->{patchSet}{revision};
        if (!$rev) {
          die "bad event: " . Dumper($event);
        }
        diag "revision $event->{patchSet}{revision} now reviewed\n";
        $reviewed_commits{$event->{patchSet}{revision}} = 1;
      }
    ),
    Sub::Override->new(
      'Gerrit::Client::ForEach::_is_commit_reviewed' => sub {
        my (undef, $event) = @_;
        my $rev = $event->{patchSet}{revision};
        if (!$rev) {
          die "bad event: ".Dumper($event);
        }
        if ($reviewed_commits{$rev}) {
          diag "revision $rev is already reviewed\n";
          return 1;
        }
        return 0;
      }
    ),
  ];
}

# some test changes and patch sets
my $test_rev1 = 'a765609f8b97fd8c9c29d7576d46b8eba99c11ac';
my $test_rev2 = 'bbb5609f8b97fd8c9c29d7576d46b8eba99c11ac';
my $test_rev3 = 'ccc5609f8b97fd8c9c29d7576d46b8eba99c11ac';
my $test_rev4 = 'ddd5609f8b97fd8c9c29d7576d46b8eba99c11ac';
my $test_rev5 = 'eee5609f8b97fd8c9c29d7576d46b8eba99c11ac';
my $test_rev6 = 'fff5609f8b97fd8c9c29d7576d46b8eba99c11ac';

my $test_ps1 =
  { number => 1, revision => $test_rev1, ref => 'refs/changes/02/2/1' };
my $test_ps2 =
  { number => 2, revision => $test_rev2, ref => 'refs/changes/01/1/2' };
my $test_ps3 =
  { number => 3, revision => $test_rev3, ref => 'refs/changes/06/6/3' };
my $test_ps4 =
  { number => 4, revision => $test_rev4, ref => 'refs/changes/07/7/4' };
my $test_ps5 =
  { number => 5, revision => $test_rev5, ref => 'refs/changes/07/7/5' };
my $test_ps6 =
  { number => 6, revision => $test_rev6, ref => 'refs/changes/07/7/6' };

my $test_change1 = {
  project         => "prj1",
  branch          => "master",
  id              => "id1",
  subject         => 'Some commit',
  currentPatchSet => $test_ps1,
};
my $test_change2 = {
  project         => "prj2",
  branch          => "master",
  id              => "id2",
  subject         => 'Some other commit',
  currentPatchSet => $test_ps2,
};
my $test_change3 = {
  project         => "prj1",
  branch          => "master",
  id              => "id3",
  subject         => 'A great commit',
  currentPatchSet => $test_ps3,
};
my $test_change4 = {
  project         => "prj2",
  branch          => "master",
  id              => "id4",
  subject         => 'A poor commit',
  currentPatchSet => $test_ps4,
};
my $test_change5 = {
  project         => "prj2",
  branch          => "master",
  id              => "id5",
  subject         => 'The best commit',
  currentPatchSet => $test_ps5,
};

my $test_change_unwanted = {
  project         => "prj3",
  branch          => "master",
  id              => "iduw",
  subject         => 'An unwanted commit',
  currentPatchSet => $test_ps6,
  unwanted => 1,
};

my %test_change_by_id = (
  id1 => $test_change1,
  id2 => $test_change2,
  id3 => $test_change3,
  id4 => $test_change4,
  id5 => $test_change5,
  iduw => $test_change_unwanted,
);

sub patchset_created_json {
  my ($change) = @_;

  # events do not include the currentPatchSet within change
  $change = dclone $change;
  my $patchset = delete $change->{currentPatchSet};
  return encode_json(
    { type     => 'patchset-created',
      change   => $change,
      patchSet => $patchset
    }
  );
}

my %MOCK_QUERY;

sub mock_query {
  my ( $query, %args ) = @_;
  my $results = shift @{ $MOCK_QUERY{$query} || [] };
  $results ||= [];
  my @new_results;
  foreach my $r ( @{$results} ) {
    my $new_r = dclone $r;
    if ( !$args{current_patch_set} ) {
      delete $new_r->{currentPatchSet};
    }
    push @new_results, $new_r;
  }
  $args{on_success}->( @new_results );
  return;
}

sub record_event {
  my ( $change, $patchset ) = @_;
  $pipe{write}->push_write(
    json => {
      change   => $change,
      patchset => $patchset,
      wd       => "$CWD",
    }
  );
  return;
}

sub test_for_each_patchset {
  my ( $testname, %args ) = @_;

  # in cmd mode, we're limited in the event checking we can do
  my $cmd = $args{on_patchset_cmd};

  local %ENV = %ENV;
  my $dir = File::Temp->newdir(
    'perl-gerrit-client-test.XXXXXX',
    TMPDIR  => 1,
    CLEANUP => 1
  );
  ok( $dir, "$testname tempdir created" );
  Env::Path->PATH->Prepend("$dir");

  # test an explicitly set query
  local $MOCK_QUERY{'quux'} = [ ([ $test_change1, $test_change2 ]) x 3 ];
  my $mock_query =
    Sub::Override->new( 'Gerrit::Client::query' => \&mock_query );
  my $mock_git = mock_gits_ok();

  Gerrit::Client::Test::create_mock_command(
    name      => 'ssh',
    directory => $dir,
    sequence  => [

      # simulate various events from a long-lived connection which
      # drops every now and again
      { delay    => 1,
        exitcode => 255,
        stdout   => patchset_created_json($test_change3) . "\n"
      },
      { delay    => 1,
        exitcode => 255,
        stdout   => patchset_created_json($test_change_unwanted) . "\n"
      },
      { delay    => 1,
        exitcode => 255,
        stdout   => patchset_created_json($test_change4) . "\n"
      },
      { delay    => 120,
        exitcode => 0,
        stdout   => patchset_created_json($test_change5) . "\n"
      }
    ],
  );

  my $cv = AE::cv();

  my @events;

  # make sure we eventually give up if something goes wrong
  my $timeout_timer = AE::timer( 120, 0, sub { my $cnt = @events; $cv->croak("timed out after $cnt event(s)") } );
  my $done_timer;
  my $guard;

  my %readreq;
  %readreq = (
    json => sub {
      my ( $h, $data ) = @_;
      push @events, $data;

      # simulate cancelling the loop after 4 events
      if ( @events >= 4 ) {
        undef $guard;
        $done_timer = AE::timer( 1, 0, sub { $cv->send(); undef $done_timer } );
      }
      $h->push_read(%readreq);
    }
  );

  $pipe{read}->push_read(%readreq);

  $guard = Gerrit::Client::for_each_patchset(
    url     => 'ssh://gerrit.example.com/',
    workdir => "$dir/work",
    wanted => sub { return !$_[0]->{unwanted} },
    query => 'quux',
    %args,
  );

  diag "'connection lost' warnings may be printed, don't be alarmed, this is expected...";
  $cv->recv();

  is( scalar(@events), 4, "$testname got expected number of events" );

  # events may occur in any order, so sort them before comparison
  if (!$cmd) {
    @events = sort { $a->{change}{id} cmp $b->{change}{id} } @events;
  }

  my %seen_wd;
  my %seen_id;
  foreach my $e (@events) {

    # there should be a unique temporary work directory for each
    # event, all of which no longer exist
    my $wd = delete $e->{wd};
    ok( !$seen_wd{$wd}, "$testname unique working directory: $wd" );
    ok( !-e $wd,        "$testname working directory $wd was cleaned up" );
    $seen_wd{$wd} = 1;

    next if ($cmd);

    my $id = $e->{change}{id};
    ok( !$seen_id{$id}, "$testname unique event $id" );
    $seen_id{$id} = 1;

    my %test_change   = %{ $test_change_by_id{$id} };
    my $test_patchset = delete $test_change{currentPatchSet};
    is_deeply( $e->{change}, \%test_change, "$testname change $id looks ok" )
      || diag explain $e->{change};
    is_deeply( $e->{patchset}, $test_patchset,
      "$testname patchset $id looks ok" )
      || diag explain $e->{patchset};
  }

  return;
}

sub test_for_each_patchset_inproc {
  my ( $r, $w ) = portable_pipe();
  local $pipe{read}  = AnyEvent::Handle->new( fh => $r );
  local $pipe{write} = AnyEvent::Handle->new( fh => $w );
  test_for_each_patchset( 'inproc', on_patchset => \&record_event );
}

sub test_for_each_patchset_forksub {
  my ( $r, $w ) = portable_pipe();
  local $pipe{read}  = AnyEvent::Handle->new( fh => $r );
  local $pipe{write} = AnyEvent::Handle->new( fh => $w );
  test_for_each_patchset( 'fork', on_patchset_fork => \&record_event );
}

sub test_for_each_patchset_cmd {
  my $script = __DIR__ . '/' . basename(__FILE__);

  my ( $r, $w ) = portable_pipe();
  local $pipe{read}  = AnyEvent::Handle->new( fh => $r );
  local $pipe{write} = AnyEvent::Handle->new( fh => $w );
  my $server = tcp_server undef, undef, sub {
    my ($fh, $host, $port) = @_;

    my $handle;
    $handle = AnyEvent::Handle->new(
      fh => $fh,
      on_read => sub {
        my ($h) = @_;
        $pipe{write}->push_write( delete $h->{rbuf} );
      },
      on_eof => sub {
        undef $handle;
      },
    );
  }, sub {
    my (undef, undef, $port) = @_;
    $ENV{TEST_SOCKET_PORT} = $port;
    return 0;
  };

  my @cmd = ($Config{perlpath}, $script, 'record_event');
  diag "patchset command: @cmd";

  test_for_each_patchset( 'cmd', on_patchset_cmd => \@cmd );
}

sub record_event_from_child {
  my $port = $ENV{TEST_SOCKET_PORT} || die;
  my $cv = AE::cv();
  tcp_connect(
    'localhost',
    $port,
    sub {
      my ($fh) = @_;
      local $pipe{write} = AnyEvent::Handle->new( fh => $fh );
      $pipe{write}->push_write( json => { wd => "$CWD" } );
      $cv->send();
    }
  );
  $cv->recv();
}

sub run_test {
  unless (Gerrit::Client::Test::have_git()) {
    plan skip_all => 'No functional git in PATH';
    return;
  }

  diag "begin inproc test...";
  test_for_each_patchset_inproc;
  clear_reviewed_commits;

  diag "begin forksub test...";
  test_for_each_patchset_forksub;
  clear_reviewed_commits;

  diag "begin cmd test...";
  test_for_each_patchset_cmd;

  return;
}

#==============================================================================

if ( !caller ) {
  if ( $ARGV[0] && $ARGV[0] eq 'record_event' ) {
    record_event_from_child();
    exit 0;
  }
  run_test;
  done_testing;
}
1;
