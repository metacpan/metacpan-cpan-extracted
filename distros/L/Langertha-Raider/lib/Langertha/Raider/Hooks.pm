package Langertha::Raider::Hooks;
# ABSTRACT: Internal runner of Claude Code hooks from settings and plugins
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Encode qw( decode );
use Future;
use IO::Async::Process;
use JSON::MaybeXS ();
use Path::Tiny;
use POSIX ();
use Scalar::Util qw( weaken );
use Time::HiRes ();
use Langertha::Raider::Hooks::Result;
use Langertha::Raider::ToolNames;


has loop => (
  is       => 'ro',
  isa      => 'IO::Async::Loop',
  required => 1,
);


has root => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has project_dir => (
  is         => 'ro',
  isa        => 'Str',
  lazy_build => 1,
);

sub _build_project_dir { $_[0]->root }


has settings => (
  is  => 'ro',
  isa => 'Maybe[Langertha::Raider::Context::Settings]',
);

has plugins => (
  is  => 'ro',
  isa => 'Maybe[Langertha::Raider::Context::Plugins]',
);


has native_briefing => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has if_matcher => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_if_matcher',
);


has groups => (
  is         => 'ro',
  isa        => 'HashRef',
  lazy_build => 1,
);

has config_errors => (
  is         => 'ro',
  isa        => 'ArrayRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub tool_names_class { 'Langertha::Raider::ToolNames' }
sub result_class     { 'Langertha::Raider::Hooks::Result' }

# Seconds between TERM and KILL for a hook over its time.
sub kill_grace { 2 }

has _collected => (
  is         => 'ro',
  isa        => 'ArrayRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_groups        { $_[0]->_collected->[0] }
sub _build_config_errors { $_[0]->_collected->[1] }

sub _build__collected {
  my ( $self ) = @_;
  my ( %groups, @errors );
  my $settings = $self->settings;
  return [ {}, [] ] if $settings && $settings->disable_all_hooks;
  if ($settings) {
    my $hooks = $settings->hooks;
    for my $event (keys %$hooks) {
      push @{ $groups{$event} }, map { { %$_, plugin => undef } } @{ $hooks->{$event} };
    }
  }
  if (my $plugins = $self->plugins) {
    for my $p (@{ $plugins->plugins }) {
      my ( $hooks, $errors ) = $plugins->hooks($p);
      push @errors, @$errors;
      my $info = {
        name     => $p->{name},
        key      => $p->{key},
        root     => $p->{root},
        data_dir => $plugins->data_dir($p),
      };
      for my $event (sort keys %$hooks) {
        push @{ $groups{$event} }, map { { %$_, plugin => $info } } @{ $hooks->{$event} };
      }
    }
  }
  return [ \%groups, \@errors ];
}


sub from_context {
  my ( $class, $context, %args ) = @_;
  my $settings = $context->settings or return;
  return $class->new(
    root        => $context->root,
    project_dir => $context->layout->project_dir->stringify,
    settings    => $settings,
    plugins     => $context->plugins,
    %args,
  );
}

#### Event tables (Claude Code's hooks reference)

my %TOOL_EVENT = map { $_ => 1 } qw( PreToolUse PostToolUse PostToolUseFailure PermissionRequest PermissionDenied );

# The input field a matcher is tested against; events not listed ignore it.
my %MATCH_FIELD = (
  ( map { $_ => 'tool_name' } keys %TOOL_EVENT ),
  SessionStart  => 'source',
  SessionEnd    => 'reason',
  SubagentStart => 'agent_type',
  SubagentStop  => 'agent_type',
  PreCompact    => 'trigger',
  PostCompact   => 'trigger',
  Notification  => 'notification_type',
);

# Events where exit 2 or decision "block" blocks (PreToolUse: a deny).
my %BLOCKING = map { $_ => 1 } qw(
  UserPromptSubmit UserPromptExpansion PostToolUse PostToolUseFailure PostToolBatch
  Stop SubagentStop PreCompact ConfigChange TaskCreated TaskCompleted TeammateIdle
);

# Events whose plain-text stdout is context for the model.
my %TEXT_IS_CONTEXT = map { $_ => 1 } qw( UserPromptSubmit UserPromptExpansion SessionStart PostModelSwitch );

# Events where exit 2 + "No such file or directory" is a missing script, not a block.
my %MISSING_FILE_IS_ERROR = map { $_ => 1 } qw( Stop SubagentStop TaskCompleted );

my %DEFAULT_TIMEOUT = ( UserPromptSubmit => 30, PreModelSwitch => 30, PostModelSwitch => 30, MessageDisplay => 10 );

my %DECISION_RANK = ( deny => 3, ask => 2, allow => 1 );

my %FILE_TOOL = map { $_ => 1 } qw( read_file write_file edit_file multi_edit );

sub _json { JSON::MaybeXS->new( utf8 => 1, canonical => 1, allow_blessed => 1, convert_blessed => 1, allow_nonref => 1 ) }

sub _json_text { JSON::MaybeXS->new( utf8 => 0 ) }


sub has_hooks {
  my ( $self, $event ) = @_;
  return @{ $self->groups->{$event} // [] } ? 1 : 0;
}


sub run { my ( $self, @args ) = @_; return $self->run_f(@args)->get }

sub run_f {
  my ( $self, $event, $input, %opt ) = @_;
  croak __PACKAGE__.'->run_f needs an event name' unless defined $event && length $event;
  $input //= {};
  croak __PACKAGE__.'->run_f needs the input as a hash ref' unless ref $input eq 'HASH';

  my $call = $self->_prepare_input($event, $input);
  $call->{raider_source} = $opt{tool_source};
  my ( $runs, $errors ) = $self->_select($event, $call);

  my @wait;
  my %seen;
  for my $run (@$runs) {
    next if $run->{outcome} eq 'skipped';
    if ($seen{ $run->{_key} }++) {
      $run->{outcome} = 'skipped';
      $run->{message} = 'the same hook from another settings file runs once';
      next;
    }
    if ($run->{async}) {
      $self->_start_async($run, $call);
      next;
    }
    push @wait, $self->_spawn_f($run, $call);
  }

  my $f = @wait ? Future->wait_all(@wait) : Future->done;
  return $f->then(sub {
    my $result = eval { $self->_merge($event, $call, $runs, $errors) };
    return Future->done($result) if $result;
    return Future->done($self->result_class->new(
      event  => $event,
      runs   => [ map { $self->_public_run($_) } @$runs ],
      errors => [ @$errors, $event.' hooks: '.$self->_one_line($@) ],
    ));
  });
}


has _async => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => undef,
  default  => sub { {} },
);

has _async_done => (
  is       => 'ro',
  isa      => 'ArrayRef',
  init_arg => undef,
  default  => sub { [] },
);

sub take_async_results {
  my ( $self ) = @_;
  my $done = $self->_async_done;
  my @out = @$done;
  @$done = ();
  return @out;
}

sub running_async { scalar keys %{ $_[0]->_async } }

sub shutdown {
  my ( $self ) = @_;
  my @wait;
  for my $entry (values %{ $self->_async }) {
    my ( $run, $f ) = @$entry;
    $run->{_cancelled} = 1;
    push @wait, $f;
    my $pid = $run->{_pid} or next;
    kill 'TERM', -$pid;
    $self->loop->delay_future( after => $self->kill_grace )->on_done(sub { kill 'KILL', -$pid unless $f->is_ready })->retain;
  }
  return @wait ? Future->wait_all(@wait) : Future->done;
}

# A runner that goes away leaves no async hook behind.
sub DEMOLISH {
  my ( $self ) = @_;
  for my $entry (values %{ $self->_async }) {
    kill 'TERM', -$entry->[0]{_pid} if $entry->[0]{_pid};
  }
  return;
}

sub _start_async {
  my ( $self, $run, $call ) = @_;
  $run->{outcome} = 'running';
  my $id = 0 + $run;
  weaken(my $weak = $self);
  my $f = $self->_spawn_f($run, $call)->on_ready(sub {
    my $self = $weak or return;
    delete $self->_async->{$id};
    push @{ $self->_async_done }, $self->_merge_async($call, $run);
  });
  $self->_async->{$id} = [ $run, $f ] unless $f->is_ready;
  return;
}

#### Input

# The input as the hooks get it, plus what the merge needs to translate back.
sub _prepare_input {
  my ( $self, $event, $input ) = @_;
  my %in = %$input;
  $in{hook_event_name} = $event;
  $in{cwd} //= $self->root;
  my %call = ( event => $event, input => \%in, cwd => $in{cwd} );

  if ($TOOL_EVENT{$event} && defined $in{tool_name} && !ref $in{tool_name}) {
    my $names = $self->tool_names_class;
    my $tool = $in{tool_name};
    $call{raider_tool} = $tool;
    $call{claude_tool} = $in{tool_name} = $names->claude_name($tool) // $tool;
    if (ref $in{tool_input} eq 'HASH') {
      $call{raider_args} = $in{tool_input};
      my $claude = $names->claude_input($tool, $in{tool_input});
      if ($FILE_TOOL{$tool} && defined $claude->{file_path} && !ref $claude->{file_path}
          && length $claude->{file_path} && !path($claude->{file_path})->is_absolute) {
        $claude->{file_path} = path($call{cwd})->child($claude->{file_path})->stringify;
      }
      $in{tool_input} = $claude;
    }
  }
  my $field = $MATCH_FIELD{$event};
  $call{match} = $field ? ( $in{$field} // '' ) : undef;
  $call{match} = '' if ref $call{match};
  return \%call;
}

#### Selection

sub _select {
  my ( $self, $event, $call ) = @_;
  my ( @runs, @errors );
  my $groups = $self->groups->{$event} // [];
  for my $group (@$groups) {
    if (defined $call->{match}) {
      my $hit = eval { $self->_matches($group->{matcher}, $call->{match}) };
      if (my $err = $@) {
        push @errors, $event.' hooks: invalid matcher "'.$group->{matcher}.'" in '.$group->{source}
          .', group skipped: '.$self->_one_line($err);
        next;
      }
      next unless $hit;
    }
    for my $hook (@{ $group->{hooks} }) {
      next unless ref $hook eq 'HASH';
      push @runs, $self->_new_run($event, $call, $group, $hook);
    }
  }
  return ( \@runs, \@errors );
}

# Claude Code's matcher rules; dies on an invalid regular expression.
sub _matches {
  my ( $self, $matcher, $value ) = @_;
  return 1 if !defined $matcher || $matcher eq '' || $matcher eq '*';
  if ($matcher =~ /\A[A-Za-z0-9_\- ,|]+\z/) {
    my %names = map { $_ => 1 } grep { length } map { s/\A\s+|\s+\z//gr } split /[|,]/, $matcher;
    return $names{$value} ? 1 : 0;
  }
  my $re = do { local $SIG{__WARN__} = sub {}; qr/$matcher/ };
  return $value =~ $re ? 1 : 0;
}

sub _new_run {
  my ( $self, $event, $call, $group, $hook ) = @_;
  my $plugin = $group->{plugin};
  my $args = ref $hook->{args} eq 'ARRAY' ? $hook->{args} : undef;
  my %run = (
    event   => $event,
    source  => $group->{source},
    plugin  => $plugin ? $plugin->{name} : undef,
    matcher => $group->{matcher},
    type    => $hook->{type},
    command => $hook->{command},
    args    => $args,
    form    => $args ? 'exec' : 'shell',
    async   => $hook->{async} || $hook->{asyncRewake} ? 1 : 0,
    outcome => 'pending',
    _on_failure_block => ( $hook->{onFailure} // '' ) eq 'block' ? 1 : 0,
  );
  my $skip = sub { $run{outcome} = 'skipped'; $run{message} = $_[0]; \%run };

  my $type = $hook->{type} // '';
  return $skip->('hook type "'.$type.'" is not supported, only "command"') unless $type eq 'command';
  return $skip->('no command') unless defined $hook->{command} && !ref $hook->{command} && length $hook->{command};

  if (defined $hook->{if}) {
    return $skip->('"if" applies to tool events only') unless $TOOL_EVENT{$event};
    my $ok;
    if ($self->has_if_matcher && defined $call->{raider_tool}) {
      $ok = eval { $self->if_matcher->( $hook->{if}, {
        name      => $call->{raider_tool},
        source    => $call->{raider_source},
        arguments => $call->{raider_args} // {},
      } ) };
    }
    return $skip->('"if" '.$hook->{if}.' does not match') if defined $ok && !$ok;
    $run{if_unchecked} = 1 unless defined $ok;
  }

  my %vars = ( CLAUDE_PROJECT_DIR => $self->project_dir );
  if ($plugin) {
    $vars{CLAUDE_PLUGIN_ROOT} = $plugin->{root};
    $vars{CLAUDE_PLUGIN_DATA} = $plugin->{data_dir} if defined $plugin->{data_dir};
  }
  my $subst = sub { my ( $s ) = @_; $s =~ s/\$\{(CLAUDE_[A-Z_]+)\}/exists $vars{$1} ? $vars{$1} : '${'.$1.'}'/ge; $s };
  my $command = $subst->($hook->{command});
  my @argv;
  if ($args) {
    @argv = ( $command, map { defined $_ && !ref $_ ? $subst->($_) : '' } @$args );
  }
  else {
    my $shell = $hook->{shell} // '';
    return $skip->('shell "'.$shell.'" is not supported') if length $shell && $shell ne 'bash' && $shell ne 'sh';
    @argv = ( $shell eq 'bash' ? 'bash' : 'sh', '-c', $command );
  }
  $run{argv} = \@argv;
  $run{_vars} = \%vars;

  if ($self->native_briefing && $self->_is_briefing_preload($command, $hook->{command})
      && ( $event eq 'SubagentStart' || ( $event eq 'PreToolUse' && ( $call->{claude_tool} // '' ) eq 'Agent' ) )) {
    return $skip->('briefing.skills are loaded by raider itself (native_briefing)');
  }

  my $timeout = $hook->{timeout};
  $timeout = undef unless defined $timeout && !ref $timeout && $timeout =~ /\A[0-9]+(?:\.[0-9]+)?\z/ && $timeout > 0;
  $run{timeout} = $run{async} ? undef : $timeout // $DEFAULT_TIMEOUT{$event} // 600;
  $run{_key} = _json()->encode([ $plugin ? $plugin->{key} : '', \@argv ]);
  return \%run;
}

sub _is_briefing_preload {
  my ( $self, @commands ) = @_;
  for my $c (@commands) {
    my ( $first ) = split ' ', $c;
    return 1 if defined $first && $first =~ m{(?:\A|/)briefing-preload(?:\.exe)?["']?\z};
  }
  return 0;
}

#### Running one hook

sub _spawn_f {
  my ( $self, $run, $call ) = @_;
  my $loop = $self->loop;
  my $stdin = _json()->encode($call->{input});

  my %env = %ENV;
  delete @env{qw( CLAUDE_PLUGIN_ROOT CLAUDE_PLUGIN_DATA )};
  %env = ( %env, %{ $run->{_vars} } );
  if (my $data = $run->{_vars}{CLAUDE_PLUGIN_DATA}) {
    eval { path($data)->mkpath };   # Claude Code creates it on first reference
  }

  my @argv = @{ $run->{argv} };
  my $cwd = $self->root;
  my ( $stdout, $stderr ) = ( '', '' );
  my $done = $loop->new_future;
  my $started = [ Time::HiRes::gettimeofday() ];

  my $process = eval {
    IO::Async::Process->new(
      code => sub {
        POSIX::setsid();
        chdir $cwd or do { print STDERR "cannot chdir to $cwd: $!\n"; return 127 };
        %ENV = %env;
        { no warnings 'exec'; exec { $argv[0] } @argv; }
        print STDERR 'cannot run '.$argv[0].': '.$!."\n";
        return 127;
      },
      stdin        => { from => $stdin },
      stdout       => { into => \$stdout },
      stderr       => { into => \$stderr },
      on_finish    => sub { $done->done($_[1]) unless $done->is_ready },
      on_exception => sub { my ( undef, $e, undef, $status ) = @_; $stderr .= $e; $done->done($status // 127 << 8) unless $done->is_ready },
    );
  };
  unless ($process) {
    $run->{outcome} = 'error';
    $run->{message} = 'cannot start: '.$self->_one_line($@);
    return Future->done($run);
  }
  $loop->add($process);
  my $pid = $run->{_pid} = $process->pid;

  my $timer;
  if (defined $run->{timeout}) {
    my $grace = $self->kill_grace;
    $timer = $loop->delay_future( after => $run->{timeout} )->on_done(sub {
      return if $done->is_ready;
      $run->{timed_out} = 1;
      kill 'TERM', -$pid;
      $loop->delay_future( after => $grace )->on_done(sub { kill 'KILL', -$pid unless $done->is_ready })->retain;
    });
  }

  return $done->then(sub {
    my ( $status ) = @_;
    $timer->cancel if $timer && !$timer->is_ready;
    delete $run->{_pid};
    $run->{duration_ms} = int( Time::HiRes::tv_interval($started) * 1000 + 0.5 );
    $run->{exit}   = $status >> 8;
    $run->{signal} = $status & 127;
    $run->{stdout} = decode( 'UTF-8', $stdout );
    $run->{stderr} = decode( 'UTF-8', $stderr );
    $self->_classify($run, $call);
    $self->_fail_block($run);
    return Future->done($run);
  });
}

# Sets output/json/outcome/message of a finished run.
sub _classify {
  my ( $self, $run, $call ) = @_;
  my $event = $run->{event};

  if ($run->{_cancelled}) {
    $run->{outcome} = 'cancelled';
    $run->{message} = 'stopped at shutdown';
    return;
  }
  if ($run->{timed_out}) {
    $run->{outcome} = 'timeout';
    $run->{message} = 'timed out after '.$run->{timeout}.'s, output discarded';
    $run->{output} = 'empty';
    $run->{stdout} = '';
    return;
  }

  my ( $kind, $json ) = $self->_parse_stdout($run->{stdout}, $run->{async});
  $run->{output} = $kind;
  $run->{json} = $json;
  my $first_err = $self->_first_line($run->{stderr});

  if ($kind eq 'json') {
    if (my $problem = $self->_check_json($event, $json)) {
      $run->{output} = 'invalid';
      $run->{json} = undef;
      $kind = 'invalid';
      $run->{message} = $problem;
    }
  }

  if ($run->{signal}) {
    $run->{outcome} = 'error';
    $run->{message} = 'killed by signal '.$run->{signal};
    return;
  }
  if ($run->{exit} == 2) {
    my $missing = $kind eq 'empty' && ( $run->{stderr} // '' ) =~ /No such file or directory/
      && ( $MISSING_FILE_IS_ERROR{$event} || ( $event eq 'UserPromptSubmit' && $run->{plugin} ) );
    if (!$missing && ( $BLOCKING{$event} || $event eq 'PreToolUse' )) {
      $run->{outcome} = 'block';
      $run->{json} = undef if $kind eq 'invalid';
      return;
    }
    $run->{outcome} = 'error';
    $run->{message} = $first_err // 'exit code 2';
    return;
  }
  if ($kind eq 'invalid') {
    $run->{outcome} = 'error';
    $run->{message} //= 'stdout is not valid JSON';
    return;
  }
  if ($run->{exit} == 0 || $kind eq 'json') {
    $run->{outcome} = 'success';
    return;
  }
  $run->{outcome} = 'error';
  $run->{message} = 'Failed with non-blocking status code: '.( $first_err // 'exit code '.$run->{exit} );
  return;
}

# onFailure "block": a failed hook does what exit 2 does on its event.
my %FAILURE_NEVER_BLOCKS = map { $_ => 1 } qw( Stop SubagentStop TaskCompleted TeammateIdle );

sub _fail_block {
  my ( $self, $run ) = @_;
  my $event = $run->{event};
  return unless $run->{_on_failure_block} && !$run->{async} && !$FAILURE_NEVER_BLOCKS{$event};
  return unless $BLOCKING{$event} || $event eq 'PreToolUse';
  my $failed = $run->{outcome} eq 'error' || $run->{outcome} eq 'timeout'
    || ( $run->{outcome} eq 'success' && ( $run->{exit} // 0 ) != 0 );
  return unless $failed;
  my $what = $run->{outcome} eq 'timeout' ? 'timed out' : 'failed';
  $run->{_block_reason} = $what.'; blocking because onFailure is "block"'
    .( defined $run->{message} ? ': '.$run->{message} : '' );
  $run->{outcome} = 'block';
  $run->{json} = undef;
  return;
}

# ( 'empty'|'text'|'json'|'invalid', $object ); stdout is decoded text.
sub _parse_stdout {
  my ( $self, $out, $async ) = @_;
  $out //= '';
  ( my $trim = $out ) =~ s/\A\s+|\s+\z//g;
  return ( 'empty', undef ) unless length $trim;
  if ($trim =~ /\A\{/ && $trim =~ /\}\z/) {
    my $data = eval { _json_text()->decode($trim) };
    return ( 'json', $data ) if ref $data eq 'HASH';
    return ( 'invalid', undef ) unless $async;
  }
  if ($async) {
    for my $line (reverse split /\n/, $out) {
      next unless $line =~ /\A\s*\{.*\}\s*\z/;
      my $data = eval { _json_text()->decode($line) };
      return ( 'json', $data ) if ref $data eq 'HASH';
    }
  }
  return ( 'text', undef );
}

# A schema problem of a decoded answer, or undef.
sub _check_json {
  my ( $self, $event, $json ) = @_;
  my $hso = $json->{hookSpecificOutput};
  return unless defined $hso;
  return 'hookSpecificOutput is not an object' unless ref $hso eq 'HASH';
  my $name = $hso->{hookEventName};
  return 'hookSpecificOutput.hookEventName is "'.( $name // '' ).'", not "'.$event.'"'
    unless defined $name && !ref $name && $name eq $event;
  return;
}

#### Merging

sub _merge {
  my ( $self, $event, $call, $runs, $errors ) = @_;
  my ( @errors, @context, @messages, %reasons, @block_reasons, @deny_messages );
  my ( $decision, $blocked, $stopped, $stop_reason, @updates ) = ( undef, 0, 0, undef );
  push @errors, @$errors;
  my $tag = $event.( defined $call->{claude_tool} ? ':'.$call->{claude_tool} : '' );

  for my $run (@$runs) {
    my $outcome = $run->{outcome};
    if ($outcome eq 'error' || $outcome eq 'timeout') {
      push @errors, $tag.' hook error: ['.$run->{command}.']: '.( $run->{message} // 'failed' );
      next;
    }
    next unless $outcome eq 'success' || $outcome eq 'block';
    my $json = $run->{json} // {};
    my $hso = ref $json->{hookSpecificOutput} eq 'HASH' ? $json->{hookSpecificOutput} : {};

    if (defined $json->{continue} && !$json->{continue}) {
      $stopped = 1;
      $stop_reason //= $json->{stopReason} if defined $json->{stopReason} && !ref $json->{stopReason};
    }
    push @messages, $json->{systemMessage} if $self->_text($json->{systemMessage});
    push @context, $hso->{additionalContext} if $self->_text($hso->{additionalContext});
    push @context, $run->{stdout} =~ s/\A\s+|\s+\z//gr
      if $outcome eq 'success' && $run->{output} eq 'text' && $TEXT_IS_CONTEXT{$event};

    if ($event eq 'PreToolUse') {
      my ( $d, $why );
      if ($outcome eq 'block') {
        ( $d, $why ) = ( 'deny', $run->{_block_reason} // ( $self->_text($hso->{permissionDecisionReason}) ? $hso->{permissionDecisionReason}
          : $self->_text($json->{reason}) ? $json->{reason} : $run->{stderr} =~ s/\A\s+|\s+\z//gr ) );
      }
      elsif (defined $hso->{permissionDecision} && !ref $hso->{permissionDecision}) {
        ( $d, $why ) = ( $hso->{permissionDecision}, $hso->{permissionDecisionReason} );
      }
      elsif (defined $json->{decision} && !ref $json->{decision}) {
        my %old = ( approve => 'allow', block => 'deny' );
        ( $d, $why ) = ( $old{ $json->{decision} }, $json->{reason} );
      }
      if (defined $d && $DECISION_RANK{$d}) {
        if ($d eq 'deny') {
          # What Claude Code tells the model: the stderr of an exit 2 (or a
          # failed onFailure "block" hook) as a hook error, the reason a
          # hook's JSON gives as it stands.
          my $from_json = $outcome ne 'block'
            || ( !$run->{_block_reason} && ( $self->_text($hso->{permissionDecisionReason}) || $self->_text($json->{reason}) ) );
          push @deny_messages, $from_json && $self->_text($why) ? $why
            : $tag.' hook '.( $self->_text($why) ? 'error: '.$why : 'blocked the tool call' );
        }
        $decision = $d if !defined $decision || $DECISION_RANK{$d} > $DECISION_RANK{$decision};
        push @{ $reasons{$d} }, $why if $self->_text($why);
      }
      elsif (defined $d) {
        push @errors, $tag.' hook error: ['.$run->{command}.']: permissionDecision "'.$d.'" is not supported';
      }
      push @updates, [ $run, $hso->{updatedInput} ] if ref $hso->{updatedInput} eq 'HASH';
    }
    elsif ($BLOCKING{$event}) {
      if ($outcome eq 'block') {
        $blocked = 1;
        my $why = $run->{_block_reason} // ( $self->_text($json->{reason}) && ( $json->{decision} // '' ) eq 'block'
          ? $json->{reason} : $run->{stderr} =~ s/\A\s+|\s+\z//gr );
        push @block_reasons, $why if length $why;
      }
      elsif (( $json->{decision} // '' ) eq 'block') {
        $blocked = 1;
        push @block_reasons, $json->{reason} if $self->_text($json->{reason});
      }
    }
  }

  my $updated;
  if (@updates && ( $decision // '' ) ne 'deny') {
    my %distinct = map { _json()->encode($_->[1]) => 1 } @updates;
    push @errors, $tag.' hooks: '.scalar(@updates).' hooks returned different updatedInput; the last one ('
      .$updates[-1][0]{command}.') wins' if keys %distinct > 1;
    $updated = $self->_raider_input($call, $updates[-1][1]);
  }

  return $self->result_class->new(
    event              => $event,
    runs               => [ map { $self->_public_run($_) } @$runs ],
    errors             => \@errors,
    decision           => $decision,
    deny_messages      => ( $decision // '' ) eq 'deny' ? \@deny_messages : [],
    reasons            => $event eq 'PreToolUse' ? [ @{ $reasons{ $decision // '' } // [] } ] : \@block_reasons,
    blocked            => $blocked,
    additional_context => \@context,
    system_messages    => \@messages,
    stopped            => $stopped,
    stop_reason        => $stop_reason,
    updated_input      => $updated,
  );
}

# An async hook decides nothing: only its context and message count.
sub _merge_async {
  my ( $self, $call, $run ) = @_;
  my $event = $run->{event};
  my ( @context, @messages, @errors );
  if ($run->{outcome} eq 'success' || $run->{outcome} eq 'block') {
    my $json = $run->{json} // {};
    my $hso = ref $json->{hookSpecificOutput} eq 'HASH' ? $json->{hookSpecificOutput} : {};
    push @messages, $json->{systemMessage} if $self->_text($json->{systemMessage});
    push @context, $hso->{additionalContext} if $self->_text($hso->{additionalContext});
  }
  elsif ($run->{outcome} ne 'cancelled') {
    push @errors, $event.' hook error: ['.$run->{command}.']: '.( $run->{message} // 'failed' );
  }
  return $self->result_class->new(
    event              => $event,
    runs               => [ $self->_public_run($run) ],
    errors             => \@errors,
    additional_context => \@context,
    system_messages    => \@messages,
  );
}

sub _raider_input {
  my ( $self, $call, $claude ) = @_;
  my $tool = $call->{raider_tool};
  return { %$claude } unless defined $tool;
  my $raider = $self->tool_names_class->raider_input($tool, $claude);
  my $orig = ( $call->{raider_args} // {} )->{path};
  if ($FILE_TOOL{$tool} && defined $orig && !ref $orig && length $orig && !path($orig)->is_absolute
      && defined $raider->{path} && $raider->{path} eq path($call->{cwd} // $self->root)->child($orig)->stringify) {
    $raider->{path} = $orig;
  }
  return $raider;
}

sub _public_run {
  my ( $self, $run ) = @_;
  return { map { $_ => $run->{$_} } grep { !/\A_/ } keys %$run };
}

sub _text { my ( $self, $v ) = @_; return defined $v && !ref $v && length $v ? 1 : 0 }

sub _first_line {
  my ( $self, $text ) = @_;
  return unless defined $text;
  my ( $line ) = grep { length } map { s/\A\s+|\s+\z//gr } split /\n/, $text;
  return $line;
}

sub _one_line {
  my ( $self, $error ) = @_;
  my ( $line ) = split /\n/, "$error";
  $line //= '';
  $line =~ s/ at (?:(?! at ).)+ line \d+\.?\z//;
  return $line;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Hooks - Internal runner of Claude Code hooks from settings and plugins

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $hooks = Langertha::Raider::Hooks->from_context( $app->context, loop => $loop )
      or return;                                       # not in the Claude layout

    my $r = await $hooks->run_f( PreToolUse => {
      session_id      => $sid,
      transcript_path => $journal_file,
      permission_mode => 'default',
      tool_name       => 'edit_file',                  # raider name and arguments;
      tool_input      => { path => 'lib/A.pm', ... },  # the hooks see Edit and file_path
      tool_use_id     => $call_id,
    });
    # $r is a Langertha::Raider::Hooks::Result

    my @late = $hooks->take_async_results;             # async hooks done since last time
    $hooks->shutdown;                                  # end of session: stop async hooks

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Runs the hooks of a Claude Code project the way Claude Code does (its
hooks reference, L<https://code.claude.com/docs/en/hooks>): the C<hooks> of
the settings files (L<Langertha::Raider::Context::Settings/hooks>) and of
every installed and enabled plugin (F<hooks/hooks.json> and the manifest's
C<hooks>, L<Langertha::Raider::Context::Plugins/hooks>), unless the settings
say C<disableAllHooks>. This module runs them and merges what they say into
a L<Langertha::Raider::Hooks::Result>; acting on it (denying a tool call,
adding context, ...) is the caller's business --
L<Langertha::Raider::Application> (C<hooks>, C<tool_hook>, C<run_prompt>)
and L<Langertha::Raider::Plugin::ClaudeHooks> in the Claude layout, as
ADR 0022 records.

=head2 Selection

Per event the matcher groups in configuration order -- settings files (user,
project, local), then plugins in L<Langertha::Raider::Context::Plugins/plugins>
order. A group's C<matcher> is tested against one field of the event's
input: the tool name for C<PreToolUse>, C<PostToolUse>,
C<PostToolUseFailure>, C<PermissionRequest> and C<PermissionDenied>, the
C<source> for C<SessionStart> (C<startup>, C<resume>, C<clear>, C<compact>),
the C<agent_type> for C<SubagentStart>/C<SubagentStop>, the C<reason> for
C<SessionEnd>, the C<trigger> for C<PreCompact>/C<PostCompact>, the
C<notification_type> for C<Notification>. Other events (C<UserPromptSubmit>,
C<Stop>, ...) ignore the matcher. Like Claude Code: C<*>, empty or missing
matches all; a matcher of only letters, digits, C<_>, C<->, spaces, C<,>
and C<|> is a list of exact names split at C<|> or C<,>; anything else is a
regular expression, unanchored (Claude Code uses JavaScript's; the common
syntax is the same in Perl). An invalid expression skips the group and is
reported in L<Langertha::Raider::Hooks::Result/errors>, never fatal.

Tool names are matched in Claude Code's spelling: the raider tool is turned
into its Claude name with L<Langertha::Raider::ToolNames/claude_name>
(C<edit_file> is C<Edit>), an C<mcp__*> name stays, a raider-only tool
(C<perl_eval>) keeps its raider name.

Only C<type: command> runs; a C<http>, C<mcp_tool>, C<prompt> or C<agent>
hook is skipped and reported. A hook with an C<if> rule runs on tool events
only (as in Claude Code); the rule is checked by L</if_matcher> when one is
set, otherwise the hook runs (the rule is a filter, the hook still decides).
The same command (with the same C<args>) from several settings files runs
once; a plugin's copy runs separately.

=head2 Running a hook

Each hook is a process of its own session (C<setsid>, no terminal) in
L</root>, all hooks of an event in parallel, on L</loop> (one raid, one
loop: ADR 0016). C<${CLAUDE_PROJECT_DIR}>, and for plugin hooks
C<${CLAUDE_PLUGIN_ROOT}> and C<${CLAUDE_PLUGIN_DATA}>, are replaced in
C<command> and every element of C<args>, and set in the environment
(C<CLAUDE_PLUGIN_*> removed for settings hooks). With C<args> the command is
started directly (exec form, looked up on C<PATH>, no shell); without, it
runs with C<sh -c> (shell form; C<shell: bash> uses bash, C<powershell> is
not supported). The data directory is created before a plugin hook runs.
C<${user_config.*}> is not supported and stays as written.

The event's input is written to stdin as JSON: what the caller passes, plus
C<hook_event_name> and C<cwd> (L</root> unless given -- the application
gives its working root, a subagent its own, ADR 0032). For tool events
C<tool_name> is turned into the Claude name and C<tool_input> into the
Claude form (L<Langertha::Raider::ToolNames/claude_input>); the C<file_path>
of C<Read>, C<Write>, C<Edit> and C<MultiEdit> is made absolute against that
C<cwd>, as Claude Code hands it.

C<timeout> is in seconds; the default is 600, 30 on C<UserPromptSubmit>. A
hook over its time gets C<TERM> (its process group), C<KILL> two seconds
later; its output is dropped and it is a non-blocking error. C<async: true>
starts the hook and does not wait: no timeout, no decision; when it ends,
its C<additionalContext> and C<systemMessage> are in
L</take_async_results>. C<asyncRewake> runs like C<async> (raider has no
idle session to wake).

C<onFailure: "block"> makes a failed hook -- one that cannot start, exits
other than 0 or 2 (even with a JSON answer), prints invalid JSON or times
out -- do what exit 2 does on its event; not on C<Stop>, C<SubagentStop>,
C<TaskCompleted>, C<TeammateIdle> and async hooks, as in Claude Code.

=head2 Reading the answer

As Claude Code reads it:

=over

=item * stdout that is one JSON object (C<{> ... C<}>, whitespace around)
is the hook's answer; stdout that is not is plain text; C<{> ... C<}> that
does not parse is invalid. An async hook may also print its object on a
line of its own.

=item * Exit 0: the JSON fields apply; plain text is context on
C<UserPromptSubmit> and C<SessionStart>; invalid JSON is a non-blocking
error.

=item * Exit 2: blocks -- C<PreToolUse> is denied, a blocking event
(C<UserPromptSubmit>, C<Stop>, C<SubagentStop>, C<PostToolUse>,
C<PostToolUseFailure>, C<PreCompact>, ...) is blocked; stderr is the reason
unless the JSON gives one. The JSON is still read but cannot undo the block.
On events that cannot block (C<SessionStart>, C<SubagentStart>, ...) exit 2
is a non-blocking error. On C<Stop>, C<SubagentStop> and a plugin's
C<UserPromptSubmit>, an exit 2 with empty stdout whose stderr says C<No such
file or directory> is a non-blocking error (a missing script).

=item * Any other exit: with a valid JSON object the fields decide (Claude
Code ignores the exit code then); otherwise a non-blocking error with the
first line of stderr.

=item * C<hookSpecificOutput> must name the event in C<hookEventName>, else
the answer is a non-blocking error.

=back

=head2 Merging

=over

=item * C<continue: false> wins over everything: L<Langertha::Raider::Hooks::Result/stopped>.

=item * C<PreToolUse>: C<deny> E<gt> C<ask> E<gt> C<allow>; the reasons of
the winning decision in configuration order. C<defer> (Claude Code's C<-p>
mode only) is not supported and counts as no decision. The deprecated
top-level C<decision> C<approve>/C<block> counts as C<allow>/C<deny>.

=item * C<updatedInput> replaces the whole input (Claude Code's rule). The
hooks of one event run in parallel on the same input, so two of them cannot
build on each other: the last one in configuration order wins, and when
several hooks return different inputs that is reported in
L<Langertha::Raider::Hooks::Result/errors>. It is translated back with
L<Langertha::Raider::ToolNames/raider_input>; a C<file_path> that is still
the absolute form of the original relative C<path> gets the original back.
It never applies to a denied call.

=item * C<additionalContext>, C<systemMessage> and plain-text context are
collected, never merged away; C<decision: "block"> on a blocking event sets
L<Langertha::Raider::Hooks::Result/blocked> with its C<reason>.

=back

=head2 Task events and the words of a denial

C<TaskCreated> and C<TaskCompleted> are fired by the application when the
task tools (C<task_create>, C<task_update>) create a task or complete one,
with C<task_id>, C<task_subject> and C<task_description> in the input and no
matcher. Exit 2 (or C<decision: "block">) vetoes the change; the model gets
C<TaskCreated hook error: STDERR> as the tool's error result. They are
blocking events here, so L<Langertha::Raider::Hooks::Result/blocked> tells
(ADR 0022, addendum).

What the model is told when a C<PreToolUse> hook denies is
L<Langertha::Raider::Hooks::Result/deny_messages>: C<PreToolUse:Bash hook
error: STDERR> for exit 2, the C<permissionDecisionReason> as it stands for a
JSON denial.

=head2 Briefing loaded natively

The briefing plugin's C<briefing-preload> rewrites an C<Agent> call's
prompt on C<PreToolUse> (and answers C<SubagentStart> for Codex) to put the
skills an agent file declares under C<briefing.skills> in front of the
task. When raider loads those skills itself (L</native_briefing>), running
the hook as well would put every skill body into the prompt twice -- or
deny a spawn raider would brief correctly, as the hook resolves skills
through its own copy of the lookup. Raider's own loading wins: with
L</native_briefing> the hooks whose command is C<briefing-preload> are
skipped (reported as C<skipped>) on C<PreToolUse> for C<Agent> and on
C<SubagentStart>. Its C<SessionStart> check still runs.

=head2 loop

The L<IO::Async::Loop> the hooks run on -- the raid's loop. Required.

=head2 root

The working directory: the hook processes run there, and it is the C<cwd>
of an input that names none, the base of its relative tool paths. Required.

=head2 project_dir

C<CLAUDE_PROJECT_DIR>: the project root. Defaults to L</root>.

=head2 settings

The L<Langertha::Raider::Context::Settings> whose hooks run, or C<undef>.

=head2 plugins

The L<Langertha::Raider::Context::Plugins> whose hooks run, or C<undef>.

=head2 native_briefing

True when raider loads C<briefing.skills> of agent files itself; then the
C<briefing-preload> hooks are skipped where they would load them a second
time (see L</Briefing loaded natively>). Default false.

=head2 if_matcher

Optional code ref that decides a hook's C<if> rule (Claude Code's
permission rule syntax, C<Bash(git *)>) for a tool call:

    if_matcher => sub { my ( $rule, $call ) = @_; ... }   # $call: { name, source, arguments }, raider form

True runs the hook, false skips it, C<undef> (the rule cannot be decided)
runs it marked C<if_unchecked>, as Claude Code runs a hook whose rule it
cannot evaluate. Without one, a hook with an C<if> rule runs on every tool
call its group matches, marked the same way. The application passes
L<Langertha::Raider::Permissions/rule_matches>.

=head2 groups

The matcher groups per event, C<< { Event => [ { matcher, hooks, source,
plugin }, ... ] } >>, C<plugin> being C<< { name, key, root, data_dir } >>
for a plugin's group and C<undef> otherwise. Built from L</settings> and
L</plugins>; empty when the settings say C<disableAllHooks>.

=head2 config_errors

Problems found while collecting L</groups> (a broken plugin hooks file),
one line each.

=head2 from_context

    my $hooks = Langertha::Raider::Hooks->from_context( $context, loop => $loop, %more );

A runner for a L<Langertha::Raider::Context>: its root, project directory,
settings and plugins. C<undef> outside the Claude layout (no settings).
C<%more> goes to C<new> (L</native_briefing>, L</if_matcher>).

=head2 has_hooks

    return unless $hooks->has_hooks('PostToolUse');

True when any group is configured for the event (whether its matcher
matches is not checked). Cheap; lets the caller skip building the input.

=head2 run_f

    my $result = await $hooks->run_f( $event => \%input, tool_source => 'engine:1' );

C<tool_source> (optional) is where a tool call runs, as the gate sees it;
it only reaches L</if_matcher>, never the hooks. Runs the hooks of C<$event> that match C<\%input> (see L</DESCRIPTION>) and
resolves to a L<Langertha::Raider::Hooks::Result> once every hook that is
not async has finished. C<\%input> holds the event's fields in raider form:
C<session_id>, C<transcript_path>, C<permission_mode>, ... and per event
C<tool_name>/C<tool_input>/C<tool_use_id>/C<tool_response>, C<prompt>,
C<source>, C<stop_hook_active>, C<agent_id>/C<agent_type>,
C<last_assistant_message>. JSON booleans for booleans. The future never
fails: every problem ends up in the result's C<errors>. With nothing to
run it is done at once with an empty result.

=head2 run

    my $result = $hooks->run( $event => \%input );

L</run_f>, waited for on L</loop>.

=head2 take_async_results

    for my $r ($hooks->take_async_results) { ... $r->context, $r->system_messages ... }

A L<Langertha::Raider::Hooks::Result> for every C<async> hook that ended
since the last call, in the order they ended; each carries only that hook's
C<additionalContext> and C<systemMessage> (an async hook decides nothing),
its run report and errors. Claude Code delivers these on the next turn.

=head2 running_async

The number of async hooks still running.

=head2 shutdown

    await $hooks->shutdown;

Stops every async hook still running (C<TERM> to its process group,
C<KILL> after two seconds, as C<claude -p> does at the end); they end as
C<cancelled> and show up in L</take_async_results>. Returns a future that
is done when they have ended.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Hooks::Result>

=item * L<Langertha::Raider::ToolNames>

=item * L<Langertha::Raider::Context::Settings/hooks>

=item * L<Langertha::Raider::Context::Plugins/hooks>

=item * Claude Code's hooks reference, L<https://code.claude.com/docs/en/hooks>

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
