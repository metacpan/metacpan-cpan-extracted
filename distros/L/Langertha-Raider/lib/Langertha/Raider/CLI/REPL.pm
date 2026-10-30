package Langertha::Raider::CLI::REPL;
# ABSTRACT: Internal interactive loop of the raider CLI
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Config;
use Encode qw( decode encode FB_QUIET );
use Future;
use IO::Handle;
use JSON::MaybeXS ();
use List::Util qw( first );
use POSIX ();
use Path::Tiny;
use Scalar::Util qw( weaken );
use Term::ANSIColor qw( color );
use Term::ReadLine;                   # Core; upgrades to Gnu if installed
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Runner;


has app => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CLI',
  required => 1,
);

has output => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CLI::Output',
  required => 1,
);

has in => (
  is      => 'ro',
  default => sub { \*STDIN },
);

has can_ask => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { -t $_[0]->in ? 1 : 0 },
);

has active_profiles => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
);

has saved_profiles => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

has customize_prompt => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has session_store => (
  is        => 'ro',
  isa       => 'Langertha::Raider::SessionStore',
  predicate => 'has_session_store',
);

has session => (
  is        => 'ro',
  isa       => 'Langertha::Raider::Session',
  writer    => '_set_session',
  predicate => 'has_session',
);


has notes => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
);

has commands => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_commands',
);

sub _build_commands {
  my ($self) = @_;
  return Langertha::Raider::CLI::Commands->new(app => $self->app, output => $self->output, in => $self->in);
}

has runner => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_runner',
);

sub _build_runner {
  my ($self) = @_;
  return Langertha::Raider::CLI::Runner->new(app => $self->app, output => $self->output);
}

my $LOGO = <<'LOGO';
             __     __
.----.---.-.|__|.--|  |.-----.----.
|   _|  _  ||  ||  _  ||  -__|   _|
|__| |___._||__||_____||_____|__|
LOGO


sub banner {
  my ( $self, $rl_impl ) = @_;
  my $app = $self->app;
  my $out = $self->output;
  my $line = sub { $out->emit($out->c(meta => $_[0]), $out->c(title => $_[1]), "\n") };

  my $env = $app->api_key_env;
  my $resolver = $app->engine_resolver;
  my $env_display = $resolver->has_provider
    # --provider: the key comes from -k, never from the environment, and
    # only an endpoint with an auth_ref needs one. Never print the key.
    ? ( defined $resolver->provider->{auth}
        ? 'auth '.$resolver->provider->{auth}.' ('.( length $resolver->api_key ? 'set' : 'missing' ).')'
        : length $resolver->api_key ? '(the endpoint asks for none; the key you gave is set and sent)'
        : '(no API key required)' )
    : defined $env
      ? ($ENV{$env} ? $env.' (set)' : $env.' (missing)')
      : '(no API key required)';
  my $model = $app->has_model ? $app->model : '(engine default)';
  my $source = $app->mission_source;
  my $file   = $app->instructions->label;
  my $persona = $source eq '-M'   ? 'from -M ('.$file.' not used)'
              : $source eq q(claude base) ? q(Claude Code base text (CLAUDE.md memory, no persona))
              : $source eq $file  ? 'custom ('.$file.' loaded)'
              :                     'Langertha (default)';
  $persona .= ', bare (no '.$file.' or skills, only explicit packs)' if $app->bare;

  $out->emit($out->c(brand => $LOGO));
  $out->emit($out->c(accent => ' perl agent - powered by Langertha'), "\n\n");
  $line->('persona:  ', $persona);

  if (my @profiles = @{ $self->active_profiles }) {
    $line->('profiles: ', join(', ', map { $_.($self->saved_profiles->{$_} ? ' (saved)' : '') } @profiles));
  }

  my $context = $app->context;
  my $layout = $context->layout;
  $line->('layout:   ', $layout->mode.' ('.$layout->reason.')'
    .( $context->claude_layout && $layout->mode ne 'claude' ? ', Claude layout on ('.$layout->claude_layout_reason.')' : '' ));
  if (my @memory = $context->instruction_items) {
    $line->('memory:   ', join(', ', map { $_->{label} } @memory));
  }

  my @skills = $app->loaded_skill_names;
  $line->('skills:   ', @skills
    ? sprintf('%d listed (%s)', scalar @skills, join(', ', @skills))
    : 'none');

  my @active_packs = @{$app->packs->active_pack_names};
  $line->('packs:    ', join(', ', @active_packs)) if @active_packs;

  for my $ign ($app->ignored_agent_files) {
    $out->emit($out->c(meta => '          '),
      $out->c(warn => 'seeing '.$ign->{path}.', ignoring (use --'.$ign->{profile}.' to load)'), "\n");
  }
  if ($resolver->has_provider) {
    my $p = $resolver->provider;
    $line->('provider: ', ( defined $p->{alias} ? $p->{alias}.' (stored alias, ' : '(' ).( $p->{provider_id} // '' )
      .', endpoint '.( $p->{endpoint} // '' ).', '.( $p->{url} // '' ).')');
  }
  $line->('engine:   ', $app->engine_name);
  $line->('model:    ', $model);
  $line->('api key:  ', $env_display);
  $line->('root:     ', $app->root);
  $line->('session:  ', $self->has_session ? $self->session->id.' ('.$self->session->path.')'
                      : $self->has_session_store ? 'new, saved from the first prompt on'
                      : 'off');
  $line->('readline: ', $rl_impl);
  $out->emit($out->c(meta => 'type '), $out->c(accent => '/help'), $out->c(meta => ' for commands, '),
    $out->c(accent => '/quit'), $out->c(meta => ' to leave'), "\n\n");
  return;
}


sub run {
  my ( $self, @first ) = @_;
  my $out = $self->output;
  my $in  = $self->in;

  if ( $self->can_ask ) {
    weaken( my $repl = $self );
    $self->app->on_ask_user( sub { $repl ? $repl->ask_user(@_) : undef } );
    $self->app->on_permission_request( sub { $repl ? $repl->permission_request(@_) : undef } );
    $self->app->on_plan_review( sub { $repl ? $repl->plan_review(@_) : undef } );
  }

  my $rl = -t $in ? $self->_terminal_reader : {
    read => sub { $self->read_line($in) },
    impl => 'none (input is not a terminal)',
  };
  my $call = sub { my $cb = $rl->{ $_[0] }; $cb->(@_[ 1 .. $#_ ]) if $cb };

  # Two-strike Ctrl-C: first press cancels the turn in progress (or only
  # warns at the prompt), second within 2s exits. Saves the user from
  # accidentally killing raider and removes the old "Ctrl-C + Return"
  # Docker quirk. Cancelling and leaving end the tool commands still
  # running: a bash command sits in a process group of its own and would
  # outlive raider. Leaving stops the background subagents too; the first
  # Ctrl-C leaves them running (ADR 0027 section 3).
  my $leave = sub {
    my ( $signal ) = @_;
    local $SIG{INT}  = 'IGNORE';
    local $SIG{TERM} = 'IGNORE';
    $call->('cleanup');
    $self->runner->terminate_children;
    $self->runner->abandon($signal);
    $self->app->stop_background;
    $self->app->close_worktree_session('session_end');
    $out->emit("\n");
    $out->say_meta($_) for $self->app->take_meta_notes;   # kept worktrees (ADR 0032)
    $call->('save');
    $out->emit($out->c(meta => "bye."), "\n");
    exit 0;
  };
  my $last_sigint = 0;
  local $SIG{INT} = sub {
    my $now = time;
    $leave->('INT') if $last_sigint && $now - $last_sigint <= 2;
    $last_sigint = $now;
    # Only a flag and signals: a die here would be swallowed by an eval.
    if ($self->runner->cancel_run) {
      $out->emit($out->c(meta => "\n(cancelling the turn; press Ctrl-C again within 2s to quit)"), "\n");
      return;
    }
    $out->emit($out->c(meta => "\n(press Ctrl-C again within 2s to quit)"), "\n");
    $call->('redisplay');
  };
  local $SIG{TERM} = $leave;

  $self->banner($rl->{impl});
  $out->say_meta($_) for @{ $self->notes };
  $self->approve_mcp_servers;
  $self->commands->cmd_prompt if $self->customize_prompt;
  if (@first) { my $first = join ' ', @first; $first =~ m{^/} ? $self->run_slash($first) : $self->run_prompt($first) }

  my $quit;
  while (1) {
    my $line = $rl->{read}->();
    # Notifications of background subagents and nothing typed: a turn.
    if (ref $line) {
      $self->run_notifications;
      next;
    }
    last unless defined $line;
    $line =~ s/^\s+|\s+$//g;
    next unless length $line;

    if ($line =~ m{^(?:/quit|/exit|:q|quit|exit)$}i) {
      $out->emit($out->c(meta => 'bye.'), "\n");
      $quit = 1;
      last;
    }
    $call->(add => $line);
    if ($line =~ m{^/}) {
      $self->run_slash($line);
      next;
    }
    if ($line =~ m{\A([!?])\s*(\S.*)\z}s) {
      $1 eq '!' ? $self->run_shell($2) : $self->run_shell_prompt($2);
      next;
    }
    $self->run_prompt($line);
  }

  $call->('cleanup');
  # Piped input has ended: its background agents are waited for, their
  # notifications delivered (ADR 0027 section 3).
  $self->finish_background unless $quit || -t $in;
  $self->app->stop_background;
  $self->app->close_worktree_session('session_end');
  $out->say_meta($_) for $self->app->take_meta_notes;   # kept worktrees (ADR 0032)
  $call->('save');
  $self->app->shutdown_hooks;
  $self->app->shutdown_mcp;
  return;
}


sub run_notifications {
  my ( $self, %o ) = @_;
  my $app = $self->app;
  my $ok  = 1;
  if ( my @items = $app->take_notifications ) {
    $self->output->say_meta( $_->{label} // 'background task '.( $_->{id} // '?' ).' ended' ) for @items;
    $ok = $self->runner->run_prompt( join( "\n", map { $_->{text} } @items ),
      session => scalar $self->_session_for_run, notification => 1, %o );
  }
  # The prompts of cron jobs that came due (ADR 0031): the surface is idle
  # now, each runs as a turn of its own, as if typed. Not while the REPL only
  # waits for background work at the end of piped input.
  unless ( $o{wait_background} ) {
    for my $job ( $app->take_scheduled ) {
      $self->output->say_meta( $job->{label} // 'scheduled job '.( $job->{id} // '?' ).' fired' );
      $ok = $self->run_prompt( $job->{text} );
    }
  }
  return $ok;
}


sub finish_background {
  my ( $self ) = @_;
  my $app = $self->app;
  while ( $app->wait_for_notifications ) {
    $self->run_notifications( wait_background => 1 );
  }
  return;
}


sub read_line {
  my ( $self, $in, $prompt ) = @_;
  my $app = $self->app;
  my $out = $self->output;
  if (defined $prompt) {
    $out->emit($prompt);
    $out->out->flush;
  }
  my $partial = '';
  while (1) {
    my ( $state, $chunk ) = $self->_poll_line($in);
    return $partial.$chunk if $state eq 'line';
    return length $partial ? $partial : undef if $state eq 'eof';
    $partial .= $chunk if defined $chunk;
    if (!length $partial && $app->idle_pending) {
      $out->emit("\n") if defined $prompt;
      return \'notifications';
    }
    $self->_await_input($in, notifications => !length $partial);
  }
}

# Reads from $in what is there without blocking: ( line => $text ) for a
# whole line (or the last one, without a newline, at the end), ( partial =>
# $text ) for the start of one, ( 'none' ) when nothing is there yet, and
# ( 'eof' ) at the end. A handle that cannot be non-blocking (an in-memory
# one) is read as it is.
sub _poll_line {
  my ( $self, $in ) = @_;
  my $blocking = eval { $in->blocking(0) };
  local $!;
  my $chunk = readline $in;
  my $again = $!{EAGAIN} || $!{EWOULDBLOCK} ? 1 : 0;
  eval { $in->blocking($blocking) } if defined $blocking;
  $in->clearerr if $again;
  if (defined $chunk) {
    return ( line => $chunk ) if $chunk =~ /\n\z/ || !$again;
    return ( partial => $chunk );
  }
  return $again ? ('none') : ('eof');
}

# Runs the loop until $in is readable -- or, with notifications, until a
# notification for the main conversation is due. True when $in is
# readable.
sub _await_input {
  my ( $self, $in, %o ) = @_;
  my $app   = $self->app;
  my $loop  = $app->loop;
  my $ready = $loop->new_future;
  $loop->watch_io( handle => $in, on_read_ready => sub { $ready->done(1) unless $ready->is_ready } );
  my $f = $o{notifications} ? Future->wait_any( $ready, $app->idle_wait_f ) : $ready;
  $loop->await($f);
  $loop->unwatch_io( handle => $in, on_read_ready => 1 );
  return $ready->is_done ? 1 : 0;
}


sub ask_user {
  my ( $self, $question, $options ) = @_;
  $options //= [];
  my $out = $self->output;
  my $in  = $self->in;
  $out->emit( $out->c( title => '? '.$question ), "\n" );
  $out->emit( $out->c( meta => '  '.( $_ + 1 ).') '.$options->[$_] ), "\n" ) for 0 .. $#$options;
  $out->emit( $out->c( meta => ( @$options ? 'answer (a number picks an option)' : 'answer' ).'> ' ) );
  my $line = <$in>;
  return unless defined $line;
  $line =~ s/^\s+|\s+\z//g;
  return unless length $line;
  return $options->[ $line - 1 ] if $line =~ /\A\d+\z/ && $line >= 1 && $line <= @$options;
  return $line;
}


sub permission_request {
  my ( $self, $req ) = @_;
  my $out  = $self->output;
  my $in   = $self->in;
  my $rule = $req->{rule};
  $out->emit( $out->c( title => '? allow '.$req->{tool}.': ' ), $self->call_summary($req), "\n" );
  $out->emit( $out->c( meta => '  ('.$req->{reason}.')' ), "\n" ) if defined $req->{reason};
  $out->emit( $out->c( meta => '  1) yes, once' ), "\n" );
  $out->emit( $out->c( meta => '  2) yes, for this session: '.$rule ), "\n" ) if defined $rule;
  $out->emit( $out->c( meta => '  3) no, and tell the model why' ), "\n" );
  while (1) {
    $out->emit( $out->c( meta => 'choice> ' ) );
    my $line = <$in>;
    return { answer => 'no' } unless defined $line;
    $line =~ s/^\s+|\s+\z//g;
    return { answer => 'once' } if $line =~ /\A(?:1|y|yes)\z/i;
    return { answer => 'session' } if defined $rule && $line eq '2';
    if ( $line =~ /\A(?:3|n|no)\z/i ) {
      $out->emit( $out->c( meta => 'reason (optional)> ' ) );
      my $why = <$in>;
      $why = '' unless defined $why;
      $why =~ s/^\s+|\s+\z//g;
      return { answer => 'no', ( length $why ? ( reason => $why ) : () ) };
    }
  }
}


sub approve_mcp_servers {
  my ( $self ) = @_;
  my $app = $self->app;
  my $out = $self->output;
  unless ( $self->can_ask ) {
    $out->say_meta($_) for $app->mcp_notes;
    return;
  }
  weaken( my $repl = $self );
  for my $ans ( $app->ask_mcp_approvals( sub { $repl ? $repl->mcp_approval(@_) : undef } ) ) {
    my %word = ( approve => 'approved', all => 'approved, with every other project server', reject => 'rejected' );
    $out->say_meta( 'mcp: '.$ans->{name}.' '.$word{ $ans->{answer} }
      .( defined $ans->{written} ? ' (saved in '.$ans->{written}.')' : ' (for this session)' ) );
  }
  return;
}

sub mcp_approval {
  my ( $self, $server ) = @_;
  my $out = $self->output;
  my $in  = $self->in;
  my $what = $server->{transport} eq 'http' ? $server->{url}
    : join ' ', grep { defined } $server->{command}, @{ $server->{args} // [] };
  $what = substr( $what, 0, 200 ).'...' if length $what > 200;
  $out->emit( $out->c( title => '? new MCP server in '.$server->{source}.': '.$server->{name} ), "\n" );
  $out->emit( $out->c( meta => '  '.$server->{transport}.': '.$what ), "\n" );
  $out->emit( $out->c( meta => '  1) use this MCP server' ), "\n" );
  $out->emit( $out->c( meta => '  2) use this and all future MCP servers in this project' ), "\n" );
  $out->emit( $out->c( meta => '  3) continue without using this MCP server' ), "\n" );
  while (1) {
    $out->emit( $out->c( meta => 'choice> ' ) );
    my $line = <$in>;
    return unless defined $line;
    $line =~ s/^\s+|\s+\z//g;
    return 'approve' if $line =~ /\A(?:1|y|yes)\z/i;
    return 'all'     if $line eq '2';
    return 'reject'  if $line =~ /\A(?:3|n|no)\z/i;
  }
}


sub call_summary {
  my ( $self, $req ) = @_;
  my $args = ref $req->{arguments} eq 'HASH' ? $req->{arguments} : {};
  my $text = first { defined && !ref } map { $args->{$_} } qw( command path url query );
  $text //= JSON::MaybeXS->new( canonical => 1, allow_nonref => 1 )->encode($args);
  $text = substr( $text, 0, 200 ).'...' if length $text > 200;
  return $text;
}


sub plan_review {
  my ( $self, $plan ) = @_;
  my $out = $self->output;
  my $in  = $self->in;
  $out->emit( $out->c( title => '? the plan:' ), "\n", $plan // '', "\n" );
  $out->emit( $out->c( meta => 'accept the plan? [y/n]> ' ) );
  my $line = <$in>;
  return { approve => 0 } unless defined $line;
  $line =~ s/^\s+|\s+\z//g;
  return { approve => 1 } if $line =~ /\A(?:y|yes|1)\z/i;
  $out->emit( $out->c( meta => 'what should change? (optional)> ' ) );
  my $feedback = <$in>;
  $feedback = '' unless defined $feedback;
  $feedback =~ s/^\s+|\s+\z//g;
  return { approve => 0, ( length $feedback ? ( feedback => $feedback ) : () ) };
}


sub run_prompt {
  my ( $self, $text, %run ) = @_;
  my $app = $self->app;
  my @items = $app->take_notifications;
  $self->output->say_meta( $_->{label} // 'background task '.( $_->{id} // '?' ).' ended' ) for @items;
  my $reminders = join "\n\n", map { $app->tasks->reminder_text( $_->{text} ) } @items;
  return $self->runner->run_prompt($text, session => scalar $self->_session_for_run,
    ( map { defined $run{$_} ? ( $_ => $run{$_} ) : () } $self->runner->run_options ),
    ( @items ? ( reminders => $reminders ) : () ));
}


sub run_slash {
  my ( $self, $line ) = @_;
  my $r = $self->commands->dispatch($line, session => sub { scalar $self->_session_for_run });
  return $self->run_prompt($r->{prompt}, %$r) if ref $r eq 'HASH';
  # A resume must not bring back what /clear removed (ADR 0015).
  $self->runner->record($self->session, 'history.cleared')
    if $r && $self->has_session && $line =~ m{\A/(?:clear|reset|new)(?:\s|\z)};
  return $r;
}


sub run_shell {
  my ( $self, $command ) = @_;
  # Ctrl-C reaches the command and raider alike; it is for the command.
  local $SIG{INT}  = 'IGNORE';
  local $SIG{QUIT} = 'IGNORE';
  my $pid = $self->_spawn_shell($command) // return;
  waitpid $pid, 0;
  my $status = $?;
  $self->output->say_meta($self->_shell_status_text($status)) if $status;
  return $status;
}


sub run_shell_prompt {
  my ( $self, $command ) = @_;
  my $out = $self->output;
  my ( $text, $status ) = ( '' );
  {
    local $SIG{INT}  = 'IGNORE';
    local $SIG{QUIT} = 'IGNORE';
    my ( $r, $w );
    unless (pipe $r, $w) {
      $out->say_error('cannot run the command: '.$!);
      return 0;
    }
    my $pid = $self->_spawn_shell($command, $w);
    close $w;
    unless (defined $pid) {
      close $r;
      return 0;
    }
    my $bytes = '';
    while (1) {
      my $n = sysread $r, $bytes, 65536, length $bytes;
      next if !defined $n && $!{EINTR};
      last unless $n;
      my $chunk = $self->_decode_output(\$bytes);
      $out->emit($chunk);
      $out->out->flush;
      $text .= $chunk;
    }
    close $r;
    if (length $bytes) {
      # What is left can be no character: replaced.
      my $rest = decode('UTF-8', $bytes);
      $out->emit($rest);
      $text .= $rest;
    }
    $out->emit("\n") if length $text && $text !~ /\n\z/;
    waitpid $pid, 0;
    $status = $?;
  }
  if ($self->_signal_name($status & 127) eq 'INT') {
    $out->say_meta('command interrupted (SIGINT), nothing sent to the model');
    return 0;
  }
  $out->say_meta($self->_shell_status_text($status)) if $status;
  return $self->run_prompt($self->shell_prompt($command, $status, $text));
}


sub shell_output_limit { 20_000 }

sub shell_prompt {
  my ( $self, $command, $status, $output ) = @_;
  my $limit = $self->shell_output_limit;
  if (length $output > $limit) {
    my $half = int($limit / 2);
    $output = substr($output, 0, $half)
      ."\n[... ".(length($output) - 2 * $half)." characters omitted ...]\n"
      .substr($output, -$half);
  }
  $output =~ s/\n\z//;
  return join "\n",
    'I ran a shell command in '.$self->app->root.':',
    '',
    '$ '.$command,
    '',
    'Result: '.$self->_shell_status_text($status),
    '',
    length $output ? ( 'Output (stdout and stderr):', $output ) : '(no output)';
}

# Forks the shell running $command in the app's root. With $capture, its
# stdout and stderr go there and stdin comes from /dev/null; without, it
# has raider's terminal. The pid, or undef after an error line.
sub _spawn_shell {
  my ( $self, $command, $capture ) = @_;
  my $shell = $ENV{SHELL} || '/bin/sh';
  my $root  = $self->app->root;
  my $pid = fork;
  unless (defined $pid) {
    $self->output->say_error('cannot run the command: '.$!);
    return;
  }
  return $pid if $pid;

  # The child: never back into raider's code, whatever fails.
  $SIG{INT} = $SIG{QUIT} = 'DEFAULT';
  if ($capture) {
    open STDIN,  '<',  '/dev/null';
    open STDOUT, '>&', $capture;
    open STDERR, '>&', $capture;
  }
  unless (chdir $root) {
    print STDERR 'raider: cannot change to '.$root.': '.$!."\n";
    POSIX::_exit(126);
  }
  { exec { $shell } $shell, '-c', encode('UTF-8', $command) }
  print STDERR 'raider: cannot run '.$shell.': '.$!."\n";
  POSIX::_exit(127);
}

# The complete UTF-8 characters at the start of $$bytes, which keeps a
# character cut off at its end for the next read. A byte that starts no
# character becomes U+FFFD.
sub _decode_output {
  my ( $self, $bytes ) = @_;
  my $text = '';
  while (length $$bytes) {
    $text .= decode('UTF-8', $$bytes, FB_QUIET);
    last if length $$bytes < 4;
    substr($$bytes, 0, 1, '');
    $text .= "\x{FFFD}";
  }
  return $text;
}

# A wait status for the user: "exit status N", "interrupted (SIGINT)",
# "killed by SIGTERM".
sub _shell_status_text {
  my ( $self, $status ) = @_;
  my $signal = $status & 127;
  return 'exit status '.($status >> 8) unless $signal;
  my $name = $self->_signal_name($signal);
  return $name eq 'INT' ? 'interrupted (SIGINT)' : 'killed by SIG'.$name;
}

# The name of the signal number (INT), empty for 0.
sub _signal_name {
  my ( $self, $number ) = @_;
  return $number ? ( split ' ', $Config{sig_name} )[$number] // $number : '';
}

sub _session_for_run {
  my ( $self ) = @_;
  return $self->session if $self->has_session;
  return unless $self->has_session_store;
  my $out = $self->output;
  my $session = eval { $self->session_store->create };
  unless ($session) {
    my $error = $out->error_text($@);
    $out->say_error('session not saved: '.$error);
    return;
  }
  $self->_set_session($session);
  $out->say_meta('session '.$session->id.' ('.$session->path.')');
  return $session;
}

# Line reader on a terminal: { read, impl, add, save, redisplay, cleanup }.
# Both run the application's loop while they wait (ADR 0027 section 4).
sub _terminal_reader {
  my ($self) = @_;
  # Prefer Term::ReadLine::Gnu (line editing + persistent history).
  # Fall back to a prompt of our own when Gnu isn't installed.
  my $term = Term::ReadLine->new('raider');
  unless ($term->ReadLine =~ /Gnu/) {
    my $out = $self->output;
    my $ps  = $out->c(prompt => 'raider>').' ';
    return {
      read      => sub { $self->read_line($self->in, $ps) },
      impl      => 'raider (install Term::ReadLine::Gnu for line editing and history)',
      redisplay => sub { $out->emit($ps); $out->out->flush },
    };
  }

  $term->ornaments(0);
  my $histfile = path($ENV{HOME} // '.')->child('.raider_history')->stringify;
  eval { $term->ReadHistory($histfile) } if -f $histfile;
  # Take SIGINT away from readline so our Perl handler always runs — with
  # catch_signals=1 (the default) Gnu's internal handler swallows Ctrl-C and
  # ours only fires after the next Return, which is the Docker annoyance.
  eval { $term->Attribs->{catch_signals} = 0 };
  # Gray prompt, plain-color user input. Non-printing sequences are
  # wrapped in \x01...\x02 so readline computes prompt width correctly.
  my $ps = "\x01".color('bright_black')."\x02".'raider> '."\x01".color('reset')."\x02";
  return {
    read      => $self->_callback_reader($term, $ps),
    impl      => $term->ReadLine,
    add       => sub { $term->addhistory($_[0]) },
    save      => sub { eval { $term->WriteHistory($histfile) } },
    cleanup   => sub { eval { $term->callback_handler_remove } },
    redisplay => sub {
      eval {
        $term->replace_line('', 0);
        $term->Attribs->{point} = 0;
        $term->Attribs->{end}   = 0;
        $term->on_new_line;
        $term->redisplay;
      };
    },
  };
}

# The read of Term::ReadLine::Gnu through its callback interface: the
# characters of the terminal are fed to readline as the loop sees them
# arrive, and the loop runs meanwhile. With nothing typed, notifications
# that are due end the read (\'notifications', see read_line); once
# something is typed they wait for the line.
sub _callback_reader {
  my ( $self, $term, $ps ) = @_;
  return sub {
    my $in = $self->in;
    my ( $line, $got );
    $term->callback_handler_install( $ps, sub {
      ( $line ) = @_;
      $got = 1;
      $term->callback_handler_remove;
    } );
    until ($got) {
      my $idle = !length( $term->Attribs->{line_buffer} // '' );
      if ($idle && $self->app->idle_pending) {
        $term->callback_handler_remove;
        $self->output->emit("\n");
        return \'notifications';
      }
      $term->callback_read_char if $self->_await_input($in, notifications => $idle);
    }
    return $line;
  };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CLI::REPL - Internal interactive loop of the raider CLI

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    Langertha::Raider::CLI::REPL->new(app => $app, output => $out)->run(@first_prompt);

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The F<raider> REPL: banner, line reading, slash commands via
L<Langertha::Raider::CLI::Commands>, every other line a prompt via
L<Langertha::Raider::CLI::Runner>, until C</quit>, C</exit>, C<:q>,
C<quit>, C<exit> or the end of input.

A line C<!CMD> runs C<CMD> in the shell and nothing else
(L</run_shell>); a line C<?CMD> runs it and then sends the command, its
exit status and its output to the model as the next prompt
(L</run_shell_prompt>). A line that is only C<!> or C<?> is a prompt.

On a terminal, lines come from L<Term::ReadLine::Gnu> (line editing,
F<~/.raider_history>), else the REPL prints its own prompt and reads the
line itself.

While it waits for a line the REPL runs the application's loop (ADR 0027
E<sect>4), so background subagents go on working: with
L<Term::ReadLine::Gnu> through its callback interface (the characters fed
from a watcher on the loop), otherwise by running the loop until the input
is readable (L</read_line>). When a background subagent of the main
conversation ends while nothing is typed, its notification starts a turn
of its own, shown as C<background agent agent_1 finished>
(L</run_notifications>); notifications that are due when a line is
submitted go in front of it, in the same turn, each in a
C<< <system-reminder> >> (L</run_prompt>). At the end of input that is not
a terminal the REPL waits for its background subagents and delivers their
notifications before it ends (L</finish_background>); leaving it any other
way -- C</quit>, Ctrl-D, a second Ctrl-C, C<SIGTERM> -- stops them
(L<Langertha::Raider::Application/stop_background>). The first Ctrl-C
leaves them running. However the REPL is left, a worktree the session
still works in is closed (ADR 0032 E<sect>5,
L<Langertha::Raider::Application/close_worktree_session>): removed when
C<enter_worktree> made it and it has no changes, else kept and named in a
meta line before C<bye.>.

The first C<SIGINT> (Ctrl-C) while a prompt runs cancels that turn
(L<Langertha::Raider::CLI::Runner/cancel_run>): the tool commands still
running are ended, the raid stops at its next safe point, C<turn
cancelled> is printed, the session journal ends the run as C<cancelled>,
and the REPL reads the next line. At the prompt the first Ctrl-C only
warns. A second one within two seconds, or a C<SIGTERM>, leaves the REPL
with exit status 0, after ending the tool commands still running
(L<Langertha::Raider::CLI::Runner/terminate_children>). While a C<!CMD>
or C<?CMD> runs, raider ignores C<SIGINT>, so Ctrl-C ends the command
alone. When L</in>
is not a terminal, lines are read from it as they are, without prompt, so
piped input ends the REPL at its end.

=head2 app

The L<Langertha::Raider::CLI>. Required.

=head2 output

The L<Langertha::Raider::CLI::Output> to print to. Required.

=head2 in

Filehandle lines are read from when it is not a terminal. Defaults to
C<STDIN>.

=head2 can_ask

Whether a person answers the model's questions (the C<ask_user> tool,
L</ask_user>), approves tool calls (L</permission_request>) and reviews
plans (L</plan_review>). Defaults to whether L</in> is a terminal; without
one the tool refuses and the model decides itself, and a call the
permission policy asks about is refused.

=head2 active_profiles

Agent profiles to show in the banner (C<claude>, C<openai>).

=head2 saved_profiles

Profiles saved to the config file by this start, marked C<(saved)>.

=head2 customize_prompt

Start with the prompt-builder (C<--customize-prompt>).

=head2 session_store

The L<Langertha::Raider::SessionStore> a new session is created in, with
the first prompt. Without one (C<--no-session>) nothing is recorded.

=head2 session

The L<Langertha::Raider::Session> the prompts are recorded in, once there
is one. A C</clear> is recorded there too, as C<history.cleared>, so
resuming the session starts with an empty history again.

=head2 notes

Lines printed right after the banner: what resuming L</session> found
(L<Langertha::Raider::CLI::Sessions/restore>).

=head2 banner

    $repl->banner($readline_impl);

Prints the logo and the live configuration: mission source, profiles,
layout mode (ADR 0019) and the memory files it loads, the listed
skills, packs, ignored agent files, engine, model, API key, root.

=head2 run

    $repl->run(@first_prompt);

Runs the REPL; C<@first_prompt> (the words given on the command line) is
sent first. Returns when the user leaves.

=head2 run_notifications

    my $ok = $repl->run_notifications;
    $ok = $repl->run_notifications(wait_background => 1);

A turn of the notifications that wait for the main conversation (ADR 0027
E<sect>4): a meta line for each (C<background agent agent_1 finished>),
then one prompt of them all, in the order their work ended, recorded with
C<notification> 1. Further options go to
L<Langertha::Raider::CLI::Runner/run_prompt>. Then the prompt of every cron
job that came due (ADR 0031) runs as a turn of its own through
L</run_prompt>, after a meta line that names the job -- not with
C<wait_background>. Returns what the runner returns, true when nothing was
due.

=head2 finish_background

At the end of input that is not a terminal: as long as background
subagents of the main conversation run or their notifications wait, waits
for them on the loop (L<Langertha::Raider::Application/wait_for_notifications>)
and delivers them in a turn that waits for the rest
(L</run_notifications> with C<wait_background>).

=head2 read_line

    my $line = $repl->read_line($in);             # input that is not a terminal
    my $line = $repl->read_line($in, 'raider> '); # a terminal without Term::ReadLine::Gnu

One line from C<$in> without stopping the application's loop (ADR 0027
E<sect>4): what is there is read without blocking, and while no whole line
is, the loop runs until C<$in> is readable. Returns the line, C<undef> at
the end of the input, or a reference (C<\'notifications'>) when
notifications of background work wait for the main conversation, or the
prompt of a cron job is due (ADR 0031), and no part of a line has come yet
-- the REPL then runs them as a turn. With
C<$prompt>, that is printed first (and a line break before such a turn).

=head2 ask_user

    my $answer = $repl->ask_user($question, \@options);

Puts the model's question to the person: the question, the options
numbered, then a line read from L</in>. A number that names an option
answers with that option's text, any other line is the answer as typed.
Returns undef when the input is closed or the line is empty. The REPL
registers this as the application's
L<on_ask_user|Langertha::Raider::Application/on_ask_user> when it can ask.

=head2 permission_request

    my $answer = $repl->permission_request({ tool => 'bash', arguments => { command => 'make' },
      reason => '...', rule => 'Bash(make)' });

Puts a tool call the permission policy asks about to the person (ADR
0021): the tool and what it would do (the command, the path, the URL), why
it asks, then the choices -- C<1> yes, once; C<2> yes, for this session,
naming the rule that is added (only when there is one); C<3> no. C<y> and
C<n> work too. A "no" asks for an optional reason, which the model gets.
Returns C<< { answer => 'once' | 'session' | 'no', reason => ... } >>; a
closed input is a "no". The REPL registers this as the application's
L<on_permission_request|Langertha::Raider::Application/on_permission_request>
when it can ask -- for every raider of the application, the prompt builder's
too.

=head2 approve_mcp_servers

    $repl->approve_mcp_servers;

Before the first prompt: every project MCP server that waits for an
approval (ADR 0029 E<sect>7) is put to the person once with
L</mcp_approval>, through
L<Langertha::Raider::Application/ask_mcp_approvals>, and each answer is
reported with where it was saved. When the REPL cannot ask (input is not a
terminal), the servers stay off and L<Langertha::Raider::Application/mcp_notes>
says so.

=head2 mcp_approval

    my $answer = $repl->mcp_approval($server);   # 'approve', 'all', 'reject' or undef

Claude Code's three choices for a pending project server: C<1> use this
server, C<2> use this and all future MCP servers of this project, C<3>
continue without it (C<y> / C<n> work too). A closed input is no answer:
the server stays pending.

=head2 call_summary

    my $text = $repl->call_summary({ tool => 'bash', arguments => { command => 'ls' } });   # 'ls'

What a call would do, in one line for the question: the command of
C<bash>, the C<path> of a file tool, the C<url> of C<web_fetch>, the
C<query> of C<web_search>, else the arguments as JSON -- cut at 200
characters.

=head2 plan_review

    my $answer = $repl->plan_review($plan);   # { approve => 1 } or { approve => 0, feedback => ... }

Shows the plan the model presents with C<exit_plan_mode> and asks whether
to accept it: C<y> accepts (the permission mode becomes C<default>),
anything else asks for feedback, which the model gets. A closed input
does not accept. Registered as
L<on_plan_review|Langertha::Raider::Application/on_plan_review> when the
REPL can ask.

=head2 run_prompt

    $repl->run_prompt($text);
    $repl->run_prompt($text, %run);   # with run options (a /name run request)

Runs one prompt through the runner, recorded in L</session>. The first
prompt with a L</session_store> starts the session and names it. The
notifications of background subagents that wait for the main conversation
go in front of the prompt, each wrapped as Claude Code delivers one next to
a genuine message (L<Langertha::Raider::Tasks/reminder_text>, ADR 0027
E<sect>4), after a meta line for each. C<%run> are the run options of
L<Langertha::Raider::CLI::Runner/run_options>.

=head2 run_slash

    $repl->run_slash('/review src/App.pm');

A C</...> line (also the first prompt from the command line): resolved by
L<Langertha::Raider::CLI::Commands/dispatch>. A run request it returns (a
catalogue entry, C</init>, a path such as C</etc/hosts is broken>) runs as
the next prompt with its run options, recorded in L</session> -- through
L</run_prompt>, so notifications that wait go in front of it as in front
of a typed line (ADR 0027 E<sect>4). A C</clear>,
C</reset> or C</new> is recorded there as C<history.cleared>.

=head2 run_shell

    my $status = $repl->run_shell('git status');

The REPL's C<!CMD>: runs the command with C<$SHELL -c> (C</bin/sh>
without C<SHELL>) in the app's root, on the terminal raider runs on, so
C<less> or C<vim> work. A non-zero exit status is printed, as C<exit
status N>, a command ended by a signal as C<interrupted (SIGINT)> or
C<killed by SIGTERM>. Nothing goes to the model or into the session
journal. Returns the wait status, or undef when the command could not be
started.

=head2 run_shell_prompt

    my $ok = $repl->run_shell_prompt('make test');

The REPL's C<?CMD>: runs the command as L</run_shell> does, but with its
standard output and standard error shown as they come and captured, and
standard input from F</dev/null>. Then the command, its exit status and
the captured output (L</shell_prompt>) go to the model through
L</run_prompt>, as any prompt: the model answers, the session journal
records the turn. A command ended by Ctrl-C (C<SIGINT>) sends nothing,
since Ctrl-C in the REPL cancels the turn. Returns what L</run_prompt>
returns, false when nothing was sent.

=head2 shell_prompt

    my $prompt = $repl->shell_prompt($command, $wait_status, $output);

The prompt L</run_shell_prompt> sends: where the command ran, the command,
its exit status and its output. An output longer than
L</shell_output_limit> characters keeps its head and its tail, half the
limit each, with a line C<[... N characters omitted ...]> between them.

=head2 shell_output_limit

How many characters of a C<?CMD> output reach the model: 20000.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CLI::Main>

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
