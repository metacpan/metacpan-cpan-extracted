#############################################################################
##
## Copyright (C) 2012-2014 Rohan McGovern <rohan@mcgovern.id.au>
## Copyright (C) 2012 Digia Plc and/or its subsidiary(-ies)
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

=head1 NAME

Gerrit::Client - interact with Gerrit code review tool

=head1 SYNOPSIS

  use AnyEvent;
  use Gerrit::Client qw(stream_events);

  # alert me when new patch sets arrive in
  # ssh://gerrit.example.com:29418/myproject
  my $stream = stream_events(
    url => 'ssh://gerrit.example.com:29418',
    on_event => sub {
      my ($event) = @_;
      if ($event->{type} eq 'patchset-added'
          && $event->{change}{project} eq 'myproject') {
        system("xmessage", "New patch set arrived!");
      }
    }
  );

  AE::cv()->recv(); # must run an event loop for callbacks to be activated

This module provides some utility functions for interacting with the Gerrit code
review tool.

This module is an L<AnyEvent> user and may be used with any event loop supported
by AnyEvent.

=cut

package Gerrit::Client;
use strict;
use warnings;

use AnyEvent::HTTP;
use AnyEvent::Handle;
use AnyEvent::Util;
use AnyEvent;
use Capture::Tiny qw(capture);
use Carp;
use Data::Alias;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use English qw(-no_match_vars);
use File::Path;
use File::Spec::Functions;
use File::Temp;
use File::chdir;
use JSON;
use Params::Validate qw(:all);
use Scalar::Util qw(weaken);
use URI;
use URI::Escape;

use base 'Exporter';
our @EXPORT_OK = qw(
  for_each_patchset
  stream_events
  git_environment
  next_change_id
  random_change_id
  review
  query
  quote
);

our @GIT             = ('git');
our @SSH             = ('ssh');
our $VERSION         = 20140611;
our $DEBUG           = !!$ENV{GERRIT_CLIENT_DEBUG};
our $MAX_CONNECTIONS = 2;
our $MAX_FORKS       = 4;

sub _debug_print {
  return unless $DEBUG;
  print STDERR __PACKAGE__ . ': ', @_, "\n";
}

# parses a gerrit URL and returns a hashref with following keys:
#   cmd => arrayref, base ssh command for interacting with gerrit
#   project => the gerrit project name (e.g. "my/project")
sub _gerrit_parse_url {
  my ($url) = @_;

  if ( !ref($url) || !$url->isa('URI') ) {
    $url = URI->new($url);
  }

  if ( $url->scheme() ne 'ssh' ) {
    croak "gerrit URL $url is not supported; only ssh URLs are supported\n";
  }

  my $project = $url->path();
  $url->path(undef);

  # remove useless leading/trailing components
  $project =~ s{\A/+}{};
  $project =~ s{\.git\z}{}i;

  return {
    cmd => [
      @SSH,
      '-oBatchMode=yes',    # never do interactive prompts
      '-oServerAliveInterval=30'
      ,    # try to avoid the server silently dropping connection
      ( $url->port() ? ( '-p', $url->port() ) : () ),
      ( $url->user() ? ( $url->user() . '@' ) : q{} ) . $url->host(),
      'gerrit',
    ],
    project => $project,
    gerrit => $url->as_string(),
  };
}

# Like qx, but takes a list, so no quoting issues
sub _safeqx {
  my (@cmd) = @_;
  my $status;
  my $output = capture { $status = system(@cmd) };
  $? = $status;
  return $output;
}

=head1 FUNCTIONS

=over

=item B<< stream_events ssh_url => $gerrit_url, ... >>

Connect to "gerrit stream-events" on the given gerrit host and
register one or more callbacks for events. Returns an opaque handle to
the stream-events connection; the connection will be aborted if the
handle is destroyed.

$gerrit_url should be a URL with ssh schema referring to a valid
Gerrit installation (e.g. "ssh://user@gerrit.example.com:29418/").

Supported callbacks are documented below. All callbacks receive the
stream-events handle as their first argument.

=over

=item B<< on_event => $cb->($data) >>

Called when an event has been received.
$data is a reference to a hash representing the event.

See L<the Gerrit
documentation|http://gerrit.googlecode.com/svn/documentation/2.2.1/cmd-stream-events.html>
for information on the possible events.

=item B<< on_error => $cb->($error) >>

Called when an error occurs in the connection.
$error is a human-readable string.

Examples of errors include network disruptions between your host and
the Gerrit server, or the ssh process being killed
unexpectedly. Receiving any kind of error means that some Gerrit
events may have been lost.

If this callback returns a true value, stream_events will attempt to
reconnect to Gerrit and resume processing; otherwise, the connection
is terminated and no more events will occur.

The default error callback will warn and return 1, retrying on all
errors.

=back

=cut

sub stream_events {
  my (%args) = @_;

  $args{ssh_url} ||= $args{url};

  my $url      = $args{ssh_url}  || croak 'missing ssh_url argument';
  my $on_event = $args{on_event} || croak 'missing on_event argument';
  my $on_error = $args{on_error} || sub {
    my ($error) = @_;
    warn __PACKAGE__ . ": $error\n";
    return 1;
  };

  my $INIT_SLEEP = 2;
  my $MAX_SLEEP  = 60 * 10;
  my $sleep      = $INIT_SLEEP;

  my @ssh = ( @{ _gerrit_parse_url($url)->{cmd} }, 'stream-events' );

  my $cleanup = sub {
    my ($handle) = @_;
    delete $handle->{timer};
    foreach my $key (qw(r_h r_h_stderr)) {
      if ( my $r_h = delete $handle->{$key} ) {
        $r_h->destroy();
      }
    }
    if ( my $cv = delete $handle->{cv} ) {
      $cv->cb( sub { } );
      if ( my $pid = $handle->{pid} ) {
        kill( 15, $pid );
      }
    }
  };

  my $restart;
  my $out_weak;

  my $handle_error = sub {
    my ( $handle, $error ) = @_;
    my $retry;
    eval { $retry = $on_error->($error); };
    if ($retry) {

      # retry after $sleep seconds only
      $handle->{timer} =
        AnyEvent->timer( after => $sleep, cb => sub { $restart->($handle) } );
      $sleep *= 2;
      if ( $sleep > $MAX_SLEEP ) {
        $sleep = $MAX_SLEEP;
      }
    }
    else {
      $cleanup->($handle);
    }
  };

  $restart = sub {
    my ($handle) = @_;
    $cleanup->($handle);

    $sleep = $INIT_SLEEP;

    my ( $r,  $w )  = portable_pipe();
    my ( $r2, $w2 ) = portable_pipe();

    $handle->{r_h} = AnyEvent::Handle->new( fh => $r, );
    $handle->{r_h}->on_error(
      sub {
        my ( undef, undef, $error ) = @_;
        $handle_error->( $handle, $error );
      }
    );
    $handle->{r_h_stderr} = AnyEvent::Handle->new( fh => $r2, );
    $handle->{r_h_stderr}->on_error( sub { } );
    $handle->{warn_on_stderr} = 1;

    # run stream-events with stdout connected to pipe ...
    $handle->{cv} = run_cmd(
      \@ssh,
      '>'  => $w,
      '2>' => $w2,
      '$$' => \$handle->{pid},
    );
    $handle->{cv}->cb(
      sub {
        my ($status) = shift->recv();
        $handle_error->( $handle, "ssh exited with status $status" );
      }
    );

    my %read_req;
    %read_req = (

      # read one json item at a time
      json => sub {
        my ( $h, $data ) = @_;

        # every successful read resets sleep period
        $sleep = $INIT_SLEEP;

        $h->push_read(%read_req);
        $on_event->($data);
      }
    );
    $handle->{r_h}->push_read(%read_req);

    my %err_read_req;
    %err_read_req = (
      line => sub {
        my ( $h, $line ) = @_;

        if ( $handle->{warn_on_stderr} ) {
          warn __PACKAGE__ . ': ssh stderr: ' . $line;
        }
        $h->push_read(%err_read_req);
      }
    );
    $handle->{r_h_stderr}->push_read(%err_read_req);
  };

  my $stash = {};
  $restart->($stash);

  my $out = { stash => $stash };
  if ( defined wantarray ) {
    $out->{guard} = guard {
      $cleanup->($stash);
    };
    $out_weak = $out;
    weaken($out_weak);
  }
  else {
    $out_weak = $out;
  }
  return $out;
}

=item B<< for_each_patchset(ssh_url => $ssh_url, workdir => $workdir, ...) >>

Set up a high-level event watcher to invoke a custom callback or
command for each existing or incoming patch set on Gerrit. This method
is suitable for performing automated testing or sanity checks on
incoming patches.

For each patch set, a git repository is set up with the working tree
and HEAD set to the patch. The callback is invoked with the current
working directory set to the top level of this git repository.

Returns a guard object. Event processing terminates when the object is
destroyed.

Options:

=over

=item B<ssh_url>

The Gerrit ssh URL, e.g. C<ssh://user@gerrit.example.com:29418/>.
May also be specified as 'url' for backwards compatibility.
Mandatory.

=item B<http_url>

=item B<< http_auth_cb => $sub->($response_headers, $request_headers) >>

=item B<http_username>

=item B<http_password>

These arguments have the same meaning as for the L<review> function.
Provide them if you want to post reviews via REST.

=item B<workdir>

The top-level working directory under which git repositories and other data
should be stored. Mandatory. Will be created if it does not exist.

The working directory is persistent across runs. Removing the
directory may cause the processing of patch sets which have already
been processed.

=item B<< on_patchset => $sub->($change, $patchset) >>

=item B<< on_patchset_fork => $sub->($change, $patchset) >>

=item B<< on_patchset_cmd => $sub->($change, $patchset) | $cmd_ref >>

Callbacks invoked for each patchset. Only one of the above callback
forms may be used.

=over

=item *

B<on_patchset> invokes a subroutine in the current process. The callback
is blocking, which means that only one patch may be processed at a
time. This is the simplest form and is suitable when the processing
for each patch is expected to be fast or the rate of incoming patches
is low.

=item *

B<on_patchset_fork> invokes a subroutine in a new child process. The
child terminates when the callback returns. Multiple patches may be
handled in parallel.

The caveats which apply to C<AnyEvent::Util::run_cmd> also apply here;
namely, it is not permitted to run the event loop in the child process.

=item *

B<on_patchset_cmd> runs a command to handle the patch.
Multiple patches may be handled in parallel.

The argument to B<on_patchset_cmd> may be either a reference to an array
holding the command and its arguments, or a reference to a subroutine
which generates and returns an array for the command and its arguments.

B<Note:> since B<on_patchset_cmd> has no way to return a value, it
can't be used to generate ReviewInput objects for REST-based reviewing.
See below.

=back

All on_patchset callbacks receive B<change> and B<patchset> hashref arguments.
Note that a change may hold several patchsets.

Output and the returned value of the callbacks may be used for posting a review
back to Gerrit; see documentation of the C<review> argument below.

=item B<< on_error => $sub->($error) >>

Callback invoked when an error occurs. $error is a human-readable error string.

All errors are treated as recoverable. To abort on an error, explicitly undefine
the loop guard object from within the callback.

By default, a warning message is printed for each error.

=item B<< review => 0 | 1 | 'code-review' | 'verified' | ... >>

If false (the default), patch sets are not automatically reviewed
(though they may be reviewed explicitly within the B<on_patchset_...>
callbacks).

If true, patch sets are automatically reviewed according to the following:

=over

=item *

If an B<on_patchset_...> callback returned a ReviewInput hashref, a review
is done via REST (see the L<review> function).  Note that B<on_patchset_cmd>
doesn't support returning a value.

=item *

If an B<on_patchset_...> callback printed text on stdout/stderr, a review
is done via SSH using the text as the top-level review message.

=item *

If both of the above are true, the review is attempted by REST first,
and then via SSH if the REST review failed.  Therefore, writing a callback
to both print out a meaningful message I<and> return a ReviewInput hashref
enables a script to be portable across Gerrit versions with and without REST.

=back

See the B<REST vs SSH> discussion in the documentation for the L<review> function
for more information on choosing between REST or SSH.

If a string is passed, it is construed as a Gerrit approval category
and a review score will be posted in that category. The score comes
from the return value of the callback (or exit code in the case of
B<on_patchset_cmd>).  The returned value must be an integer, so this cannot
be combined with reviewing by REST, which requires callbacks to return a
hashref.

=item B<< on_review => $sub->( $change, $patchset, $message, $score, $returnvalue ) >>

Optional callback invoked prior to performing a review (when the `review'
option is set to a true value).

The callback should return a true value if the review should be
posted, false otherwise. This may be useful for the implementation of
a dry-run mode.

The callback may be invoked with an undefined $message and $score, which
indicates that a patchset was successfully processed but no message
or score was produced.

=item B<< wanted => $sub->( $change, $patchset ) >>

The optional `wanted' subroutine may be used to limit the patch sets processed.

If given, a patchset will only be processed if this callback returns a
true value. This can be used to avoid git clones of unwanted projects.

For example, patchsets for all Gerrit projects under a 'test/' namespace could
be excluded from processing by the following:

    wanted => sub { $_[0]->{project} !~ m{^test/} }

=item B<< git_work_tree => 0 | 1 >>

By default, while processing a patchset, a git work tree is set up
with content set to the appropriate revision.

C<< git_work_tree => 0 >> may be passed to disable the work tree, saving
some time and disk space. In this case, a bare clone is used, with HEAD
referring to the revision to be processed.

This may be useful when the patch set processing does not require a
work tree (e.g. the incoming patch is directly scanned).

Defaults to 1.

=item B<< query => $query | 0 >>

The Gerrit query used to find the initial set of patches to be
processed.  The query is executed when the loop begins and whenever
the connection to Gerrit is interrupted, to avoid missed patchsets.

Defaults to "status:open", meaning every open patch will be processed.

Note that the query is not applied to incoming patchsets observed via
stream-events. The B<wanted> parameter may be used for that case.

If a false value is passed, querying is disabled altogether. This
means only patchsets arriving while the loop is running will be
processed.

=back

=cut

sub for_each_patchset {
  my (%args) = @_;

  $args{ssh_url} ||= $args{url};
  if ($args{http_username} && $args{http_password}) {
    $args{http_auth_cb} ||= http_digest_auth($args{http_username}, $args{http_password});
  }

  $args{ssh_url} || croak 'missing ssh_url argument';
       $args{on_patchset}
    || $args{on_patchset_cmd}
    || $args{on_patchset_fork}
    || croak 'missing on_patchset{_cmd,_fork} argument';
  $args{workdir} || croak 'missing workdir argument';
  $args{on_error} ||= sub { warn __PACKAGE__, ': ', @_ };

  if ( !exists( $args{git_work_tree} ) ) {
    $args{git_work_tree} = 1;
  }

  if ( !exists( $args{query} ) ) {
    $args{query} = 'status:open';
  }

  if ( !-d $args{workdir} ) {
    mkpath( $args{workdir} );
  }

  # drop the path section of the URL to get base gerrit URL
  my $url = URI->new($args{ssh_url});
  $url->path( undef );
  $args{ssh_url} = $url->as_string();

  require "Gerrit/Client/ForEach.pm";
  my $self = bless {}, 'Gerrit::Client::ForEach';
  $self->{args} = \%args;

  my $weakself = $self;
  weaken($weakself);

  # stream_events takes care of incoming changes, perform a query to find
  # existing changes
  my $do_query = sub {
    return unless $args{query};

    query(
      $args{query},
      ssh_url           => $args{ssh_url},
      current_patch_set => 1,
      on_error          => sub { $args{on_error}->(@_) },
      on_success        => sub {
        return unless $weakself;
        my (@results) = @_;
        foreach my $change (@results) {

          # simulate patch set creation
          my ($event) = {
            type     => 'patchset-created',
            change   => $change,
            patchSet => delete $change->{currentPatchSet},
          };
          $weakself->_handle_for_each_event($event);
        }
      },
    );
  };

  # Unfortunately, we have no idea how long it takes between starting the
  # stream-events command and when the streaming of events begins, so if
  # we query straight away, we could miss some changes which arrive while
  # stream-events is e.g. still in ssh negotiation.
  # Therefore, introduce this arbitrary delay between when we start
  # stream-events and when we'll perform a query.
  my $query_timer;
  my $do_query_soon = sub {
    $query_timer = AE::timer( 4, 0, $do_query );
  };

  $self->{stream} = Gerrit::Client::stream_events(
    ssh_url  => $args{ssh_url},
    on_event => sub {
      $weakself->_handle_for_each_event(@_);
    },
    on_error => sub {
      my ($error) = @_;

      $args{on_error}->("connection lost: $error, attempting to recover\n");

      # after a few seconds to allow reconnect, perform the base query again
      $do_query_soon->();

      return 1;
    },
  );

  $do_query_soon->();

  return $self;
}

=item B<random_change_id>

Returns a random Change-Id (the character 'I' followed by 40
hexadecimal digits), suitable for usage as the Change-Id field in a
commit to be pushed to gerrit.

=cut

sub random_change_id {
  return 'I' . sprintf(

    # 40 hex digits, one 32 bit integer gives 8 hex digits,
    # therefore 5 random integers
    "%08x" x 5,
    map { rand() * ( 2**32 ) } ( 1 .. 5 )
  );
}

=item B<next_change_id>

Returns the 'next' Change-Id which should be used for a commit created
by the current git author/committer (which should be set by
L<git_environment|/git_environment-name-name-email-email-author_only-0-1->
prior to calling this method). The current working directory must be
within a git repository.

This method is suitable for usage within a script which periodically
creates commits for review, but should have only one outstanding
review (per branch) at any given time.  The returned Change-Id is
(hopefully) unique, and stable; it only changes when a new commit
arrives in the git repository from the current script.

For example, consider a script which is run once per day to clone a
repository, generate a change and push it for review. If this function
is used to generate the Change-Id on the commit, the script will
update the same change in gerrit until that change is merged. Once the
change is merged, next_change_id returns a different value, resulting
in a new change.  This ensures the script has a maximum of one pending
review any given time.

If any problems occur while determining the next Change-Id, a warning
is printed and a random Change-Id is returned.

=cut

sub next_change_id {
  if ( !$ENV{GIT_AUTHOR_NAME} || !$ENV{GIT_AUTHOR_EMAIL} ) {
    carp __PACKAGE__ . ': git environment is not set, using random Change-Id';
    return random_change_id();
  }

  # First preference: change id is the last SHA used by this bot.
  my $author    = "$ENV{GIT_AUTHOR_NAME} <$ENV{GIT_AUTHOR_EMAIL}>";
  my $change_id = _safeqx( @GIT, qw(rev-list -n1 --fixed-strings),
    "--author=$author", 'HEAD' );
  if ( my $error = $? ) {
    carp __PACKAGE__ . qq{: no previous commits from "$author" were found};
  }
  else {
    chomp $change_id;
  }

  # Second preference: for a stable but random change-id, use hash of the
  # bot name
  if ( !$change_id ) {
    my $tempfile = File::Temp->new(
      'perl-Gerrit-Client-hash.XXXXXX',
      TMPDIR  => 1,
      CLEANUP => 1
    );
    $tempfile->printflush($author);
    $change_id = _safeqx( @GIT, 'hash-object', "$tempfile" );
    if ( my $error = $? ) {
      carp __PACKAGE__ . qq{: git hash-object failed};
    }
    else {
      chomp $change_id;
    }
  }

  # Check if we seem to have this change id already.
  # This can happen if an author other than ourself has already used the
  # change id.
  if ($change_id) {
    my $found = _safeqx( @GIT, 'log', '-n1000', "--grep=I$change_id", 'HEAD' );
    if ( !$? && $found ) {
      carp __PACKAGE__ . qq{: desired Change-Id $change_id is already used};
      undef $change_id;
    }
  }

  if ($change_id) {
    return "I$change_id";
  }

  carp __PACKAGE__ . q{: falling back to random Change-Id};

  return random_change_id();
}

=item B<< git_environment(name => $name, email => $email,
                          author_only => [0|1] ) >>

Returns a copy of %ENV modified suitably for the creation of git
commits by a script/bot.

Options:

=over

=item B<name>

The human-readable name used for git commits. Mandatory.

=item B<email>

The email address used for git commits. Mandatory.

=item B<author_only>

If 1, the environment is only modified for the git I<author>, and not
the git I<committer>.  Depending on the gerrit setup, this may be
required to avoid complaints about missing "Forge Identity"
permissions.

Defaults to 0.

=back

When generating commits for review in gerrit, this method may be used
in conjunction with L</next_change_id> to ensure this bot has only one
outstanding change for review at any time, as in the following
example:

    local %ENV = git_environment(
        name => 'Indent Bot',
        email => 'indent-bot@example.com',
    );

    # fix up indenting in all the .cpp files
    (system('indent *.cpp') == 0) || die 'indent failed';

    # then commit and push them; commits are authored and committed by
    # 'Indent Bot <indent-bot@example.com>'.  usage of next_change_id()
    # ensures that this bot has a maximum of one outstanding change for
    # review
    my $message = "Fixed indentation\n\nChange-Id: ".next_change_id();
    (system('git add -u *.cpp') == 0)
      || die 'git add failed';
    (system('git', 'commit', '-m', $message) == 0)
      || die 'git commit failed';
    (system('git push gerrit HEAD:refs/for/master') == 0)
      || die 'git push failed';

=cut

sub git_environment {
  my (%options) = validate(
    @_,
    { name        => 1,
      email       => 1,
      author_only => 0,
    }
  );

  my %env = %ENV;

  $env{GIT_AUTHOR_NAME}  = $options{name};
  $env{GIT_AUTHOR_EMAIL} = $options{email};

  unless ( $options{author_only} ) {
    $env{GIT_COMMITTER_NAME}  = $options{name};
    $env{GIT_COMMITTER_EMAIL} = $options{email};
  }

  return %env;
}

my @GERRIT_LABELS = qw(
  code_review
  sanity_review
  verified
);

# options to Gerrit::review which map directly to options to
# "ssh <somegerrit> gerrit review ..."
my %GERRIT_REVIEW_OPTIONS = (
  abandon => { type => BOOLEAN, default => 0 },
  message => { type => SCALAR,  default => undef },
  project => { type => SCALAR,  default => undef },
  restore => { type => BOOLEAN, default => 0 },
  stage   => { type => BOOLEAN, default => 0 },
  submit  => { type => BOOLEAN, default => 0 },
  ( map { $_ => { regex => qr{^[-+]?\d+$}, default => undef } }
      @GERRIT_LABELS
  )
);

=item B<< review $revision, ssh_url => $ssh_url, http_url => $http_url ... >>

Post a gerrit review, either by the `gerrit review' command using
ssh, or via REST.

$revision is mandatory, and should be a git commit in full 40-digit form.
(Actually, a few other forms of $revision are accepted, but they are
deprecated - unabbreviated revisions are the only input which work for
both SSH and REST.)

$ssh_url should be a URL with ssh schema referring to a 
valid Gerrit installation (e.g. "ssh://user@gerrit.example.com:29418/").
The URL may optionally contain the relevant gerrit project.

$http_url should be an HTTP or HTTPS URL pointing at the base of a Gerrit
installation (e.g. "https://gerrit.example.com/").

At least one of $ssh_url or $http_url must be provided.

=over

B<REST vs SSH>

In Gerrit 2.6, it became possible to post reviews onto patch sets using
a new REST API. In earlier versions of gerrit, only the `gerrit review'
command may be used.

Reviewing by REST has a significant advantage over `gerrit review':
comments may be posted directly onto the relevant lines of a patch.
`gerrit review' in contrast only supports setting a top-level message.

Gerrit::Client supports posting review comments both by REST and
`gerrit review'. Most scripts will most likely prefer to use REST due
to the improved review granularity.

To review by REST:

=over

=item *

Provide the C<http_url> argument, and most likely C<http_username> and C<http_password>.

=item *

Provide the C<project> and C<branch> arguments.

=item *

Provide the C<reviewInput> argument as a hash with the correct structure.
(See documentation below.)

=back

To review by SSH:

=over

=item *

Provide the C<ssh_url> argument.

=item *

Provide the C<message> argument, and one or more of the score-related
arguments.

=back

To review by REST where supported, with fallback to SSH if REST
is unavailable (e.g on Gerrit < 2.6), provide all of the arguments
listed above.  C<message> will only be used if reviewing by REST was
not available.

=back

Other arguments to this method include:

=over

=item B<< http_auth_cb => $sub->($response_headers, $request_headers) >>

A callback invoked when HTTP authentication to Gerrit is required.
The callback receives HTTP headers from the 401 Unauthorized response
in $response_headers, and should add corresponding request headers
(such as Authorization) into $request_headers.

$response_headers also includes the usual AnyEvent::HTTP psuedo-headers,
and one additional psuedo-header, Method, which is the HTTP method being
used (i.e. "POST").

The callback must return true if it was able to provide the necessary
authentication headers.  It should return false if authentication failed.

See also C<http_username>, C<http_password> and C<Gerrit::Client::http_digest_auth>,
to use the Digest-based authentication used by default in Gerrit.

=item B<http_username>

=item B<http_password>

Passing these values is a shortcut for:

  http_auth_cb => Gerrit::Client::http_digest_auth($username, $password)

... which uses Gerrit's default Digest-based authentication.

=item B<< reviewInput => $hashref >>

A ReviewInput object as used by Gerrit's REST API.

This is a simple data structure of the following form:

  {
    message => "Some nits need to be fixed.",
    labels => {
      'Code-Review' => -1
    },
    comments => {
      'gerrit-server/src/main/java/com/google/gerrit/server/project/RefControl.java' => [
        {
          line => 23,
          message => '[nit] trailing whitespace'
        },
        {
          line => 49,
          message => "[nit] s/conrtol/control"
        }
      ]
    }
  }

This value is only used if reviewing via REST.

=item B<< message => $string >>

Top-level review message.

This value is only used if reviewing via SSH, or if REST reviewing was
attempted but failed.

=item B<< project => $string >>

=item B<< branch => $string >>

Project and branch values for the patch set to be reviewed.

If reviewing via SSH, these are only necessary if the patch set can't
be unambiguously located by its git revision alone. If reviewing via
REST, these are always necessary.

In any case, it's recommended to always provide these.

=item B<< on_success => $cb->() >>

=item B<< on_error => $cb->( $error ) >>

Callbacks invoked when the operation succeeds or fails.

=item B<< abandon => 1|0 >>

=item B<< restore => 1|0 >>

=item B<< stage => 1|0 >>

=item B<< submit => 1|0 >>

=item B<< code_review => $number >>

=item B<< sanity_review => $number >>

=item B<< verified => $number >>

Most of these options are passed to the `gerrit review' command.  For
information on their usage, please see the output of `gerrit review
--help' on your gerrit installation, or see L<the Gerrit
documentation|http://gerrit.googlecode.com/svn/documentation/2.2.1/cmd-review.html>.

Note that certain options can be disabled on a per-site basis.
`gerrit review --help' will show only those options which are enabled
on the given site.

=back

=cut

sub review {
  my $commit_or_change = shift;
  my (%options) = validate(
    @_,
    { url        => 0,
      ssh_url    => 0,
      http_url   => 0,
      http_auth_cb => 0,
      http_username => 0,
      http_password => 0,
      change     => 0,
      branch     => 0,
      reviewInput => { type => HASHREF, default => undef },
      on_success => { type => CODEREF, default => undef },
      on_error   => {
        type    => CODEREF,
        default => sub {
          warn __PACKAGE__ . "::review: error: ", @_;
          }
      },
      %GERRIT_REVIEW_OPTIONS,
    }
  );

  $options{ssh_url} ||= $options{url};

  if (!$options{ssh_url} && !$options{http_url}) {
    croak 'called without SSH or HTTP URL';
  }

  if (!$options{http_auth_cb} && $options{http_username} && $options{http_password}) {
    $options{http_auth_cb} = Gerrit::Client::http_digest_auth($options{http_username}, $options{http_password});
  }

  if ($options{ssh_url}) {
    $options{parsed_url} = _gerrit_parse_url( $options{ssh_url} );
    # project can be filled in by explicit 'project' argument, or from
    # URL, or left blank
    $options{project} ||= $options{parsed_url}{project};
    if ( !$options{project} ) {
      delete $options{project};
    }
  }

  if ($options{reviewInput}) {
    return _review_by_rest_then_ssh($commit_or_change, \%options)
  }

  return _review_by_ssh($commit_or_change, \%options);
}

sub _review_by_rest_then_ssh {
  my ($commit, $options) = @_;

  foreach my $opt (qw(project branch http_url change)) {
    if (!$options->{$opt}) {
      croak "Attempted to do review by REST with missing $opt argument";
    }
  }

  unless ($commit =~ /^[a-fA-F0-9]+$/) {
    croak "Invalid revision: $commit. For REST review, must specify a valid git revision";
  }

  my $data = $options->{reviewInput};

  my $jsondata = encode_json($data);

  my $url = join('/',
    $options->{http_url},
    'a',
    'changes',
    uri_escape(join('~', $options->{project}, $options->{branch}, $options->{change})),
    'revisions',
    $commit,
    'review',
  );

  _debug_print "Posting to $url ...\n";

  my $tried_auth = 0;

  my %post_args = (
    headers => { 'Content-Type' => 'application/json;charset=UTF-8' },
    recurse => 5,
  );

  my $handle_response;
  my $do_http_call;

  my $handle_no_rest = sub {
    _debug_print "Post to $url returned 404. Fall through to ssh...";
    return _review_by_ssh($commit, $options);
  };

  my $handle_ok = sub {
    _debug_print "Post to $url returned OK. Fall through to ssh...";
    if ($data->{message} || $data->{comments}) {
      delete $options->{message};
    }
    if ($data->{labels}) {
      foreach my $lbl (@GERRIT_LABELS) {
        delete $options->{$lbl};
      }
    }

    return _review_by_ssh($commit, $options);
  };

  my $handle_err = sub {
    my ($body, $hdr) = @_;
    my $errstr = "POST $url: $hdr->{Status} $hdr->{Reason}\n$body";
    if ($options->{on_error} ) {
      $options->{on_error}->($errstr);
    }
    _debug_print "POST to $url returned errors: " . Dumper($hdr);
  };

  my $handle_auth = sub {
    my ($body, $hdr) = @_;

    $tried_auth = 1;

    $hdr->{Method} = 'POST';

    if ($options->{http_auth_cb}->($hdr, $post_args{headers})) {
      _debug_print "Repeating POST to $url after auth";
      $do_http_call->();
    } else {
      warn __PACKAGE__ . ': HTTP authentication callback failed.';
      $handle_err->($body, $hdr);
    }
  };

  if (!$options->{http_auth_cb}) {
    $handle_auth = undef;
    _debug_print "No HTTP authentication callback.";
  }

  $handle_response = sub {
    my ($body, $hdr) = @_;

    if ($hdr->{Status} =~ /^2/) {
      $handle_ok->($body, $hdr);
      return;
    }

    if ($hdr->{Status} eq '404') {
      $handle_no_rest->($body, $hdr);
      return;
    }

    if ($hdr->{Status} eq '401' && !$tried_auth && $handle_auth) {
      $handle_auth->($body, $hdr);
      return;
    }
  
    # failed!
    $handle_err->($body, $hdr);
  };

  $do_http_call = sub { http_post($url, $jsondata, %post_args, $handle_response) };
  $do_http_call->();
  
  return;
}

sub _review_by_ssh {
  my ($commit_or_change, $options) = @_;

  my $parsed_url = $options->{parsed_url};
  my @cmd = ( @{ $parsed_url->{cmd} }, 'review', $commit_or_change, );

  while ( my ( $key, $spec ) = each %GERRIT_REVIEW_OPTIONS ) {
    my $value = $options->{$key};

    # code_review -> --code-review
    my $cmd_key = $key;
    $cmd_key =~ s{_}{-}g;
    $cmd_key = "--$cmd_key";

    if ( $spec->{type} && $spec->{type} eq BOOLEAN ) {
      if ($value) {
        push @cmd, $cmd_key;
      }
    }
    elsif ( defined($value) ) {
      push @cmd, $cmd_key, quote($value);
    }
  }

  my $cv = AnyEvent::Util::run_cmd( \@cmd );

  my $cmdstr;
  {
    local $LIST_SEPARATOR = '] [';
    $cmdstr = "[@cmd]";
  }

  $cv->cb(
    sub {
      my $status = shift->recv();
      if ( $status && $options->{on_error} ) {
        $options->{on_error}->("$cmdstr exited with status $status");
      }
      if ( !$status && $options->{on_success} ) {
        $options->{on_success}->();
      }

      # make sure we stay alive until this callback is executed
      undef $cv;
    }
  );

  return;
}

# options to Gerrit::Client::query which map directly to options to
# "ssh <somegerrit> gerrit query ..."
my %GERRIT_QUERY_OPTIONS = (
  ( map { $_ => { type => BOOLEAN, default => 0 } }
      qw(
      all_approvals
      comments
      commit_message
      current_patch_set
      dependencies
      files
      patch_sets
      submit_records
      )
  )
);

=item B<< query $query, ssh_url => $gerrit_url, ... >>

Wrapper for the `gerrit query' command; send a query to gerrit
and invoke a callback with the results.

$query is the Gerrit query string, whose format is described in L<the
Gerrit
documentation|https://gerrit.googlecode.com/svn/documentation/2.2.1/user-search.html>.
"status:open age:1w" is an example of a simple Gerrit query.

$gerrit_url is the URL with ssh schema of the Gerrit site to be queried
(e.g. "ssh://user@gerrit.example.com:29418/").
If the URL contains a path (project) component, it is ignored.

All other arguments are optional, and include:

=over

=item B<< on_success => $cb->( @results ) >>

Callback invoked when the query completes.

Each element of @results is a hashref representing a Gerrit change,
parsed from the JSON output of `gerrit query'. The format of Gerrit
change objects is described in L<the Gerrit documentation|
https://gerrit.googlecode.com/svn/documentation/2.2.1/json.html>.

=item B<< on_error => $cb->( $error ) >>

Callback invoked when the query command fails.
$error is a human-readable string describing the error.

=item B<< all_approvals => 0|1 >>

=item B<< comments => 0|1 >>

=item B<< commit_message => 0|1 >>

=item B<< current_patch_set => 0|1 >>

=item B<< dependencies => 0|1 >>

=item B<< files => 0|1 >>

=item B<< patch_sets => 0|1 >>

=item B<< submit_records => 0|1 >>

These options are passed to the `gerrit query' command and may be used
to increase the level of information returned by the query.
For information on their usage, please see the output of `gerrit query
--help' on your gerrit installation, or see L<the Gerrit
documentation|http://gerrit.googlecode.com/svn/documentation/2.2.1/cmd-query.html>.

=back

=cut

sub query {
  my $query = shift;
  my (%options) = validate(
    @_,
    { url        => 0,
      ssh_url    => 0,
      on_success => { type => CODEREF, default => undef },
      on_error   => {
        type    => CODEREF,
        default => sub {
          warn __PACKAGE__ . "::query: error: ", @_;
          }
      },
      %GERRIT_QUERY_OPTIONS,
    }
  );

  $options{ssh_url} ||= $options{url};

  my $parsed_url = _gerrit_parse_url( $options{ssh_url} );
  my @cmd = ( @{ $parsed_url->{cmd} }, 'query', '--format', 'json' );

  while ( my ( $key, $spec ) = each %GERRIT_QUERY_OPTIONS ) {
    my $value = $options{$key};
    next unless $value;

    # some_option -> --some-option
    my $cmd_key = $key;
    $cmd_key =~ s{_}{-}g;
    $cmd_key = "--$cmd_key";

    push @cmd, $cmd_key;
  }

  push @cmd, quote($query);

  my $output;
  my $cv = AnyEvent::Util::run_cmd( \@cmd, '>' => \$output );

  my $cmdstr;
  {
    local $LIST_SEPARATOR = '] [';
    $cmdstr = "[@cmd]";
  }

  $cv->cb(
    sub {
      # make sure we stay alive until this callback is executed
      undef $cv;

      my $status = shift->recv();
      if ( $status && $options{on_error} ) {
        $options{on_error}->("$cmdstr exited with status $status");
        return;
      }

      return unless $options{on_success};

      my @results;
      foreach my $line ( split /\n/, $output ) {
        my $data = eval { decode_json($line) };
        if ($EVAL_ERROR) {
          $options{on_error}->("error parsing result `$line': $EVAL_ERROR");
          return;
        }
        next if ( $data->{type} && $data->{type} eq 'stats' );
        push @results, $data;
      }

      $options{on_success}->(@results);
      return;
    }
  );

  return;
}

=item B<< quote $string >>

Returns a copy of the input string with special characters escaped, suitable
for usage with Gerrit CLI commands.

Gerrit commands run via ssh typically need extra quoting because the ssh layer
already evaluates the command string prior to passing it to Gerrit.
This function understands how to quote arguments for this case.

B<Note:> do not use this function for passing arguments to other Gerrit::Client
functions; those perform appropriate quoting internally.

=cut

sub quote {
  my ($string) = @_;

  # character set comes from gerrit source:
  # gerrit-sshd/src/main/java/com/google/gerrit/sshd/CommandFactoryProvider.java
  # 'split' function
  $string =~ s{([\t "'\\])}{\\$1}g;
  return $string;
}

=item B<< http_digest_auth($username, $password) >>

Returns a callback to be used with REST-related Gerrit::Client functions.
The callback enables Digest-based HTTP authentication with the given
credentials.

Note that only the Digest scheme used by Gerrit (as of 2.8) is supported:
algorithm = MD5, qop = auth.

=cut
sub http_digest_auth {
  my ($username, $password, %args) = @_;

  my $cnonce_cb = $args{cnonce_cb} || sub {
    sprintf("%08x", rand() * ( 2**32 ));
  };

  my %noncecount;

  return sub {
    my ($in_headers, $out_headers) = @_;

    my $authenticate = $in_headers->{'www-authenticate'};
    if (!$authenticate || !($authenticate =~ /^Digest /)) {
      warn __PACKAGE__ . ': server did not offer digest authentication';
      return;
    }

    $authenticate =~ s/^Digest //;

    my %attr;
    while ($authenticate =~ /([a-zA-Z0-9\-]+)="([^"]+)"(,\s*)?/g) {
      $attr{$1} = $2;
    }

    if ($attr{qop}) {
      $attr{qop} = [ split(/,/, $attr{qop}) ];
    }

    $attr{algorithm} ||= 'MD5';
    $attr{qop} ||= [];

    _debug_print "digest attrs with defaults filled: "  . Dumper(\%attr);

    unless (grep {$_ eq 'auth'} @{$attr{qop}}) {
      warn __PACKAGE__ . ": server didn't offer qop=auth for digest authentication";
      return;
    }

    unless ($attr{algorithm} eq 'MD5') {
      warn __PACKAGE__ . ": server didn't offer algorithm=MD5 for digest authentication";
    }

    my $nonce = $attr{nonce};
    my $cnonce = $cnonce_cb->();

    $noncecount{$nonce} = ($noncecount{$nonce}||0) + 1;
    my $count = $noncecount{$nonce};
    my $count_hex = sprintf("%08x", $count);

    my $uri = URI->new($in_headers->{URL})->path;
    my $method = $in_headers->{Method};
    _debug_print "uri $uri method $method\n";

    my $ha1 = md5_hex($username, ':', $attr{realm}, ':', $password);
    my $ha2 = md5_hex($method, ':', $uri);
    my $response = md5_hex($ha1, ':', $nonce, ':', $count_hex, ':', $cnonce, ':', 'auth', ':', $ha2);

    my $authstr = qq(Digest username="$username", realm="$attr{realm}", nonce="$nonce", uri="$uri", )
                 .qq(cnonce="$cnonce", nc=$count_hex, qop="auth", response="$response");
    
    _debug_print "digest auth: $authstr\n";

    $out_headers->{Authorization} = $authstr;
    return 1;
  }
}

=back

=head1 VARIABLES

=over

=item B<@Gerrit::Client::SSH>

The ssh command and initial arguments used when Gerrit::Client invokes
ssh.

  # force IPv6 for this connection
  local @Gerrit::Client::SSH = ('ssh', '-oAddressFamily=inet6');
  my $stream = Gerrit::Client::stream_events ...

The default value is C<('ssh')>.

=item B<@Gerrit::Client::GIT>

The git command and initial arguments used when Gerrit::Client invokes
git.

  # use a local object cache to speed up initial clones
  local @Gerrit::Client::GIT = ('env', "GIT_ALTERNATE_OBJECT_DIRECTORIES=$ENV{HOME}/gitcache", 'git');
  my $guard = Gerrit::Client::for_each_patchset ...

The default value is C<('git')>.

=item B<$Gerrit::Client::MAX_CONNECTIONS>

Maximum number of simultaneous git connections Gerrit::Client may make
to a single Gerrit server. The amount of parallel git clones and
fetches should be throttled, otherwise the Gerrit server may drop
incoming connections.

The default value is C<2>.

=item B<$Gerrit::Client::MAX_FORKS>

Maximum number of processes allowed to run simultaneously for handling
of patchsets in for_each_patchset. This limit applies only to local
work processes, not git clones or fetches from gerrit.

Note that C<$AnyEvent::Util::MAX_FORKS> may also impact the maximum number
of processes. C<$AnyEvent::Util::MAX_FORKS> should be set higher than or
equal to C<$Gerrit::Client::MAX_FORKS>.

The default value is C<4>.

=item B<$Gerrit::Client::DEBUG>

If set to a true value, various debugging messages will be printed to
standard error.  May be set by the GERRIT_CLIENT_DEBUG environment
variable.

=back

=head1 AUTHOR

Rohan McGovern, <rohan@mcgovern.id.au>

=head1 COMPATIBILITY

Gerrit::Client has been known to work with Gerrit 2.2.2.1, Gerrit 2.6-rc1,
and Gerrit 2.8.5 and hence could reasonably be expected to work with any
gerrit version in that range.

Please note that different Gerrit versions may represent objects in
slightly incompatible ways (e.g. "CRVW" vs "Code-Review" strings in
event objects). Gerrit::Client does not insulate the caller against
these changes.

=head1 BUGS

Please use L<https://github.com/rohanpm/Gerrit-Client/issues>
to view or report bugs.

When reporting a reproducible bug, please include the output of your
program with the environment variable GERRIT_CLIENT_DEBUG set to 1.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2014 Rohan McGovern <rohan@mcgovern.id.au>

Copyright (C) 2012 Digia Plc and/or its subsidiary(-ies)

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License version
2.1 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA.

=cut

1;
