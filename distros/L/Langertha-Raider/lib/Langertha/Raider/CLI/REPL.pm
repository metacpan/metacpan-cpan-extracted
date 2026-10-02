package Langertha::Raider::CLI::REPL;
# ABSTRACT: Internal interactive loop of the raider CLI
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Config;
use Encode qw( decode encode FB_QUIET );
use POSIX ();
use Path::Tiny;
use Term::ANSIColor qw( color );
use Term::ReadLine;                   # Core; upgrades to Gnu if installed
use IO::Prompt::Tiny qw( prompt );    # Fallback when Gnu is not available
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
        : '(no API key required)' )
    : defined $env
      ? ($ENV{$env} ? $env.' (set)' : $env.' (missing)')
      : '(no API key required)';
  my $model = $app->has_model ? $app->model : '(engine default)';
  my $source = $app->mission_source;
  my $file   = $app->instructions->label;
  my $persona = $source eq '-M'   ? 'from -M ('.$file.' not used)'
              : $source eq $file  ? 'custom ('.$file.' loaded)'
              :                     'Langertha (default)';
  $persona .= ', bare (no '.$file.' or skills, only explicit packs)' if $app->bare;

  $out->emit($out->c(brand => $LOGO));
  $out->emit($out->c(accent => ' perl agent - powered by Langertha'), "\n\n");
  $line->('persona:  ', $persona);

  if (my @profiles = @{ $self->active_profiles }) {
    $line->('profiles: ', join(', ', map { $_.($self->saved_profiles->{$_} ? ' (saved)' : '') } @profiles));
  }

  my @skills = $app->loaded_skill_names;
  $line->('skills:   ', @skills
    ? sprintf('%d loaded (%s)', scalar @skills, join(', ', @skills))
    : 'none');

  my @active_packs = @{$app->packs->active_pack_names};
  $line->('packs:    ', join(', ', @active_packs)) if @active_packs;

  for my $ign ($app->ignored_agent_files) {
    $out->emit($out->c(meta => '          '),
      $out->c(warn => 'seeing '.$ign->{path}.', ignoring (use --'.$ign->{profile}.' to load)'), "\n");
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

  my $rl = -t $in ? $self->_terminal_reader : {
    read => sub { my $l = <$in>; $l },
    impl => 'none (input is not a terminal)',
  };
  my $call = sub { my $cb = $rl->{ $_[0] }; $cb->(@_[ 1 .. $#_ ]) if $cb };

  # Two-strike Ctrl-C: first press cancels the turn in progress (or only
  # warns at the prompt), second within 2s exits. Saves the user from
  # accidentally killing raider and removes the old "Ctrl-C + Return"
  # Docker quirk. Cancelling and leaving end the tool commands still
  # running: a bash command sits in a process group of its own and would
  # outlive raider.
  my $leave = sub {
    my ( $signal ) = @_;
    local $SIG{INT}  = 'IGNORE';
    local $SIG{TERM} = 'IGNORE';
    $self->runner->terminate_children;
    $self->runner->abandon($signal);
    $call->('save');
    $out->emit($out->c(meta => "\nbye."), "\n");
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
  $self->commands->cmd_prompt if $self->customize_prompt;
  $self->run_prompt(join ' ', @first) if @first;

  while (defined(my $line = $rl->{read}->())) {
    $line =~ s/^\s+|\s+$//g;
    next unless length $line;

    if ($line =~ m{^(?:/quit|/exit|:q|quit|exit)$}i) {
      $out->emit($out->c(meta => 'bye.'), "\n");
      last;
    }
    $call->(add => $line);
    if ($line =~ m{^/}) {
      $self->commands->dispatch($line);
      # A resume must not bring back what /clear removed (ADR 0015).
      $self->runner->record($self->session, 'history.cleared')
        if $self->has_session && $line =~ m{\A/clear(?:\s|\z)};
      next;
    }
    if ($line =~ m{\A([!?])\s*(\S.*)\z}s) {
      $1 eq '!' ? $self->run_shell($2) : $self->run_shell_prompt($2);
      next;
    }
    $self->run_prompt($line);
  }

  $call->('save');
  return;
}


sub run_prompt {
  my ( $self, $text ) = @_;
  return $self->runner->run_prompt($text, session => scalar $self->_session_for_run);
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

# Line reader on a terminal: { read, impl, add, save, redisplay }.
sub _terminal_reader {
  my ($self) = @_;
  # Prefer Term::ReadLine::Gnu (line editing + persistent history).
  # Fall back to IO::Prompt::Tiny when Gnu isn't installed.
  my $term = Term::ReadLine->new('raider');
  return {
    read => sub { prompt('raider>') },
    impl => 'IO::Prompt::Tiny (install Term::ReadLine::Gnu for history)',
  } unless $term->ReadLine =~ /Gnu/;

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
    read      => sub { $term->readline($ps) },
    impl      => $term->ReadLine,
    add       => sub { $term->addhistory($_[0]) },
    save      => sub { eval { $term->WriteHistory($histfile) } },
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

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CLI::REPL - Internal interactive loop of the raider CLI

=head1 VERSION

version 0.503

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
F<~/.raider_history>) or L<IO::Prompt::Tiny>.

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
skills, packs, ignored agent files, engine, model, API key, root.

=head2 run

    $repl->run(@first_prompt);

Runs the REPL; C<@first_prompt> (the words given on the command line) is
sent first. Returns when the user leaves.

=head2 run_prompt

    $repl->run_prompt($text);

Runs one prompt through the runner, recorded in L</session>. The first
prompt with a L</session_store> starts the session and names it.

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

Please report bugs and feature requests on GitHub at
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

=cut
