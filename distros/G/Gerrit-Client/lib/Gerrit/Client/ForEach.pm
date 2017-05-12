#############################################################################
##
## Copyright (C) 2012-2014 Rohan McGovern <rohan@mcgovern.id.au>
##
## This library is free software; you can redistribute it and/or
## modify it under the terms of the GNU Lesser General Public
## License as published by the Free Software Foundation; either
## version 2.1 of the License, or (at your option) any later version.
##
## This library is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public
## License along with this library; if not, write to the Free Software
## Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA
##
##
#############################################################################

package Gerrit::Client::ForEach;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Util;
use Capture::Tiny qw(capture_merged);
use Data::Alias;
use Data::Dumper;
use English qw(-no_match_vars);
use File::chdir;
use Gerrit::Client;
use Scalar::Util qw(weaken);

# counter of how many connections we have per server
my %CONNECTION_COUNTER;

# counter of how many worker processes we have
my $WORKER_COUNTER;

# 1 when fetching into a gitdir
my %GITDIR_FETCHING;

sub _giturl_counter {
  my ($giturl) = @_;
  my $gerriturl = Gerrit::Client::_gerrit_parse_url($giturl)->{gerrit};
  return \$CONNECTION_COUNTER{$gerriturl};
}

sub _debug_print {
  return Gerrit::Client::_debug_print(@_);
}

sub _handle_for_each_event {
  my ( $self, $event ) = @_;

  return unless $event->{type} eq 'patchset-created';

  if (my $wanted = $self->{args}{wanted}) {
    if (!$wanted->( $event->{change}, $event->{patchSet})) {
      return;
    }
  }

  $self->_enqueue_event($event);

  return $self->_dequeue_soon();
}

# Git command generators; these are methods so that they can be
# overridden for testing
sub _git_bare_clone_cmd
{
  my (undef, $giturl, $gitdir) = @_;
  return (@Gerrit::Client::GIT, 'clone', '--bare', $giturl, $gitdir);
}

sub _git_clone_cmd
{
  my (undef, $giturl, $gitdir) = @_;
  return (@Gerrit::Client::GIT, 'clone', $giturl, $gitdir);
}

sub _git_fetch_cmd
{
  my (undef, $giturl, $gitdir, @refs) = @_;
  return (@Gerrit::Client::GIT, '--git-dir', $gitdir, 'fetch', '-v', $giturl,
          (map { "+$_:$_" } @refs));
}

sub _git_reset_cmd
{
  my (undef, $ref, $mode) = @_;
  $mode ||= '--hard';
  return (@Gerrit::Client::GIT, 'reset', $mode, $ref);
}

# Returns 1 iff $gitdir contains the given $ref
sub _have_ref {
  my ($gitdir, $ref) = @_;
  my $status;
  capture_merged {
    $status = system(
      @Gerrit::Client::GIT,
      '--git-dir',             $gitdir,
      'rev-parse', $ref
    );
  };
  return ($status == 0);
}

# Returns 1 iff it appears the revision for $event has already been handled
sub _is_commit_reviewed {
  my ( $self, $event ) = @_;
  my $gitdir = $self->_gitdir($event);
  return unless ( -d $gitdir );

  my $revision = $event->{patchSet}{revision};
  my $status;
  my $score = capture_merged {
    $status = system(
      @Gerrit::Client::GIT,    '--no-pager',
      '--git-dir',             $gitdir,
      'notes',                 '--ref',
      'Gerrit-Client-reviews', 'show',
      $revision
    );
  };
  _debug_print "git notes for $revision: status: $status, notes: $score\n";
  return (0 == $status);
}

# Flag a commit as reviewed in persistent storage; it won't be
# reviewed again.
sub _mark_commit_reviewed {
  my ( $self, $event ) = @_;
  my $gitdir = $self->_gitdir($event);

  my $revision = $event->{patchSet}{revision};
  my $status;
  my $output = capture_merged {
    $status =
      system( @Gerrit::Client::GIT, '--git-dir', $gitdir, 'notes', '--ref',
      'Gerrit-Client-reviews', 'append', '-m', '1', $revision, );
  };
  if ( $status != 0 ) {
    $self->{args}{on_error}
      ->( "problem writing git note for $revision\n$output\n" );
  }
  else {
    _debug_print "marked $revision as reviewed\n";
  }
  return;
}

sub _enqueue_event {
  my ( $self, $event ) = @_;

  return if $self->_is_commit_reviewed( $event );

  push @{ $self->{queue} }, $event;

  return;
}

sub _giturl {
  my ( $self, $event ) = @_;
  my $project = $event->{change}{project};
  return "$self->{args}{ssh_url}/$project";
}

sub _gitdir {
  my ( $self, $event ) = @_;
  my $project = $event->{change}{project};
  return "$self->{args}{workdir}/$project/git";
}

sub _ensure_git_cloned {
  my ( $self, $event, $out ) = @_;

  my $ref     = $event->{patchSet}{ref};
  my $project = $event->{change}{project};

  my $gitdir = $self->_gitdir($event);
  my $giturl = $self->_giturl($event);

  # ensure only one event owns the cloning process for a given dir
  if ($self->{git_cloning}{$gitdir} && !$event->{_git_cloning}) {
    if ($self->{git_cloned}{$gitdir}) {
      return 1;
    }
    push @{$out}, $event;
    return 0;
  }

  $self->{git_cloning}{$gitdir} = 1;
  $event->{_git_cloning} = 1;

  my $cloned = $self->_ensure_cmd(
    event => $event,
    queue => $out,
    name  => 'git clone',
    cmd => [ $self->_git_bare_clone_cmd( $giturl, $gitdir ) ],
    onlyif => sub { !-d $gitdir },
    counter => [ _giturl_counter($giturl), $Gerrit::Client::MAX_CONNECTIONS ],
  );
  return unless $cloned;

  if (!$self->{git_cloned}{$gitdir}) {
    $self->{git_cloned}{$gitdir} = 1;

    # make sure to wake up any other event who was waiting on the clone
    $self->_dequeue_soon();
  }

  if ( !-d $gitdir ) {
    $self->{args}{on_error}
      ->( "failed to clone $giturl to $gitdir\n" );
    return;
  }

  return 1;
}

sub _ensure_git_fetched {
  my ( $self, $event, $out, $in ) = @_;

  my $gitdir = $self->_gitdir($event);
  my $giturl = $self->_giturl($event);
  my $ref    = $event->{patchSet}{ref};

  if ($event->{_have_ref} || _have_ref($gitdir, $ref)) {
    $event->{_have_ref} ||= 1;
    return 1;
  }

  # If we're running a 'git fetch', we should try to find
  # _all_ needed refs for the given giturl and fetch them at once
  my @refs = map {
    ($self->_giturl($_) eq $giturl) ? ($_->{patchSet}{ref}) : ()
  } @{$in};

  return $self->_ensure_cmd(
    event => $event,
    queue => $out,
    name  => 'git fetch',
    counter => [ _giturl_counter($giturl), $Gerrit::Client::MAX_CONNECTIONS ],
    'lock' => \$GITDIR_FETCHING{$gitdir},
    onlyif => sub { !_have_ref( $gitdir, $ref ) },
    cmd =>
      [ $self->_git_fetch_cmd( $giturl, $gitdir, $ref, @refs ) ],
  );
}

sub _ensure_git_workdir_uptodate {
  my ( $self, $event, $out ) = @_;

  my $project = $event->{change}{project};
  my $ref     = $event->{patchSet}{ref};
  my $gitdir  = $self->_gitdir($event);

  alias my $workdir = $event->{_workdir};

  # avoid creating temporary directory etc if we can't run processes yet
  if (!$workdir && ($WORKER_COUNTER||0) >= $Gerrit::Client::MAX_FORKS) {
    push @{$out}, $event;
    return;
  }

  $workdir ||=
    File::Temp->newdir("$self->{args}{workdir}/$project/work.XXXXXX");

  my $bare = !$self->{args}{git_work_tree};

  return
    unless $self->_ensure_cmd(
    event => $event,
    queue => $out,
    name  => 'git clone for workdir',
    cmd => [ $bare
               ? $self->_git_bare_clone_cmd( $gitdir, $workdir )
               : $self->_git_clone_cmd( $gitdir, $workdir ) ],
    onlyif => sub { !-d( $bare ? "$workdir/objects" : "$workdir/.git") },
    counter => [ \$WORKER_COUNTER, $Gerrit::Client::MAX_FORKS ],
    );

  return
    unless $self->_ensure_cmd(
    event => $event,
    queue => $out,
    name  => 'git fetch for workdir',
    cmd => [ $self->_git_fetch_cmd( 'origin', $bare ? $workdir : "$workdir/.git", $ref ) ],
    wd    => $workdir,
    counter => [ \$WORKER_COUNTER, $Gerrit::Client::MAX_FORKS ],
  );

  return $self->_ensure_cmd(
    event => $event,
    queue => $out,
    name  => 'git reset for workdir',
    cmd => [ $self->_git_reset_cmd( $ref, $bare ? '--soft' : '--hard' ) ],
    wd    => $workdir,
    counter => [ \$WORKER_COUNTER, $Gerrit::Client::MAX_FORKS ],
  );
}

sub _ensure_cmd {
  my ( $self, %args ) = @_;

  my $event = $args{event};
  my $name  = $args{name};

  # capture output by default so that we can include it in error messages
  if ( !exists( $args{saveoutput} ) ) {
    $args{saveoutput} = 1;
  }

  my $donekey   = "_cmd_${name}_done";
  my $cvkey     = "_cmd_${name}_cv";
  my $statuskey = "_cmd_${name}_status";
  my $outputkey = "_cmd_${name}_output";

  return 1 if ( $event->{$donekey} );

  my $onlyif = $args{onlyif} || sub { 1 };
  my $queue = $args{queue};

  my $weakself = $self;
  weaken($weakself);

  alias my $cmdcv = $event->{$cvkey};
  my $cmd = $args{cmd};
  my $cmdstr;
  {
    local $LIST_SEPARATOR = '] [';
    $cmdstr = "[@{$cmd}]";
  }

  if ( !$cmdcv ) {

    # not done and not started; only needs doing if 'onlyif' returns false
    if ( !$onlyif->() ) {
      $event->{$donekey} = 1;
      return 1;
    }

    # Don't run the command if it counts as a connection and we'd have
    # too many
    my ($counter, $count_max) = @{ $args{counter} || [] };
    my $uncounter;
    if ($counter) {
      if ( ($$counter||0) >= $count_max ) {
        _debug_print(
          "$cmdstr: delaying execution, would surpass limit\n");
        push @{$queue}, $event;
        return;
      }
      $$counter++;
      $uncounter = guard { $$counter-- };
    }

    my $lock = $args{lock};
    my $unlock;
    if ($lock) {
      if ($$lock) {
        _debug_print(
          "$cmdstr: delaying execution, lock held elsewhere\n");
        push @{$queue}, $event;
        return;
      }
      $$lock++;
      $unlock = guard { $$lock-- };
    }

    my $printoutput = sub { _debug_print( "$cmdstr: ", @_ ) };
    my $handleoutput = $printoutput;

    if ( $args{saveoutput} ) {
      $handleoutput = sub {
        $printoutput->(@_);
        $event->{$outputkey} .= $_[0] if $_[0];
      };
    }

    my %run_cmd_args = (
      '>'  => $handleoutput,
      '2>' => $handleoutput,
    );

    if ( $args{wd} ) {
      $run_cmd_args{on_prepare} = sub {
        chdir( $args{wd} ) || warn __PACKAGE__ . ": chdir $args{wd}: $!";
      };
    }

    $cmdcv = AnyEvent::Util::run_cmd( $cmd, %run_cmd_args, );
    $cmdcv->cb(
      sub {
        my ($cv) = @_;
        undef $uncounter;
        undef $unlock;
        return unless $weakself;

        my $status = $cv->recv();
        if ( $status && !$args{allownonzero} ) {
          $self->{args}{on_error}->( "$name exited with status $status\n"
              . ( $event->{$outputkey} ? $event->{$outputkey} : q{} ) );
        }
        else {
          $event->{$donekey} = 1;
        }
        $event->{$statuskey} = $status;
        $weakself->_dequeue_soon();
      }
    );
    push @{$queue}, $event;
    return;
  }

  if ( !$cmdcv->ready ) {
    push @{$queue}, $event;
    return;
  }

  $self->{args}{on_error}->("dropped event due to failed command: $cmdstr\n");
  return;
}

sub _do_cb_sub {
  my ( $self, $sub, $event ) = @_;

  my $returned;
  my $run = sub {
    local $CWD = $event->{_workdir};
    $returned = $sub->( $event->{change}, $event->{patchSet} );
  };

  my $output;
  if ($self->{args}{review}) {
    $output = &capture_merged( $run );
  } else {
    $run->();
  }

  return {
    returned => $returned,
    output => $output
  };
}

sub _do_cb_forksub {
  my ( $self, $sub, $event, $queue ) = @_;

  my $weakself = $self;
  weaken($weakself);

  if ($event->{_forksub_result}) {
    return $event->{_forksub_result};
  }

  if ( $event->{_forked} ) {
    push @{$queue}, $event;
    return;
  }

  $event->{_forked} = 1;
  &fork_call(
    \&_do_cb_sub,
    $self,
    $sub,
    $event,
    sub {
      return unless $weakself;

      my ($result) = $_[0];
      if (!$result) {
        if ($@) {
          $result = {output => $@};
        } else {
          $result = {output => $!};
        }
      }
      $event->{_forksub_result} = $result;
      $weakself->_dequeue_soon();
    }
  );
  push @{$queue}, $event;
  return;
}

sub _do_cb_cmd {
  my ( $self, $cmd, $event, $out ) = @_;

  return if ( $event->{_done} );

  my $project = $event->{change}{project};
  my $ref     = $event->{patchSet}{ref};

  if ( !$event->{_cmd} ) {
    if ( $cmd && ref($cmd) eq 'CODE' ) {
      $cmd = [ $cmd->( $event->{change}, $event->{patchSet} ) ];
    }
    $event->{_cmd} = $cmd;
    local $LIST_SEPARATOR = '] [';
    _debug_print "on_patchset_cmd for $project $ref: [@{$cmd}]\n";
  }

  return unless $self->_ensure_cmd(
    event => $event,
    queue => $out,
    name  => 'on_patchset_cmd',
    cmd   => $event->{_cmd},
    wd    => $event->{_workdir},
    saveoutput => $self->{args}{review},
    allownonzero => 1,
    counter => [ \$WORKER_COUNTER, $Gerrit::Client::MAX_FORKS ],
  );

  my $score = 0;
  my $output = $event->{_cmd_on_patchset_cmd_output};
  my $status = $event->{_cmd_on_patchset_cmd_status};

  if ($status == -1) {
    # exited abnormally; treat as neutral score
  } elsif ($status & 127) {
    # exited due to signal; treat as neutral score,
    # append signal to output
    $output .= "\n[exited due to signal ".($status&127)."]\n";
  } else {
    # exited normally; exit code is score
    $score = $status >> 8;
    # interpret exit code as signed
    if ($score > 127) {
      $score = $score - 256;
    }
  }

  return {
    score => $score,
    output => $output
  };
}

sub _do_callback {
  my ( $self, $event, $out ) = @_;

  my $ref;
  my $result;

  if ( $ref = $self->{args}{on_patchset} ) {
    $result = $self->_do_cb_sub( $ref, $event );
  }
  elsif ( $ref = $self->{args}{on_patchset_fork} ) {
    $result = $self->_do_cb_forksub( $ref, $event, $out );
  }
  elsif ( $ref = $self->{args}{on_patchset_cmd} ) {
    $result = $self->_do_cb_cmd( $ref, $event, $out );
  }

  return unless $result;

  if ($Gerrit::Client::DEBUG) {
    _debug_print 'callback result: ' . Dumper($result);
  }

  # Ensure we shan't review it again
  $self->_mark_commit_reviewed($event);

  my $review = $self->{args}{review};
  return unless $review;

  if ( $review =~ m{\A\d+\z} ) {
    $review = 'code_review';
  }

  if ( my $cb = $self->{args}{on_review} ) {
    return
      unless $cb->(
      $event->{change},  $event->{patchSet},
      $result->{output}, $result->{score},
      $result->{returned}
      );
  }

  if ( !$result->{output} && !$result->{score} && !$result->{returned}) {
    # no review to be done
    return;
  }

  my (%review_args) = (
    message => $result->{output},
    project => $event->{change}{project},
    branch  => $event->{change}{branch},
    change  => $event->{change}{id},
  );

  for my $arg (qw(ssh_url http_url http_auth_cb)) {
    $review_args{$arg} = $self->{args}{$arg};
  }

  if ($result->{returned}) {
    if (ref($result->{returned}) eq 'HASH') {
      $review_args{reviewInput} = $result->{returned};
    } else {
      $review_args{$review} = $result->{returned};
    }
  }

  Gerrit::Client::review(
    $event->{patchSet}{revision},
    %review_args
  );
}

sub _dequeue_soon {
  my ($self) = @_;
  my $weakself = $self;
  weaken($weakself);
  $self->{_dequeue_timer} ||= AE::timer( .1, 0,
                                         sub {
                                           return unless $weakself;
                                           delete $weakself->{_dequeue_timer};
                                           $weakself->_dequeue();
                                         }
                                       );
}

sub _dequeue {
  my ($self) = @_;

  if ($Gerrit::Client::DEBUG) {
    _debug_print 'queue before processing: ', Dumper( $self->{queue} );
  }

  my $weakself = $self;
  weaken($weakself);

  my @queue = @{ $self->{queue} || [] };
  my @newqueue;
  while (my $event = shift @queue) {
    next unless $self->_ensure_git_cloned( $event, \@newqueue );
    next unless $self->_ensure_git_fetched( $event, \@newqueue, \@queue );
    next unless $self->_ensure_git_workdir_uptodate( $event, \@newqueue );
    $self->_do_callback( $event, \@newqueue );
  }

  $self->{queue} = \@newqueue;

  if ($Gerrit::Client::DEBUG) {
    _debug_print 'queue after processing: ', Dumper( $self->{queue} );
  }

  return;
}

1;
