package Langertha::Raider::BashTools;
# ABSTRACT: Internal shell tools of raider: bash, bash_output, kill_shell and monitor
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Encode ();
use Future;
use Future::AsyncAwait;
use JSON::MaybeXS ();
use Langertha::Raider::Monitor;
use List::Util qw( min );
use MCP::Server;
use Path::Tiny;
use POSIX qw( WNOHANG );
use Scalar::Util qw( looks_like_number weaken );
use Time::HiRes ();


has loop => (
  is       => 'ro',
  isa      => 'IO::Async::Loop',
  required => 1,
);


has working_directory => (
  is  => 'ro',
  isa => 'Str',
);


has allowed_commands => (
  is        => 'ro',
  isa       => 'ArrayRef[Str]',
  predicate => 'has_allowed_commands',
);


has validator => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_validator',
);


has tasks => (
  is        => 'ro',
  isa       => 'Langertha::Raider::Tasks',
  predicate => 'has_tasks',
);


has default_timeout => ( is => 'ro', isa => 'Int', default => 120 );


has max_timeout => ( is => 'ro', isa => 'Int', default => 600 );


has output_limit => ( is => 'ro', isa => 'Int', default => 30000 );


has kill_grace => ( is => 'ro', isa => 'Num', default => 2 );


has block_timeout => ( is => 'ro', isa => 'Int', default => 30 );


has monitor_timeout => ( is => 'ro', isa => 'Int', default => 300 );


has monitor_max_timeout => ( is => 'ro', isa => 'Int', default => 1800 );


has monitor_unattended_max_timeout => ( is => 'ro', isa => 'Int', default => 600 );


has unattended => ( is => 'ro', isa => 'CodeRef', predicate => 'has_unattended' );


has monitor_min_timeout => ( is => 'ro', isa => 'Num', default => 1 );


has monitor_options => ( is => 'ro', isa => 'HashRef', default => sub { {} } );


has server => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_server',
  init_arg => undef,
);


has _shells => ( is => 'ro', isa => 'HashRef', default => sub { {} }, init_arg => undef );
has _count  => ( is => 'rw', isa => 'Int', default => 0, init_arg => undef );
has _dir    => ( is => 'ro', lazy => 1, builder => '_build__dir', init_arg => undef );
has _quiet  => ( is => 'rw', isa => 'Bool', default => 0, init_arg => undef );
has _monitors => ( is => 'ro', isa => 'HashRef', default => sub { {} }, init_arg => undef );

sub _build__dir { Path::Tiny->tempdir( TEMPLATE => 'raider-bash-XXXXXXXX' ) }

#### Texts

sub _no_output { '(Bash completed with no output)' }

sub _hint {
  my ( $self, $id ) = @_;
  return ( $self->has_tasks ? 'You will be notified when it completes. ' : '' )
    .'Read its output and see whether it has finished with bash_output (bash_id: '.$id
    .'); stop it with kill_shell (shell_id: '.$id.').';
}

sub _no_shell { 'No task found with ID: '.$_[1] }

#### The server

sub _build_server {
  my ( $self ) = @_;
  weaken( my $weak = $self );
  my $call = sub {
    my ( $method ) = @_;
    return sub {
      my ( $tool, $in ) = @_;
      return $tool->text_result( 'the shell tools are gone', 1 ) unless $weak;
      return $tool->text_result( $weak->$method( $in // {} ) );
    };
  };
  my $server = MCP::Server->new( name => 'raider-bash', version => '1.0' );
  $server->tool(
    name         => 'bash',
    description  => 'Run a shell command with bash -c in the project root. Returns the combined output (stdout and stderr); '
      .'a failing command is an error result that starts with "Exit code N". timeout is in seconds (default '
      .$self->default_timeout.', at most '.$self->max_timeout.'); a command still running then is moved to the background. '
      .'run_in_background: true starts it in the background at once. A background command is read with bash_output and '
      .'stopped with kill_shell. Use this for ls, grep, find, git, cat, running tests, any shell pipeline '
      .'-- anything you would type at a terminal.',
    input_schema => {
      type       => 'object',
      properties => {
        command           => { type => 'string',  description => 'The command to run' },
        description       => { type => 'string',  description => 'What the command does, in a few words' },
        timeout           => { type => 'integer', description => 'Seconds before the command is moved to the background (default '
          .$self->default_timeout.', at most '.$self->max_timeout.')' },
        run_in_background => { type => 'boolean', description => 'Start the command in the background and return its ID at once' },
        working_directory => { type => 'string',  description => 'Directory to run in (default: the project root)' },
      },
      required => ['command'],
    },
    code => $call->('bash'),
  );
  $server->tool(
    name         => 'bash_output',
    description  => 'Read the output a background shell has written since the last call, with its status (running, '
      .'completed, killed) and, once it has finished, its exit code. filter: a regex; only matching lines are '
      .'returned, the others are discarded. block: true waits until the command has finished, at most timeout '
      .'seconds (default '.$self->block_timeout.', at most '.$self->max_timeout.').'
      .( $self->has_tasks ? ' Given an agent ID (or an agent\'s name), it answers with the agent\'s status and, once '
        .'it has ended, its report; block waits for its end.' : '' ),
    input_schema => {
      type       => 'object',
      properties => {
        bash_id => { type => 'string',  description => 'The ID of the background shell'
          .( $self->has_tasks ? ' (or of an agent)' : '' ) },
        filter  => { type => 'string',  description => 'Regex: only lines matching it are returned' },
        block   => { type => 'boolean', description => 'Wait until the command has finished' },
        timeout => { type => 'integer', description => 'With block: the most seconds to wait' },
      },
      required => ['bash_id'],
    },
    code => $call->('bash_output'),
  );
  $server->tool(
    name         => 'kill_shell',
    description  => 'Stop a background shell by its ID: SIGTERM to its process group, SIGKILL after '
      .$self->kill_grace.' seconds.'
      .( $self->has_tasks ? ' Given an agent ID (or an agent\'s name), it stops that agent.' : '' ),
    input_schema => {
      type       => 'object',
      properties => {
        shell_id => { type => 'string', description => 'The ID of the background shell to stop'
          .( $self->has_tasks ? ' (or of an agent)' : '' ) },
      },
      required => ['shell_id'],
    },
    code => $call->('kill_shell'),
  );
  $server->tool(
    name         => 'monitor',
    description  => 'Start a background monitor that streams events from a long-running command or script. Each line the '
      .'command writes to stdout is an event, delivered to you as a notification while you keep working -- do not poll or '
      .'sleep. Use it to watch a log for errors, a build, a test run, the status of a PR or a job, files that change: '
      .'anything you would otherwise check in a loop. The command runs with bash -c in the project root, under the same '
      .'rules as bash (permissions, loadguard). Lines that arrive close together are delivered as one notification; '
      .'stderr is not delivered. Filter the stream so that only what matters is printed (grep --line-buffered, or a '
      .'poll loop that prints when something changed): a monitor that sends too many events is stopped. The watch ends '
      .'when the command exits, at the deadline timeout_ms (default '.( $self->monitor_timeout * 1000 ).', at most '
      .( $self->monitor_max_timeout * 1000 ).'; at most '.( $self->monitor_unattended_max_timeout * 1000 )
      .' in a run with a single prompt and nobody to talk to) with one notice so that you can start it again, or when '
      .'you stop it with kill_shell (shell_id: the monitor\'s ID).',
    input_schema => {
      type       => 'object',
      properties => {
        description => { type => 'string', description => 'Short human-readable description of what you are monitoring (shown in notifications).' },
        timeout_ms  => { type => 'number', minimum => 1000, maximum => 3600000, default => $self->monitor_timeout * 1000,
          description => 'Kill the monitor after this deadline. Default '.( $self->monitor_timeout * 1000 ).'ms. Deadlines above '
            .( $self->monitor_max_timeout * 1000 ).'ms are capped to '.( $self->monitor_max_timeout * 1000 )
            .'ms. You are notified at expiry and can re-arm.' },
        command     => { type => 'string', description => 'Shell command or script. Each stdout line is an event; exit ends the watch.' },
      },
      required => [ 'description', 'command' ],
    },
    code => $call->('monitor'),
  ) if $self->has_tasks;
  return $server;
}

#### bash


sub bash {
  my ( $self, $in, $caller ) = @_;
  $caller //= {};
  my $command = $in->{command};
  return ( 'No command given: the command parameter must be a non-empty string', 1 )
    unless defined $command && $command =~ /\S/;
  my $wd = $in->{working_directory} // $caller->{working_directory} // $self->working_directory;
  if ( my $refused = $self->_refusal( $command, $wd ) ) {
    return ( $refused, 1 );
  }
  my $shell = $self->_spawn( $command, $wd );
  return ( 'Cannot start bash: '.$shell, 1 ) unless ref $shell;
  $shell->{description} = $in->{description} if defined $in->{description} && !ref $in->{description}
    && $in->{description} =~ /\S/;
  $shell->{recipient}   = $caller->{recipient} // 'main';
  $shell->{tool_use_id} = $caller->{call};
  $shell->{detached}    = $caller->{detached} ? 1 : 0;

  if ( $in->{run_in_background} ) {
    $self->_adopt($shell);
    return ( 'Command running in background with ID: '.$shell->{id}.'. '.$self->_hint( $shell->{id} ), 0 );
  }

  my $timeout = $self->_seconds( $in->{timeout}, $self->default_timeout );
  unless ( $self->_wait( $shell, $timeout, 1 ) ) {
    $self->_adopt($shell);
    return ( 'Command did not complete within its '.$timeout.'s timeout and was moved to the background (ID: '
      .$shell->{id}.'). '.$self->_hint( $shell->{id} ), 0 );
  }
  my $output = $self->_clip( $self->_take_output( $shell, 1 ) =~ s/[\r\n]+\z//r );
  $self->_forget($shell);
  if ( $shell->{status} eq 'killed' ) {
    return ( 'Command was stopped before it finished'.( length $output ? "\n".$output : '' ), 1 );
  }
  return ( length $output ? $output : $self->_no_output, 0 ) if $shell->{exit_code} == 0;
  return ( 'Exit code '.$shell->{exit_code}.( length $output ? "\n".$output : '' ), 1 );
}

# The text of a refusal by allowed_commands or the validator, or nothing.
sub _refusal {
  my ( $self, $command, $wd ) = @_;
  if ( $self->has_allowed_commands ) {
    my ( $first ) = $command =~ /^\s*(\S+)/;
    return 'Command not allowed: '.$first unless grep { $_ eq $first } @{ $self->allowed_commands };
  }
  if ( $self->has_validator ) {
    my $verdict = $self->validator->( $command, $wd );
    return if defined $verdict && !ref $verdict && $verdict eq '1';
    return 'Command '.( defined $verdict && length $verdict ? $verdict : 'denied' );
  }
  return;
}

# A usable number of seconds: whole, at least 1, at most max_timeout; the
# default for anything else.
sub _seconds {
  my ( $self, $value, $default ) = @_;
  return $default unless defined $value && looks_like_number($value) && $value == $value && $value > 0;
  return min( $self->max_timeout, $value < 1 ? 1 : int $value );
}

#### Processes

# Starts the command; returns the shell (a hash) or the reason it could not.
sub _spawn {
  my ( $self, $command, $wd ) = @_;
  my $n    = $self->_count + 1;
  $self->_count($n);
  my $id   = 'bash_'.$n;
  my $file = $self->_dir->child( $id.'.output' );
  open my $out, '>', "$file" or return 'cannot write '.$file.': '.$!;
  my $pid = fork;
  return 'fork: '.$! unless defined $pid;
  unless ($pid) {
    # The child: into a process group of its own (stopping it reaches every
    # process it starts), the signals back to their defaults, one file for
    # both outputs.
    eval { setpgrp( 0, 0 ) };
    $SIG{$_} = 'DEFAULT' for grep { exists $SIG{$_} } qw( INT TERM HUP QUIT PIPE CHLD ALRM );
    open STDIN,  '<',  '/dev/null';
    open STDOUT, '>&', $out;
    open STDERR, '>&', $out;
    # chdir, not "cd DIR && COMMAND": a command ending in & would take the cd
    # into the background with it and run the rest elsewhere.
    if ( defined $wd && length $wd && !chdir $wd ) {
      print STDERR 'raider: cannot change to '.$wd.': '.$!."\n";
      POSIX::_exit(1);
    }
    { no warnings 'exec'; exec 'bash', '-c', $command; }
    print STDERR 'raider: cannot run bash: '.$!."\n";
    POSIX::_exit(127);
  }
  close $out;
  my $shell = {
    id        => $id,
    command   => $command,
    pid       => $pid,
    file      => $file,
    offset    => 0,
    status    => 'running',
    started   => Time::HiRes::time(),
  };
  $self->_shells->{$id} = $shell;
  return $shell;
}

# Hands a running shell to the loop, which reaps it when it ends while the
# loop runs; bash_output and kill_shell look themselves.
sub _adopt {
  my ( $self, $shell ) = @_;
  $shell->{background} = 1;
  return unless $shell->{status} eq 'running';
  $self->_register($shell);
  weaken( my $weak = $self );
  $shell->{watched} = 1;
  $self->loop->watch_process( $shell->{pid}, sub {
    my ( undef, $status ) = @_;
    $shell->{watched} = 0;
    $weak->_ended( $shell, $status ) if $weak;
  } );
  return;
}

# True when the shell has ended (and is reaped).
sub _poll {
  my ( $self, $shell ) = @_;
  return 1 unless $shell->{status} eq 'running';
  my $got = waitpid( $shell->{pid}, WNOHANG );
  return 0 if $got == 0;
  if ( $got == $shell->{pid} ) {
    $self->_unwatch($shell);
    $self->_ended( $shell, $? );
    return 1;
  }
  # Reaped by someone else: by the loop, which may only have queued its
  # callback yet (watch_process reaps a child that is gone already), or by the
  # surface stopping the children of a cancelled run.
  $self->loop->loop_once(0) if $shell->{watched} && ${^GLOBAL_PHASE} ne 'DESTRUCT';
  $self->_unwatch($shell);
  $self->_ended( $shell, undef ) if $shell->{status} eq 'running';
  return 1;
}

sub _unwatch {
  my ( $self, $shell ) = @_;
  return unless delete $shell->{watched};
  eval { $self->loop->unwatch_process( $shell->{pid} ) };
  return;
}

# Records how a shell ended; a wait status of undef: unknown, stopped. A
# registered shell ends its entry and notifies -- once, as this runs once.
sub _ended {
  my ( $self, $shell, $status ) = @_;
  return unless $shell->{status} eq 'running';
  $shell->{ended} = Time::HiRes::time();
  if ( !defined $status || $shell->{stopping} ) {
    $shell->{status} = 'killed';
  }
  else {
    $shell->{status}    = 'completed';
    $shell->{exit_code} = ( $status & 127 ) ? 128 + ( $status & 127 ) : $status >> 8;
  }
  $self->_task_ended($shell) if $shell->{registered};
  return;
}

#### The registry

# A background shell in the application's registry (ADR 0027 section 1):
# kind bash; leaving raider stops it through the registry too.
sub _register {
  my ( $self, $shell ) = @_;
  return unless $self->has_tasks && !$shell->{registered};
  weaken( my $weak = $self );
  $self->tasks->add(
    id          => $shell->{id},
    kind        => 'bash',
    command     => $shell->{command},
    description => $shell->{description},
    tool_use_id => $shell->{tool_use_id},
    recipient   => $shell->{recipient} // 'main',
    background  => 1,
    stop        => sub { $weak->_stop($shell) if $weak },
  );
  $shell->{registered} = 1;
  return;
}

# The end of a registered shell: its entry, then the notification for the
# run that started it -- unless that is a subagent whose run has ended
# (nobody would read it), or the shells are being torn down.
sub _task_ended {
  my ( $self, $shell ) = @_;
  my $tasks  = $self->tasks;
  my $status = $shell->{status} eq 'killed' ? 'killed' : $shell->{exit_code} ? 'failed' : 'completed';
  $tasks->finish( $shell->{id}, $status, exit_code => $shell->{exit_code} );
  return if $self->_quiet || ${^GLOBAL_PHASE} eq 'DESTRUCT';
  my $recipient = $shell->{recipient} // 'main';
  if ( $recipient ne 'main' ) {
    my $caller = $tasks->get($recipient);
    return unless $caller && $caller->{status} eq 'running';
  }
  my ( $text, $label ) = $self->notification( $shell, $status );
  $tasks->notify( $recipient, $text, id => $shell->{id}, label => $label );
  return;
}


sub notification {
  my ( $self, $shell, $status ) = @_;
  my $what = 'Background command "'.( $shell->{description} // $shell->{command} ).'"';
  my $summary = $status eq 'killed' ? $what.' was stopped'
    : $status eq 'failed'           ? $what.' failed with exit code '.$shell->{exit_code}
    :                                 $what.' completed (exit code '.( $shell->{exit_code} // 0 ).')';
  my $text = $self->tasks->notification_text(
    task_id     => $shell->{id},
    tool_use_id => $shell->{tool_use_id},
    status      => $status,
    summary     => $summary,
  );
  return ( $text, 'background shell '.$shell->{id}.' '.( $status eq 'killed' ? 'was stopped' : $status ) );
}

# The registry entry an ID or name stands for when it is no shell of this
# object (a subagent), or nothing.
sub _task {
  my ( $self, $ref ) = @_;
  return unless $self->has_tasks;
  my $entry = $self->tasks->find($ref) or return;
  return if $entry->{kind} eq 'bash';
  return $entry;
}

# Waits up to $seconds for the shell to end; true when it has. With
# $forward, a HUP, INT or TERM nobody else handles stops the command
# before raider goes, as MCP::Run::Bash did.
sub _wait {
  my ( $self, $shell, $seconds, $forward ) = @_;
  my @forward = $forward ? grep { _unclaimed($_) } qw( HUP INT TERM ) : ();
  local @SIG{@forward} = map {
    my $signal = $_;
    sub { $self->_stop($shell); $SIG{$signal} = 'DEFAULT'; kill $signal => $$ };
  } @forward;
  my $deadline = Time::HiRes::time() + $seconds;
  my $pause    = 0.001;
  while (1) {
    return 1 if $self->_poll($shell);
    my $left = $deadline - Time::HiRes::time();
    return 0 if $left <= 0;
    Time::HiRes::sleep( min( $pause, $left ) );
    $pause = min( $pause * 2, 0.05 );
  }
}

sub _unclaimed {
  my ( $signal ) = @_;
  my $handler = $SIG{$signal};
  return !ref $handler && ( !defined $handler || $handler eq '' || $handler eq 'DEFAULT' );
}

sub _signal {
  my ( $self, $shell, $signal ) = @_;
  return kill( $signal => -$shell->{pid} ) || kill( $signal => $shell->{pid} );
}

# Stops a running shell: SIGTERM to its group, SIGKILL after kill_grace.
sub _stop {
  my ( $self, @shells ) = @_;
  my @running = grep { $_->{status} eq 'running' } @shells or return;
  for my $shell (@running) {
    $shell->{stopping} = 1;
    $self->_signal( $shell, 'TERM' );
  }
  my $deadline = Time::HiRes::time() + $self->kill_grace;
  while ( my @left = grep { !$self->_poll($_) } @running ) {
    if ( Time::HiRes::time() >= $deadline ) {
      for my $shell (@left) {
        $self->_signal( $shell, 'KILL' );
        my $got = waitpid( $shell->{pid}, 0 );
        $self->_unwatch($shell);
        $self->_ended( $shell, $got == $shell->{pid} ? $? : undef );
      }
      last;
    }
    Time::HiRes::sleep(0.02);
  }
  return;
}

sub _forget {
  my ( $self, $shell ) = @_;
  delete $self->_shells->{ $shell->{id} };
  $shell->{file}->remove;
  return;
}

#### Output

# The output written since the last call, decoded. While the command runs,
# an incomplete UTF-8 sequence at the end waits for the next call.
sub _take_output {
  my ( $self, $shell, $all ) = @_;
  my $bytes = '';
  if ( open my $fh, '<:raw', $shell->{file}->stringify ) {
    seek $fh, $shell->{offset}, 0;
    local $/;
    $bytes = <$fh> // '';
  }
  my $keep = $all ? 0 : _incomplete_tail($bytes);
  substr( $bytes, -$keep ) = '' if $keep;
  $shell->{offset} += length $bytes;
  return Encode::decode( 'UTF-8', $bytes );
}

sub _incomplete_tail {
  my ( $bytes ) = @_;
  my $len = length $bytes;
  for my $back ( 1 .. min( 4, $len ) ) {
    my $byte = ord substr( $bytes, -$back, 1 );
    next if ( $byte & 0xC0 ) == 0x80;    # a continuation byte
    my $need = $byte >= 0xF0 ? 4 : $byte >= 0xE0 ? 3 : $byte >= 0xC0 ? 2 : 1;
    return $need > $back ? $back : 0;
  }
  return 0;
}

# Output over output_limit keeps its start and its end, as Claude Code does.
sub _clip {
  my ( $self, $text ) = @_;
  my $max = $self->output_limit;
  return $text if length $text <= $max;
  my $half = int( $max / 2 );
  my $cut  = length($text) - 2 * $half;
  return substr( $text, 0, $half )."\n\n... [".$cut." characters truncated] ...\n\n".substr( $text, -$half );
}

#### bash_output


sub bash_output {
  my ( $self, $in ) = @_;
  my $id    = $in->{bash_id} // '';
  my $shell = $self->_shells->{$id};
  unless ($shell) {
    my $entry = $self->_task($id) or return ( $self->_no_shell($id), 1 );
    return $self->_task_output($entry);
  }
  my ( $filter, $bad ) = $self->_filter( $in->{filter} );
  return ( $bad, 1 ) if defined $bad;
  $in->{block}
    ? $self->_wait( $shell, $self->_seconds( $in->{timeout}, $self->block_timeout ) )
    : $self->_poll($shell);
  return $self->_shell_output( $shell, $filter );
}

async sub bash_output_f {
  my ( $self, $in ) = @_;
  my $id    = $in->{bash_id} // '';
  my $shell = $self->_shells->{$id};
  my $entry = $shell ? undef : $self->_task($id);
  return ( $self->_no_shell($id), 1 ) unless $shell || $entry;
  my ( $filter, $bad ) = $shell ? $self->_filter( $in->{filter} ) : ();
  return ( $bad, 1 ) if defined $bad;
  if ( $in->{block} ) {
    my $done = $shell ? sub { $self->_poll($shell) } : sub { $entry->{status} ne 'running' };
    await $self->_wait_f( $done, $self->_seconds( $in->{timeout}, $self->block_timeout ) );
  }
  return $self->_task_output($entry) if $entry;
  $self->_poll($shell);
  return $self->_shell_output( $shell, $filter );
}

# The filter of bash_output: ( $regex ), ( undef, $error_text ), or nothing.
sub _filter {
  my ( $self, $source ) = @_;
  return unless defined $source && length $source;
  my $filter = eval { qr/$source/ };
  return $filter if $filter;
  ( my $why = $@ ) =~ s/ at \S+ line \d+.*//s;
  return ( undef, 'Invalid filter regex: '.$why );
}

# Lets the loop run until $done answers true, at most $seconds.
async sub _wait_f {
  my ( $self, $done, $seconds ) = @_;
  my $deadline = Time::HiRes::time() + $seconds;
  my $pause    = 0.001;
  until ( $done->() ) {
    my $left = $deadline - Time::HiRes::time();
    last if $left <= 0;
    await $self->loop->delay_future( after => min( $pause, $left ) );
    $pause = min( $pause * 2, 0.05 );
  }
  return;
}

# bash_output of a registry entry that is no shell: its status, and once it
# has ended its report (or error).
sub _task_output {
  my ( $self, $entry ) = @_;
  my @parts = ( '<status>'.$entry->{status}.'</status>' );
  if ( $entry->{status} ne 'running' ) {
    my $text = $entry->{status} eq 'completed' ? $entry->{report} : $entry->{error};
    push @parts, "<output>\n".$self->_clip( $text =~ s/[\r\n]+\z//r )."\n</output>"
      if defined $text && length $text;
  }
  return ( join( "\n\n", @parts ), 0 );
}

# bash_output of a shell: what it wrote since the last call, filtered.
sub _shell_output {
  my ( $self, $shell, $filter ) = @_;
  my $output = $self->_take_output( $shell, $shell->{status} ne 'running' );
  if ($filter) {
    $output = join '', grep { /$filter/ } split /^/m, $output;
  }
  $output = $self->_clip( $output =~ s/[\r\n]+\z//r );
  my @parts = ( '<status>'.$shell->{status}.'</status>' );
  push @parts, '<exit_code>'.$shell->{exit_code}.'</exit_code>' if defined $shell->{exit_code};
  push @parts, "<stdout>\n".$output."\n</stdout>" if length $output;
  return ( join( "\n\n", @parts ), 0 );
}

#### kill_shell


sub kill_shell {
  my ( $self, $in ) = @_;
  my $id    = $in->{shell_id} // '';
  my $shell = $self->_shells->{$id};
  unless ($shell) {
    my $entry = $self->_task($id) or return ( $self->_no_shell($id), 1 );
    return ( 'Task '.$entry->{id}.' is not running (status: '.$entry->{status}.')', 1 )
      unless $entry->{status} eq 'running';
    $self->tasks->stop( $entry->{id} );
    my $label = defined $entry->{description} && length $entry->{description}
      ? $entry->{description} : $entry->{agent} // $entry->{name} // $entry->{kind};
    return ( 'Successfully stopped task: '.$entry->{id}.' ('.$label.')', 0 );
  }
  $self->_poll($shell);
  return ( 'Task '.$id.' is not running (status: '.$shell->{status}.')', 1 )
    unless $shell->{status} eq 'running';
  $self->_stop($shell);
  return ( 'Successfully stopped task: '.$id.' ('.$shell->{command}.')', 0 );
}

#### monitor


sub monitor {
  my ( $self, $in, $caller ) = @_;
  $caller //= {};
  return ( 'The monitor tool needs the task registry', 1 ) unless $self->has_tasks;
  my ( $command, $description ) = @$in{qw( command description )};
  return ( 'No command given: the command parameter must be a non-empty string', 1 )
    unless defined $command && !ref $command && $command =~ /\S/;
  return ( 'No description given: the description parameter must be a non-empty string', 1 )
    unless defined $description && !ref $description && $description =~ /\S/;
  my $wd = $self->working_directory;
  if ( my $refused = $self->_refusal( $command, $wd ) ) {
    return ( $refused, 1 );
  }
  my $cap = $self->has_unattended && $self->unattended->() ? $self->monitor_unattended_max_timeout : $self->monitor_max_timeout;
  my $ms  = $in->{timeout_ms};
  my $seconds = defined $ms && !ref $ms && looks_like_number($ms) && $ms == $ms && $ms > 0
    ? $ms / 1000 : $self->monitor_timeout;
  $seconds = $self->monitor_min_timeout if $seconds < $self->monitor_min_timeout;
  $seconds = $cap if $seconds > $cap;

  my $id = $self->tasks->next_id('monitor');
  weaken( my $weak = $self );
  my $monitor = Langertha::Raider::Monitor->new(
    id                => $id,
    loop              => $self->loop,
    tasks             => $self->tasks,
    command           => $command,
    description       => $description,
    timeout           => $seconds,
    recipient         => $caller->{recipient} // 'main',
    tool_use_id       => $caller->{call},
    ( defined $wd ? ( working_directory => $wd ) : () ),
    stderr_file       => $self->_dir->child( $id.'.stderr' ),
    kill_grace        => $self->kill_grace,
    on_end            => sub { delete $weak->_monitors->{ $_[0]->id } if $weak },
    %{ $self->monitor_options },
  );
  if ( my $error = $monitor->start ) {
    return ( 'Cannot start bash: '.$error, 1 );
  }
  $self->_monitors->{$id} = $monitor;
  return ( 'Monitor started (task '.$id.', expires in '.$monitor->span.' unless the source ends first; you get one notice '
    ."at expiry \x{2014} re-arm if you still need the watch). You will be notified on each event. Keep working \x{2014} "
    ."do not poll or sleep. Events may arrive while you are waiting for the user \x{2014} an event is not their reply. "
    .'Stop it with kill_shell (shell_id: '.$id.').', 0 );
}

#### The shells


sub background_pids {
  my ( $self ) = @_;
  return (
    ( map { $_->{pid} } grep { ( $_->{background} || $_->{detached} ) && $_->{status} eq 'running' } values %{ $self->_shells } ),
    ( map { $_->pid } grep { $_->status eq 'running' } values %{ $self->_monitors } ),
  );
}


sub async_tools {
  my ( $self, %caller ) = @_;
  weaken( my $weak = $self );
  my $value  = sub { my ( $v ) = @_; ref $v eq 'CODE' ? $v->() : $v };
  my $result = sub {
    my ( $text, $is_error ) = @_;
    return {
      content => [ { type => 'text', text => ''.( $text // '' ) } ],
      isError => $is_error ? JSON::MaybeXS->true : JSON::MaybeXS->false,
    };
  };
  my $gone = sub { Future->done( $result->( 'the shell tools are gone', 1 ) ) };
  my $in   = sub { ref $_[0] eq 'HASH' ? $_[0] : {} };
  my %tools = (
    bash => sub {
      my ( $input, %ctx ) = @_;
      return $gone->() unless $weak;
      return Future->done( $result->( $weak->bash( $in->($input), {
        recipient => $value->( $caller{recipient} ) // 'main',
        detached  => $value->( $caller{detached} ),
        call      => $ctx{call} // $ctx{id},
        ( $caller{working_directory} ? ( working_directory => $value->( $caller{working_directory} ) ) : () ),
      } ) ) );
    },
    bash_output => sub {
      my ( $input ) = @_;
      return $gone->() unless $weak;
      return $weak->bash_output_f( $in->($input) )->then( sub { Future->done( $result->(@_) ) } );
    },
    kill_shell => sub {
      my ( $input ) = @_;
      return $gone->() unless $weak;
      return Future->done( $result->( $weak->kill_shell( $in->($input) ) ) );
    },
    ( $self->has_tasks ? ( monitor => sub {
      my ( $input, %ctx ) = @_;
      return $gone->() unless $weak;
      return Future->done( $result->( $weak->monitor( $in->($input), {
        recipient => $value->( $caller{recipient} ) // 'main',
        call      => $ctx{call} // $ctx{id},
      } ) ) );
    } ) : () ),
  );
  return { map { $_ => { code => $tools{$_}, ( $caller{applies} ? ( applies => $caller{applies} ) : () ) } } keys %tools };
}


sub stop_all {
  my ( $self ) = @_;
  $_->stop for values %{ $self->_monitors };
  $self->_stop( values %{ $self->_shells } );
  return;
}

sub DEMOLISH {
  my ( $self ) = @_;
  $self->_quiet(1);
  $_->quiet(1) for values %{ $self->_monitors };
  $self->stop_all;
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::BashTools - Internal shell tools of raider: bash, bash_output, kill_shell and monitor

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $shell = Langertha::Raider::BashTools->new(
      loop              => $app->loop,
      working_directory => $root,
      validator         => $loadguard->validator,
    );
    my $server = $shell->server;    # MCP::Server with bash, bash_output, kill_shell

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The shell tools of raider, shaped after Claude Code's C<Bash>,
C<BashOutput> and C<KillShell> (L<Langertha::Raider::ToolNames>, ADR 0024).

C<bash> runs a command with C<bash -c> in L</working_directory> (or the
C<working_directory> argument), in a process group of its own, with standard
input from F</dev/null> and standard output and standard error into one file,
so the result is the combined output in the order it was written, as in
Claude Code. A command that exits with 0 answers with its output, or
C<(Bash completed with no output)>; any other exit status is an error result
that starts with C<Exit code N>. Output over L</output_limit> characters
keeps its start and its end around C<... [N characters truncated] ...>.

A command still running after its C<timeout> (seconds, default
L</default_timeout>, at most L</max_timeout>) is not killed: it is moved to
the background, as Claude Code does, and the result says so with its ID.
C<run_in_background> starts it there at once. A background shell is a child
of raider supervised by the application's event loop
(L<IO::Async::Loop/watch_process>, ADR 0016); C<bash_output> reads what it
wrote since the last call, with its status, and C<kill_shell> stops it. The
background shells belong to this object, so to the application: they live
across the runs of a session and are stopped when it goes away
(L</stop_all>, C<DEMOLISH>).

C<allowed_commands> and C<validator> (the loadguard gate, ADR 0018) are asked
before any command starts, in the foreground or the background, with the
texts L<MCP::Run> used.

With L</tasks> -- the application's registry of background work (ADR 0027)
-- a background shell is registered there as C<bash_N>, kind C<bash>, and
when it ends, on its own or stopped, a C<< <task-notification> >> goes to
the run that started it (L</async_tools>); the texts of C<bash> then say
that it will be notified. C<bash_output> and C<kill_shell> also take the ID
(or the name given at spawn) of any other entry of the registry -- a
subagent: C<bash_output> answers with its status and, once it has ended,
its report; C<kill_shell> asks it to stop (L<Langertha::Raider::Tasks/stop>).
This module does not know what a subagent is; the registry does.

With L</tasks> it also has C<monitor> (ADR 0031): a command in the
background whose stdout lines are delivered as notifications
(L<Langertha::Raider::Monitor>), stopped with C<kill_shell> like a shell.
C<monitor> is a shell tool: the gates of C<bash> apply to its command.

=head2 loop

Required. The event loop that supervises the background shells -- the
application's, the one the raid drives (ADR 0016).

=head2 working_directory

The directory commands run in unless a call names another. Without it,
raider's own working directory.

=head2 allowed_commands

Optional. The first words a command may start with; any other command is
refused with C<Command not allowed: WORD>.

=head2 validator

Optional. Called as C<< $validator->($command, $working_directory) >> before a
command starts; C<1> lets it run, anything else refuses it with
C<Command REASON> (L<Langertha::Raider::Loadguard/validator>).

=head2 tasks

Optional. The application's L<Langertha::Raider::Tasks>: background shells
are registered and notify there, and C<bash_output> and C<kill_shell> reach
its other entries (see L</DESCRIPTION>). Without it a background shell is
known only here and notifies nobody.

=head2 default_timeout

Seconds a command runs in the foreground when the call gives no C<timeout>:
120, as in Claude Code.

=head2 max_timeout

The largest C<timeout> of C<bash> and C<bash_output>, in seconds: 600, as in
Claude Code. A larger one is cut down to it.

=head2 output_limit

Characters of output a result carries: 30000, as in Claude Code. Longer
output keeps its first and its last half of it.

=head2 kill_grace

Seconds between C<SIGTERM> and C<SIGKILL> when a shell is stopped.

=head2 block_timeout

Seconds C<bash_output> with C<block> waits when the call gives no C<timeout>.

=head2 monitor_timeout

Seconds a C<monitor> watches when the call gives no C<timeout_ms>: 300.

=head2 monitor_max_timeout

The longest a C<monitor> may watch, in seconds: 1800 (30 minutes). A larger
C<timeout_ms> is cut down to it.

=head2 monitor_unattended_max_timeout

The same limit when L</unattended> says there is nobody to talk to (a run
with a single prompt, C<raider -p>): 600 (10 minutes).

=head2 unattended

Optional. Called without arguments when a monitor starts: true when the
run has no person at the keyboard (the application has no one to ask).

=head2 monitor_min_timeout

The shortest watch in seconds: 1, as the C<timeout_ms> of Claude Code has a
minimum of 1000. Tests lower it.

=head2 monitor_options

Extra arguments for every L<Langertha::Raider::Monitor> (C<batch_window>,
C<burst_limit>, ...). Tests use it to make the limits small.

=head2 server

The L<MCP::Server> with the tools C<bash>, C<bash_output> and C<kill_shell>,
built once.

=head2 bash

    my ( $text, $is_error ) = $shell->bash({ command => 'make test', timeout => 300 });

The C<bash> tool: runs the command and returns the result text and whether
it is an error result.

    my ( $text, $is_error ) = $shell->bash( $in, { recipient => 'agent_2', call => 'c4', detached => 1 } );

The optional caller (see L</async_tools>) says who runs it: the
C<recipient> of the notification when the command ends in the background
(default C<main>), the C<call> id the notification names as
C<tool-use-id>, and whether the run is C<detached> -- its foreground
command then belongs to the session (L</background_pids>). Its
C<working_directory> is where a command without one runs instead of
L</working_directory> (a subagent in a worktree of its own, ADR 0032).

=head2 notification

    my ( $text, $label ) = $shell->notification( $shell_hash, 'completed' );

The C<< <task-notification> >> of a background shell that ended (ADR 0027
E<sect>4, in Claude Code's form for shells) and the line a surface shows
for it. Status C<completed> (exit code 0), C<failed> (any other) or
C<killed>; summary C<Background command "DESCRIPTION" completed (exit code
N)>, C<... failed with exit code N> or C<... was stopped> -- the command
stands in for a missing C<description>.

=head2 bash_output

    my ( $text, $is_error ) = $shell->bash_output({ bash_id => 'bash_1', filter => 'FAIL', block => 1 });

The C<bash_output> tool: the new output of a background shell, with its
status and exit code:

    <status>completed</status>

    <exit_code>0</exit_code>

    <stdout>
    ...
    </stdout>

C<stdout> carries both outputs and is left out when there is no new output.
An unknown ID is an error result C<No task found with ID: ID>.

Another entry of L</tasks> (an agent, by ID or by the name given at spawn)
answers with its status (C<running>, C<completed>, C<failed>, C<killed>)
and, once it has ended, its report (its error, when it failed):

    <status>completed</status>

    <output>
    REPORT
    </output>

This synchronous method does not wait for an agent: an agent runs on the
loop, which a blocking wait would stop. L</bash_output_f> waits.

=head2 bash_output_f

    my ( $text, $is_error ) = await $shell->bash_output_f({ bash_id => 'agent_1', block => 1 });

L</bash_output> as a Future: C<block> waits on the loop, so other work --
an agent, the shells -- goes on meanwhile, for a shell and for an agent.
What L</async_tools> runs.

=head2 kill_shell

    my ( $text, $is_error ) = $shell->kill_shell({ shell_id => 'bash_1' });

The C<kill_shell> tool: stops a running background shell (L</kill_grace>)
and answers C<Successfully stopped task: ID (COMMAND)>. An unknown ID, or a
shell that is not running, is an error result.

Another running entry of L</tasks> (an agent, by ID or by the name given at
spawn) is asked to stop (L<Langertha::Raider::Tasks/stop>), and the answer
is C<Successfully stopped task: agent_1 (DESCRIPTION)>; its run ends on the
loop, and a background agent's notification then says it was stopped. One
that is not running is the same error as a shell's.

=head2 monitor

    my ( $text, $is_error ) = $shell->monitor(
      { description => 'errors in the log', command => 'tail -f app.log | grep --line-buffered ERROR', timeout_ms => 600000 },
      { recipient => 'agent_2', call => 'c4' },
    );

The C<monitor> tool: starts the command as a L<Langertha::Raider::Monitor>
(an entry of L</tasks>, C<monitor_N>) and answers at once. The gates of
C<bash> (L</allowed_commands>, the L</validator>) are asked first and refuse
with the same texts. C<timeout_ms> is held to L</monitor_min_timeout> and
L</monitor_max_timeout> (L</monitor_unattended_max_timeout> without a
person); the caller is as for L</bash>.

=head2 background_pids

The process IDs of the commands that belong to the session, not to the run
in progress: the background shells still running, and the foreground
command of a run that goes on without the person -- a background subagent,
the C<detached> caller of L</bash> (ADR 0027 E<sect>3). A surface that
stops the children of a cancelled run leaves these alone.

=head2 async_tools

    my $tools = $shell->async_tools( recipient => 'main' );
    my $tools = $shell->async_tools(
      recipient => sub { $subagent->task_id },
      detached  => sub { $subagent->detached },
      working_directory => sub { $subagent->working_root },   # optional
      applies   => sub { my ( $mcp ) = @_; ... },   # is $mcp a client of this server?
    );

The three tools as L<Langertha::Raider/async_tools> for the raider of one
run. C<bash> runs with that run as its caller (L</bash>): the
C<recipient> of its background shells' notifications, whether it is
C<detached> and the C<working_directory> its commands run in by default
-- each a value or a code reference asked at the call -- and
the call id from the call's context (C<call>, else C<id>). C<bash_output>
goes through L</bash_output_f>, so C<block> lets the loop run;
C<kill_shell> is L</kill_shell>. Each handler returns a Future of an MCP
result. C<applies> goes into each tool as the C<applies> of
L<Langertha::Raider/async_tools>, so a tool of these names from another
source is left alone.

=head2 stop_all

    $shell->stop_all;

Stops every shell still running (L</kill_grace>). C<DEMOLISH> does the same,
so no shell outlives the application.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Application>

=item * L<Langertha::Raider::Loadguard>

=item * L<Langertha::Raider::ToolNames>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut
