package Langertha::Raider::CLI::Main;
# ABSTRACT: Internal command-line entry point behind bin/raider
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use utf8;
use Getopt::Long ();
use IO::Prompt::Tiny qw( prompt );
use Path::Tiny;
use Time::HiRes ();
use Langertha;
use Langertha::Raider;
use Langertha::Raider::ACP::CLI;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Machine;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::Provider;
use Langertha::Raider::CLI::REPL;
use Langertha::Raider::CLI::Runner;
use Langertha::Raider::CLI::Sessions;
use Langertha::Raider::Config;
use Langertha::Raider::Config::Migrate;
use Langertha::Raider::Hall::CLI;
use Langertha::Raider::SessionStore;
use Langertha::Raider::Skill;


use constant {
  EXIT_OK             => 0,
  EXIT_RUN_ERROR      => 1,
  EXIT_USAGE          => 2,
  EXIT_CONFIG         => 3,
  EXIT_SESSION_IN_USE => 4,
};

# The machine output flags (ADR 0013): flag => [ format, stream ].
my %MACHINE_FLAG = (
  json             => [ json    => 0 ],
  msgpack          => [ msgpack => 0 ],
  yaml             => [ yaml    => 0 ],
  'stream-json'    => [ json    => 1 ],
  'stream-msgpack' => [ msgpack => 1 ],
  'stream-yaml'    => [ yaml    => 1 ],
);


has output => (
  is      => 'ro',
  isa     => 'Langertha::Raider::CLI::Output',
  lazy    => 1,
  default => sub { Langertha::Raider::CLI::Output->new },
);

has err => (
  is      => 'ro',
  default => sub { \*STDERR },
);

has in => (
  is      => 'ro',
  default => sub { \*STDIN },
);

sub app_class     { 'Langertha::Raider::CLI' }
sub config_class  { 'Langertha::Raider::Config' }
sub migrate_class { 'Langertha::Raider::Config::Migrate' }
sub machine_class { 'Langertha::Raider::CLI::Machine' }
sub provider_class { 'Langertha::Raider::CLI::Provider' }
sub repl_class    { 'Langertha::Raider::CLI::REPL' }
sub runner_class  { 'Langertha::Raider::CLI::Runner' }
sub session_store_class { 'Langertha::Raider::SessionStore' }
sub sessions_class { 'Langertha::Raider::CLI::Sessions' }
sub skill_class   { 'Langertha::Raider::Skill' }

sub _warn {
  my ( $self, @text ) = @_;
  print { $self->err } @text;
  return;
}


sub usage { <<'USAGE' }
Usage: raider [options] [prompt...]
       raider config explain [options]     show each setting and its source
       raider config migrate [--dry-run]   move .raider.yml / .raider.md to
                                           .raider/ (see its --help)
       raider session list [options]       the project's sessions, newest first
       raider session show ID [--json]     one session, event by event
       raider session resume ID [options]  continue a session in the REPL
       raider session fork ID [--json]     a new session with its history
       raider session rm ID [--json]       delete a session
       raider provider inspect HOST [--json] [--allow-internal]
                                           fetch, validate and show a
                                           provider's manifest

Options:
  -e, --engine NAME        anthropic, openai, deepseek, groq, mistral, gemini,
                           minimax, cerebras, openrouter, ollama
                           (default: auto-detected from available *_API_KEY
                           env var — anthropic > openai > deepseek > ...)
  -m, --model NAME         Model identifier (engine-specific cheap default)
  -k, --api-key KEY        API key (overrides *_API_KEY env var)
      --provider HOST[:PORT] | https://HOST[:PORT]
                           Run on the model endpoint the provider's
                           manifest (/.well-known/langertha.json) declares;
                           nothing is stored. -m picks one of its models
                           (a must when it lists several); the key comes
                           only from -k, never from the config file or
                           the environment. Not with -e, -o engine= or -o url=
      --allow-internal     With --provider: allow a loopback, private,
                           link-local or reserved provider address
  -o, --option KEY=VALUE   Engine attribute (repeatable), e.g.
                           -o temperature=0.2 -o response_size=4096
                           Merged over the config file (.raider/config.yml,
                           else .raider.yml); CLI wins. raider's own
                           config keys (perl, packs=a,b, skills=a,b,
                           no_detect=a,b, detect=false,
                           preferred_lib_target, engine) configure raider.
  -r, --root DIR           Working directory (default: cwd). File tools are
                           confined to this directory.
  -M, --mission TEXT       Instructions: replaces the default persona and
                           the instructions file (.raider/instructions.md,
                           else .raider.md); skills, packs and the tool
                           description still apply
      --bare               Isolated context: no instructions file, skills,
                           packs:, default packs or detection (--pack NAME
                           and /pack NAME still work)
  -i, --interactive        REPL mode (default when stdin is a TTY with no
                           prompt argv and no pipe; forces it otherwise)
      --json[=N]           Print one JSON document for the run and exit
                           (format version N; 1 is the only one)
      --msgpack[=N]        The same document as MessagePack
      --yaml[=N]           The same document as YAML
      --stream-json[=N]    Print the run as JSON Lines events as it happens,
                           ending with the document (run.finished)
      --stream-msgpack[=N] The same events as MessagePack objects
      --stream-yaml[=N]    The same events as YAML documents
      --no-session         Do not record the run(s) in a session journal
                           (default: a new one in .raider/sessions/)
      --session ID         Continue session ID: its conversation is replayed
                           and the run(s) recorded in it (one-shot or REPL)
      --continue           The same with the newest session of the project
      --max-iterations N   Hard safety cap on tool rounds per raid
                           (default: 10000 — effectively unlimited)
      --no-color           Disable ANSI colors
      --trace / --no-trace Show / hide live tool-call progress output
                           (default: shown when stdout is a terminal;
                           with a machine output flag --trace sends it
                           to stderr)
      --perl               Enable perl_eval / perl_check / perl_cpanm tools
      --pack NAME          Enable a bundled pack (repeatable)
      --no-pack NAME       Switch a pack off, also a detected or default
                           one (repeatable)
      --no-detect          Do not activate packs by workspace detection
                           (--detect forces it on over detect: false)
      --customize-prompt   Launch the prompt-builder at startup
      --claude             Load Claude Code layout: CLAUDE.md +
                           .claude/skills/*/SKILL.md.
      --openai / --codex   Load AGENTS.md (the OpenAI Codex / cross-tool
                           convention).
      --skills DIR         Load *.md files from DIR as skills (repeatable).
      --export-skill [PATH]
                           Write a plain-markdown "how to use raider" doc
                           (default: ./RAIDER-SKILL.md) and exit.
      --export-claude-skill [PATH]
                           Write a Claude Code SKILL.md with frontmatter
                           (default: .claude/skills/raider/SKILL.md)
                           and exit.
      --version            Show the versions of raider and Langertha
  -h, --help               Show this help

If no prompt is given and not interactive, reads the prompt from STDIN.
A session ID may be shortened to a unique start of it or to its last four
hex digits (3f2a).

Exit status: 0 success, 1 the run failed, 2 usage error,
3 configuration error, 4 the session is in use.
USAGE


sub version_line {
  my ( $self ) = @_;
  return 'raider '.Langertha::Raider->VERSION.' (Langertha '.Langertha->VERSION.")\n";
}


sub parse_options {
  my ( $self, @argv ) = @_;
  my %opt = ( packs => [], no_packs => [], skill_dirs => [] );
  my @raw_engine_opts;
  # --json=N and friends. Only the =N form carries a version: an optional
  # Getopt::Long value would also take the next word (raider --json 3 ...).
  my ( %machine_flag, %machine_version );
  for my $arg (@argv) {
    last if $arg eq '--';
    next unless $arg =~ /\A--([a-z-]+)=(.*)\z/s && $MACHINE_FLAG{$1};
    $machine_version{$1} = $2;
    $arg = '--'.$1;
  }
  my $parser = Getopt::Long::Parser->new(config => [qw( no_ignore_case bundling )]);
  my $ok = do {
    local $SIG{__WARN__} = sub { $self->_warn(@_) };
    $parser->getoptionsfromarray(\@argv,
      'e|engine=s'            => \$opt{engine},
      'provider=s'            => \$opt{provider},
      'allow-internal'        => \$opt{allow_internal},
      'm|model=s'             => \$opt{model},
      'r|root=s'              => \$opt{root},
      'M|mission=s'           => \$opt{mission},
      'bare'                  => \$opt{bare},
      'k|api-key=s'           => \$opt{api_key},
      'o|option=s@'           => \@raw_engine_opts,
      'i|interactive'         => \$opt{interactive},
      ( map { $_ => \$machine_flag{$_} } sort keys %MACHINE_FLAG ),
      'max-iterations=i'      => \$opt{max_iterations},
      'no-color'              => \$opt{no_color},
      'trace!'                => \$opt{trace},
      'perl'                  => \$opt{perl},
      'pack=s@'               => $opt{packs},
      'no-pack=s@'            => $opt{no_packs},
      'detect!'               => \$opt{detect},
      'customize-prompt'      => \$opt{customize_prompt},
      'claude'                => \$opt{profile_claude},
      'openai|codex'          => \$opt{profile_openai},
      'skills=s@'             => $opt{skill_dirs},
      'export-skill:s'        => \$opt{export_skill},
      'export-claude-skill:s' => \$opt{export_claude_skill},
      'no-session'            => \$opt{no_session},
      'session=s'             => \$opt{session},
      'continue'              => \$opt{continue},
      'version'               => \$opt{version},
      'h|help'                => \$opt{help},
    );
  };
  unless ($ok) {
    $self->_warn("Bad options. Try --help.\n");
    return;
  }

  if (defined $opt{session} && !$self->session_store_class->is_ref($opt{session})) {
    $self->_warn("--session: not a session id: '".$opt{session}."'\n");
    return;
  }
  my @session_flags = grep { $opt{ $_->[0] } } [ session => '--session' ], [ continue => '--continue' ],
    [ no_session => '--no-session' ];
  if (@session_flags > 1) {
    $self->_warn(join(', ', map { $_->[1] } @session_flags).": only one of them at a time\n");
    return;
  }

  my @machine = grep { $machine_flag{$_} } sort keys %MACHINE_FLAG;
  if (@machine > 1) {
    $self->_warn(join(', ', map { '--'.$_ } @machine).": only one machine output format at a time\n");
    return;
  }
  if (my ( $flag ) = @machine) {
    if ($opt{interactive}) {
      $self->_warn('--'.$flag.": no machine output in the REPL (-i)\n");
      return;
    }
    my $version = $machine_version{$flag} // 1;
    unless ($version =~ /\A\d+\z/ && grep { $_ == $version } $self->machine_class->versions) {
      $self->_warn("unknown --".$flag." version '".$version."' (known: "
        .join(', ', $self->machine_class->versions).")\n");
      return;
    }
    my ( $format, $stream ) = @{ $MACHINE_FLAG{$flag} };
    $opt{machine} = { format => $format, stream => $stream, version => 0 + $version };
  }

  my %engine_opts;
  for my $pair (@raw_engine_opts) {
    my ( $k, $v ) = split /=/, $pair, 2;
    unless (defined $k && defined $v) {
      $self->_warn("bad -o spec '".$pair."' (expected key=value)\n");
      return;
    }
    # Auto-coerce simple numerics so temperature=0.2 lands as a number.
    if    ($v =~ /\A-?\d+\z/)                    { $v = 0 + $v }
    elsif ($v =~ /\A-?\d*\.\d+(?:[eE]-?\d+)?\z/) { $v = 0 + $v }
    elsif ($v eq 'true')                         { $v = 1 }
    elsif ($v eq 'false')                        { $v = 0 }
    $engine_opts{$k} = $v;
  }
  $opt{engine_options} = \%engine_opts;
  return ( \%opt, @argv );
}


sub app_args {
  my ( $self, $opt ) = @_;
  my %args;
  for my $key (qw( engine model root mission api_key trace perl detect max_iterations bare )) {
    $args{$key} = $opt->{$key} if defined $opt->{$key};
  }
  $args{trace}          = 0                        if $opt->{machine} && !defined $opt->{trace};
  $args{trace_out}      = $self->err               if $opt->{machine};
  $args{pack_names}     = $opt->{packs}            if @{ $opt->{packs} // [] };
  $args{no_pack_names}  = $opt->{no_packs}         if @{ $opt->{no_packs} // [] };
  $args{engine_options} = $opt->{engine_options}   if %{ $opt->{engine_options} // {} };
  return %args;
}


sub run {
  my ( $self, @argv ) = @_;

  if (@argv && $argv[0] eq 'hall') {
    shift @argv;
    Langertha::Raider::Hall::CLI->main(@argv);
    return EXIT_OK;
  }
  if (@argv && $argv[0] eq 'acp') {
    shift @argv;
    Langertha::Raider::ACP::CLI->main(@argv);
    return EXIT_OK;
  }

  # raider provider inspect TARGET [options]. Only these two words make the
  # subcommand; "raider provider is down?" stays a prompt.
  if (@argv >= 2 && $argv[0] eq 'provider' && $argv[1] eq 'inspect') {
    splice @argv, 0, 2;
    return $self->provider_command(inspect => @argv);
  }

  # raider config explain [options]: prints where each setting comes from
  # and exits without writing the config file or building an engine.
  my $config_cmd;
  # raider config migrate [--dry-run] [options] writes files, so it is the
  # subcommand only in front of the options.
  if (@argv && $argv[0] eq 'config') {
    shift @argv;
    $config_cmd = shift(@argv) // '';
    return $self->migrate_command(@argv) if $config_cmd eq 'migrate';
    unless ($config_cmd eq 'explain') {
      $self->_warn("Usage: raider config explain [options] | raider config migrate [--dry-run] [options]\n");
      return EXIT_USAGE;
    }
  }

  # raider session list | show ID | resume ID | fork ID | rm ID [options].
  # Only these words make the subcommand; any other prompt starting with
  # "session" (raider session is lost?) stays a prompt.
  my ( $session_cmd, $session_id );
  if (!$config_cmd && @argv >= 2 && $argv[0] eq 'session' && $argv[1] =~ /\A(?:list|show|resume|fork|rm)\z/) {
    ( undef, $session_cmd ) = splice @argv, 0, 2;
  }

  my ( $opt, @prompt ) = $self->parse_options(@argv) or return EXIT_USAGE;

  # Behind options (raider -e openai config explain) only the exact words
  # "config explain" are the subcommand; any other prompt starting with
  # "config" stays a prompt. The same for "session list" and "session
  # show|resume|fork|rm ID" with a word shaped like a session id.
  if (!$config_cmd && @prompt == 2 && $prompt[0] eq 'config' && $prompt[1] eq 'explain') {
    $config_cmd = 'explain';
    @prompt = ();
  }
  if (!$config_cmd && !$session_cmd && @prompt >= 2 && $prompt[0] eq 'session'
      && ( (@prompt == 2 && $prompt[1] eq 'list')
        || (@prompt == 3 && $prompt[1] =~ /\A(?:show|resume|fork|rm)\z/ && $self->session_store_class->is_ref($prompt[2])) )) {
    ( undef, $session_cmd ) = splice @prompt, 0, 2;
  }
  if ($session_cmd) {
    my $wants_id = $session_cmd ne 'list';
    $session_id = shift @prompt if $wants_id;
    if (@prompt || ($wants_id && !$self->session_store_class->is_ref($session_id))) {
      $self->_warn("Usage: raider session list | show ID | resume ID | fork ID | rm ID [options]\n");
      return EXIT_USAGE;
    }
  }

  $ENV{ANSI_COLORS_DISABLED} = 1 if $opt->{no_color} || $opt->{machine};

  if ($opt->{help}) {
    $self->output->emit($self->usage);
    return EXIT_OK;
  }
  if ($opt->{version}) {
    $self->output->emit($self->version_line);
    return EXIT_OK;
  }

  if ($session_cmd && $session_cmd ne 'resume') {
    return $self->session_command($session_cmd, $session_id, $opt);
  }
  if (my $problem = $self->provider_usage_error($opt, $config_cmd)) {
    $self->_warn($problem."\n");
    return EXIT_USAGE;
  }
  if ($session_cmd) {
    # resume ID is the REPL on that session.
    for my $flag (grep { $opt->{$_->[0]} } [ machine => 'a machine output format' ],
        [ session => '--session' ], [ continue => '--continue' ], [ no_session => '--no-session' ]) {
      $self->_warn('raider session resume: not with '.$flag->[1]."\n");
      return EXIT_USAGE;
    }
    $opt->{session} = $session_id;
    $opt->{interactive} = 1;
  }

  my %args = $self->app_args($opt);
  my $machine = $opt->{machine}
    ? $self->machine_class->new(%{ $opt->{machine} }, out => $self->output->out)
    : undef;
  # The runner, made once the app exists, reports a session journal that
  # cannot be written.
  my $runner;
  $args{on_journal_error} = sub { $runner->journal_error(@_) if $runner };

  # A machine consumer gets its interrupted document also for a signal
  # during startup (configuration, reading the prompt); the runner takes
  # the signals over once the run starts.
  my $t0 = Time::HiRes::time();
  local $SIG{INT}  = $machine ? sub { $self->interrupt_startup(INT  => $machine, $t0) } : $SIG{INT};
  local $SIG{TERM} = $machine ? sub { $self->interrupt_startup(TERM => $machine, $t0) } : $SIG{TERM};

  # The one reader/writer of the project config (.raider/config.yml, else
  # .raider.yml) and of the home config under it (~/.raider/config.yml).
  # Both parsed up front so a broken file stops raider here, with its path
  # in the message, and so does an invalid project_tools of the home file.
  # A legacy file next to the new one is not loaded, and said so (ADR 0011).
  my $config = $self->config_class->new(root => $opt->{root} // Path::Tiny->cwd->stringify);
  unless (eval { $config->data; $config->home_data; $config->project_tools; 1 }) {
    $self->_warn($self->output->error_text($@)."\n");
    return EXIT_CONFIG;
  }
  $self->_warn('warning: ignoring '.$_->{file}.': '.$_->{reason}."\n") for $config->ignored_files;
  $args{config} = $config;

  # --provider: the manifest decides engine, model and URL before anything
  # is built or saved.
  if (defined $opt->{provider}) {
    my $cli_opts = $opt->{engine_options};
    my ( $exit, $activation ) = $self->provider_class->new(output => $self->output, err => $self->err)->activate(
      $opt->{provider},
      allow_internal => $opt->{allow_internal},
      model          => $opt->{model} // $cli_opts->{model},
      has_api_key    => length($opt->{api_key} // $cli_opts->{api_key} // '') ? 1 : 0,
    );
    return $exit if defined $exit;
    $args{provider} = $activation;
  }

  my ( @skill_specs, @cli_profiles );
  if ($opt->{profile_claude}) {
    push @skill_specs, @{ $Langertha::Raider::CLI::AGENT_PROFILES{claude} };
    push @cli_profiles, 'claude';
  }
  if ($opt->{profile_openai}) {
    push @skill_specs, @{ $Langertha::Raider::CLI::AGENT_PROFILES{openai} };
    push @cli_profiles, 'openai';
  }
  my @persist_skills = @cli_profiles;
  for my $dir (@{ $opt->{skill_dirs} }) {
    my $spec = { type => 'dir', path => $dir };
    push @skill_specs, $spec;
    # A directory named like a profile keyword is saved as a spec, so it is
    # not read back as that profile.
    push @persist_skills, ($dir =~ /\A(?:claude|openai|codex|agents)\z/ ? $spec : $dir);
  }
  $args{cli_skill_sources} = \@skill_specs if @skill_specs;

  # Persist --claude / --openai / --skills to the config file so the user doesn't
  # need to retype them every invocation. Track which profiles were freshly
  # persisted this run for the banner "(saved)" hint.
  my %saved_now = $config_cmd ? ()
    : map { $_ => 1 } grep { !ref } $config->add_skills(@persist_skills);

  # Unknown engine or an invalid detection rule: stop before anything runs.
  my $app = $self->app_class->new(%args);
  unless (eval { $app->_engine_class; $app->packs; 1 }) {
    $self->_warn($self->output->error_text($@)."\n");
    return EXIT_CONFIG;
  }
  # A legacy .raider.md next to .raider/instructions.md is not used, and
  # said so (ADR 0011), like the config file above.
  $self->_warn('warning: ignoring '.$_->{file}.': '.$_->{reason}."\n") for $app->instructions->ignored_files;

  if ($config_cmd) {
    $self->output->config_report($app->explain_config);
    return EXIT_OK;
  }

  # One-shot skill export paths. Empty string means "use default path".
  if (defined $opt->{export_skill}) {
    my $path = length $opt->{export_skill}
      ? $opt->{export_skill}
      : path($app->root)->child('RAIDER-SKILL.md')->stringify;
    my $p = $self->skill_class->new(app => $app)->write_markdown($path);
    $self->_warn('wrote '.$p."\n");
    return EXIT_OK;
  }
  if (defined $opt->{export_claude_skill}) {
    my $skill = $self->skill_class->new(app => $app);
    my $p = $skill->write_claude_skill(length $opt->{export_claude_skill} ? $opt->{export_claude_skill} : undef);
    $self->_warn('wrote '.$p."\n");
    if (my $old = $skill->legacy_claude_skill) {
      $self->_warn('note: '.$old." is left over from an older raider, remove it\n");
    }
    return EXIT_OK;
  }

  # Default to interactive REPL when stdin is a terminal and no prompt was
  # given on argv / piped in / requested as one-shot machine output.
  my $in = $self->in;
  my $interactive = $opt->{interactive} || (!$opt->{machine} && !@prompt && -t $in);
  $runner = $self->runner_class->new(app => $app, output => $self->output, err => $self->err);
  my $store = $opt->{no_session} ? undef : $app->session_store;

  # --session ID, --continue, session resume ID: the session is locked
  # and replayed before anything runs.
  my ( $session, @notes );
  if (defined $opt->{session} || $opt->{continue}) {
    ( my $exit, $session, @notes ) = $self->resume_session($app, $opt->{session});
    return $exit if defined $exit;
  }

  if ($interactive) {
    my %seen;
    $self->repl_class->new(
      app              => $app,
      output           => $self->output,
      in               => $in,
      runner           => $runner,
      $store ? ( session_store => $store ) : (),
      active_profiles  => [ grep { !$seen{$_}++ } @cli_profiles, $config->profiles($app->engine_name) ],
      saved_profiles   => \%saved_now,
      customize_prompt => $opt->{customize_prompt} ? 1 : 0,
      $session ? ( session => $session ) : (),
      notes            => \@notes,
    )->run(@prompt);
    return EXIT_OK;
  }

  my $text;
  if (@prompt) {
    $text = join ' ', @prompt;
  }
  elsif (-t $in) {
    # Interactive terminal but no -i and no argv: ask once.
    $text = prompt($self->output->c(prompt => 'raider>'));
  }
  else {
    local $/;
    $text = <$in>;
  }
  unless (defined $text && length $text) {
    $self->_warn("No prompt given.\n");
    return EXIT_USAGE;
  }
  if ($session) {
    $self->_warn($_."\n") for @notes;
  }
  elsif ($store) {
    $session = $self->new_session($app, $machine);
  }
  return $runner->run_prompt($text, machine => $machine, session => $session, catch_signals => 1)
    ? EXIT_OK : EXIT_RUN_ERROR;
}


sub resume_session {
  my ( $self, $app, $ref ) = @_;
  my $store = $app->session_store;
  my $id = defined $ref ? $self->resolve_session($store, $ref) : $store->latest;
  unless (defined $id) {
    $self->_warn('no session to continue in '.$store->dir."\n") unless defined $ref;
    return EXIT_USAGE;
  }
  my $session = eval { $app->open_session($id) };
  unless ($session) {
    my $error = $self->output->error_text($@);
    $self->_warn($error.($error =~ / is in use\z/ ? ' by another raider' : '')."\n");
    return $error =~ / is in use\z/ ? EXIT_SESSION_IN_USE : EXIT_RUN_ERROR;
  }
  my @notes = eval {
    $self->sessions_class->new(app => $app, output => $self->output)->restore($session);
  };
  if ($@) {
    my $error = $self->output->error_text($@);
    $self->_warn('cannot resume session '.$id.': '.$error."\n");
    return EXIT_RUN_ERROR;
  }
  return ( undef, $session, @notes );
}


sub session_command {
  my ( $self, $cmd, $id, $opt ) = @_;
  my $machine;
  if (my $m = $opt->{machine}) {
    if ($m->{stream}) {
      $self->_warn('raider session '.$cmd.": no --stream-* output, only a document\n");
      return EXIT_USAGE;
    }
    $machine = $self->machine_class->new(%$m, out => $self->output->out);
  }
  # The app of the project; building it reads no .raider.yml and builds no
  # engine.
  my $app = $self->app_class->new(root => $opt->{root} // Path::Tiny->cwd->stringify);
  my $store = $app->session_store;
  my $sessions = $self->sessions_class->new(app => $app, output => $self->output);
  if ($cmd eq 'list') {
    $sessions->list($machine);
    return EXIT_OK;
  }
  $id = $self->resolve_session($store, $id) // return EXIT_USAGE;
  if ($cmd eq 'show') {
    $sessions->show($id, $machine);
    return EXIT_OK;
  }
  my $method = $cmd eq 'fork' ? 'fork_session' : 'remove';
  return EXIT_OK if eval { $sessions->$method($id, $machine); 1 };
  my $error = $self->output->error_text($@);
  my $in_use = $error =~ / is in use\z/;
  $self->_warn($error.($in_use ? ' by another raider' : '')."\n");
  return $in_use ? EXIT_SESSION_IN_USE : EXIT_RUN_ERROR;
}


sub migrate_usage { <<'USAGE' }
Usage: raider config migrate [--dry-run] [options]

Moves the legacy project files of the working directory (-r DIR) to the
.raider/ layout: .raider.yml to .raider/config.yml and .raider.md to
.raider/instructions.md, each only when it exists. Shows what it does
first. Each new file is written atomically; the legacy file is renamed to
.raider.yml.bak / .raider.md.bak, so afterwards the same settings are read
from the new files. .raider/ is created with its .gitignore (sessions/,
lib/).

api_key (top level, default: or an engine section) is not copied into
.raider/config.yml, which is meant to be shared: it is reported; move it
to ~/.raider/config.yml or the engine's *_API_KEY environment variable.

Nothing is merged: when .raider/config.yml or .raider/instructions.md (or
a backup) already exists, nothing is written.

Options:
      --dry-run            Show what would happen, write nothing
  -r, --root DIR           The project (default: cwd)
      --no-color           Disable ANSI colors
  -h, --help               Show this help

The report is for humans only; there is no --json form.

Exit status: 0 migrated, nothing to migrate or a dry run, 1 refused or
failed, 2 usage error, 3 .raider.yml cannot be read.
USAGE


sub migrate_command {
  my ( $self, @argv ) = @_;
  # --dry-run belongs to this subcommand only, so it is taken out before
  # the common options are parsed.
  my $dry_run = 0;
  my @rest;
  while (@argv) {
    my $arg = shift @argv;
    if ($arg eq '--') { push @rest, $arg, @argv; last }
    if ($arg eq '--dry-run') { $dry_run = 1; next }
    push @rest, $arg;
  }
  my ( $opt, @words ) = $self->parse_options(@rest) or return EXIT_USAGE;
  if ($opt->{help}) {
    $self->output->emit($self->migrate_usage);
    return EXIT_OK;
  }
  if (@words) {
    $self->_warn("Usage: raider config migrate [--dry-run] [options]\n");
    return EXIT_USAGE;
  }
  if ($opt->{machine}) {
    $self->_warn("raider config migrate: no machine output, the report is for humans only\n");
    return EXIT_USAGE;
  }
  $ENV{ANSI_COLORS_DISABLED} = 1 if $opt->{no_color};

  my $migrate = $self->migrate_class->new(root => $opt->{root} // Path::Tiny->cwd->stringify);
  my $plan = eval { $migrate->plan };
  unless ($plan) {
    $self->_warn($self->output->error_text($@)."\n");
    return EXIT_CONFIG;
  }
  if (my @refused = @{ $plan->{refused} }) {
    $self->_warn('raider config migrate: '.$_."\n") for @refused;
    $self->_warn("raider config migrate: nothing written\n");
    return EXIT_RUN_ERROR;
  }
  $self->output->migrate_report($plan, dry_run => $dry_run);
  return EXIT_OK if $dry_run || !@{ $plan->{steps} };

  my @results = $migrate->apply($plan);
  $self->output->migrate_done(@results);
  my $failed = 0;
  for my $r (@results) {
    my $s = $r->{step};
    if ($r->{error}) {
      $failed = 1;
      $self->_warn('raider config migrate: '.$s->{from_label}.' not migrated, it stays in use: '
        .$self->output->error_text($r->{error})."\n");
    }
    elsif ($r->{skipped}) {
      $self->_warn('raider config migrate: '.$s->{from_label}." not migrated, stopped after the error above\n");
    }
  }
  return $failed ? EXIT_RUN_ERROR : EXIT_OK;
}


sub provider_usage { <<'USAGE' }
Usage: raider provider inspect HOST[:PORT] | https://HOST[:PORT] [options]

Fetches https://HOST[:PORT]/.well-known/langertha.json, validates it as a
provider manifest and shows provider id, issuer, endpoints, auth and
models. Nothing is stored and no credential is sent or bound.

Options:
      --allow-internal     Allow a loopback, private, link-local or reserved
                           target address, for a deliberately released
                           internal knarr or skeid (cloud metadata,
                           multicast and unspecified addresses stay refused)
      --json[=N]           Print one JSON document (also --msgpack, --yaml)
      --no-color           Disable ANSI colors
  -h, --help               Show this help

Limits: https only, 1 MiB, 10 seconds, 3 redirects within the origin; a
redirect to another origin is not followed.

Exit status: 0 a valid manifest, 1 refused, not fetched or not valid,
2 usage error.
USAGE


sub provider_command {
  my ( $self, $cmd, @argv ) = @_;
  # --allow-internal belongs to this subcommand only, so it is taken out
  # before the common options are parsed.
  my $allow_internal = 0;
  my @rest;
  while (@argv) {
    my $arg = shift @argv;
    if ($arg eq '--') { push @rest, $arg, @argv; last }
    if ($arg eq '--allow-internal') { $allow_internal = 1; next }
    push @rest, $arg;
  }
  my ( $opt, @words ) = $self->parse_options(@rest) or return EXIT_USAGE;
  if ($opt->{help}) {
    $self->output->emit($self->provider_usage);
    return EXIT_OK;
  }
  if (@words != 1) {
    $self->_warn("Usage: raider provider inspect HOST[:PORT] | https://HOST[:PORT] [--json] [--allow-internal]\n");
    return EXIT_USAGE;
  }
  $ENV{ANSI_COLORS_DISABLED} = 1 if $opt->{no_color} || $opt->{machine};
  my $machine;
  if (my $m = $opt->{machine}) {
    if ($m->{stream}) {
      $self->_warn('raider provider '.$cmd.": no --stream-* output, only a document\n");
      return EXIT_USAGE;
    }
    $machine = $self->machine_class->new(%$m, out => $self->output->out);
  }
  return $self->provider_class->new(output => $self->output, err => $self->err)
    ->inspect($words[0], allow_internal => $allow_internal, machine => $machine);
}


sub provider_usage_error {
  my ( $self, $opt, $config_cmd ) = @_;
  unless (defined $opt->{provider}) {
    return $opt->{allow_internal} ? '--allow-internal: only with --provider' : undef;
  }
  my $cli_opts = $opt->{engine_options} // {};
  my @conflicts = (
    ( defined $opt->{engine}     ? '-e/--engine' : () ),
    ( exists $cli_opts->{engine} ? '-o engine='  : () ),
    ( exists $cli_opts->{url}    ? '-o url='     : () ),
  );
  return '--provider: not with '.join(', ', @conflicts).'; the provider manifest decides the engine and its URL'
    if @conflicts;
  return '--provider: not with config explain' if $config_cmd;
  return;
}


sub resolve_session {
  my ( $self, $store, $ref ) = @_;
  my $id = eval { $store->resolve($ref) };
  $self->_warn($self->output->error_text($@)."\n") unless defined $id;
  return $id;
}


sub new_session {
  my ( $self, $app, $machine ) = @_;
  my $session = eval { $app->create_session };
  unless ($session) {
    my $error = $self->output->error_text($@);
    $self->_warn('session not saved: '.$error."\n");
    return;
  }
  $self->_warn('session '.$session->id.' ('.$session->path.")\n") unless $machine;
  return $session;
}


sub interrupt_startup {
  my ( $self, $signal, $machine, $t0 ) = @_;
  my $runner = $self->runner_class;
  return $runner->interrupt($signal => $machine, $runner->elapsed_since($t0));
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CLI::Main - Internal command-line entry point behind bin/raider

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    exit Langertha::Raider::CLI::Main->new->run(@ARGV);

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Everything F<raider> does with its command line: the C<hall>, C<acp>,
C<config explain>, C<config migrate>, C<session> and C<provider inspect> subcommands, option parsing, the skill exports, and
then either the REPL (L<Langertha::Raider::CLI::REPL>) or one prompt
(L<Langertha::Raider::CLI::Runner>). L</run> returns the exit status.

=head2 Exit status

=over

=item C<0> -- success, including C<--help>, C<--version>, the exports, C<config explain>,
C<config migrate> (also with nothing to migrate, and C<--dry-run>), C<session list>, C<session show>, C<session fork>, C<session rm>,
C<provider inspect> of a valid manifest and leaving the REPL.

=item C<1> -- the run failed: the engine, a tool or the network raised an
error (with a machine format, the output is the C<failed> document); for
C<config migrate>: the migration was refused (a new file or a backup
already exists, F<.raider> is no directory, the home directory) or a step
failed; for C<provider inspect>: the manifest was refused (address, redirect), could
not be fetched or is not valid; for C<--provider> also: its endpoint is
not usable (another origin, not https, a refused address, a dialect or
auth type this raider has no adapter for, no models, a model on several
endpoints).

=item C<2> -- usage error: unknown option, a C<-o> that is not
C<KEY=VALUE>, an unknown C<config> subcommand, no prompt, more than one
machine format, a machine format with C<-i>, or an unknown machine format
version; for C<config migrate>: a word after it or a machine format;
for sessions: a C<--session> value that is no session id,
more than one of C<--session>, C<--continue> and C<--no-session>, an unknown
or ambiguous session, or C<--continue> without any session; for
C<provider inspect>: no target or more than one, a target that is no
host or https origin, or a C<--stream-*> flag; for C<--provider>: a
target that is none, C<-e>, C<-o engine=>, C<-o url=> or C<config explain>
with it, a model the manifest does not list, no C<-m> where it lists
several models, or no C<-k> where the endpoint needs a key;
C<--allow-internal> without C<--provider>.

=item C<3> -- configuration error: the config file (F<.raider/config.yml>,
else F<.raider.yml>; for C<config migrate> the F<.raider.yml> to migrate)
cannot be read, the
engine is unknown, or a pack detection rule is invalid.

=item C<4> -- the session to continue (C<--session>, C<--continue>,
C<session resume>) or to remove (C<session rm>) is in use: another raider
has it open for writing and holds its lock. Unlike a usage error the same
command can work later, which is why it has a status of its own.

=item C<130>, C<143> -- a one-shot run was cancelled by C<SIGINT> or
interrupted by C<SIGTERM> (see L<Langertha::Raider::CLI::Runner/run_prompt>).
It writes the C<cancelled> or C<interrupted> document (or a note), then
dies of that same signal, which a shell reports as 128 plus the signal
number; see L<Langertha::Raider::CLI::Runner/die_of_signal>.

=back

The C<hall> and C<acp> subcommands keep their own exit statuses. The REPL's
two-strike Ctrl-C leaves with C<0>.

=head2 output

The L<Langertha::Raider::CLI::Output> for everything but diagnostics.
Defaults to one on C<STDOUT>.

=head2 err

Filehandle for diagnostics. Defaults to C<STDERR>.

=head2 in

Filehandle a prompt or the REPL input is read from. Defaults to C<STDIN>.

=head2 usage

The C<--help> text.

=head2 version_line

The C<--version> line: F<raider>'s version (that of L<Langertha::Raider>),
then that of L<Langertha> core.

    raider 0.503 (Langertha 0.503)   # for example

=head2 parse_options

    my ( $opt, @prompt ) = $main->parse_options(@argv);

Parses the options; returns the option hash (with C<-o> pairs in
C<engine_options>, and a machine format in C<machine> as C<format>,
C<stream> and C<version>) and the remaining words, or nothing after reporting a
usage error.

=head2 app_args

    my %args = $main->app_args($opt);

Constructor arguments for L<Langertha::Raider::CLI> from the parsed
options, without C<config> and the skill sources. With a machine format
the live trace is off unless C<--trace> asks for it, and then goes to
L</err>, so stdout carries only the machine output.

=head2 run

    my $exit = $main->run(@argv);

Does what the command line says and returns the exit status.

=head2 resume_session

    my ( $exit, $session, @notes ) = $main->resume_session($app, $ref);

Opens the session C<$ref> names (L</resolve_session>; the newest one of
the project when C<undef>, for C<--continue>) for writing through
L<Langertha::Raider::Application/open_session> and replays it into the
app's raider through L<Langertha::Raider::CLI::Sessions/restore>. Returns C<undef>, the
L<Langertha::Raider::Session> and the notes of the resume -- or, after
reporting why, just the exit status: C<2> when there is no such session
or C<$ref> is ambiguous, C<4> when another raider has it open, C<1> when
it cannot be opened or replayed otherwise.

=head2 session_command

    my $exit = $main->session_command(list => undef, $opt);
    my $exit = $main->session_command(show => $id, $opt);

C<raider session list>, C<show ID>, C<fork ID> and C<rm ID> for the
project in C<-r> (or the working directory), through the
L<Langertha::Raider::Application> of that project and
L<Langertha::Raider::CLI::Sessions>; a document format (C<--json>,
C<--msgpack>, C<--yaml>) writes them as one document. C<rm> of a session
another raider has open ends with C<4>, as a resume of it would; a fork or
removal that fails otherwise with C<1>.

=head2 migrate_usage

The C<raider config migrate --help> text.

=head2 migrate_command

    my $exit = $main->migrate_command(@argv);

C<raider config migrate [--dry-run] [options]> through
L<Langertha::Raider::Config::Migrate>: the report
(L<Langertha::Raider::CLI::Output/migrate_report>) on L</output>, then,
without C<--dry-run>, the migration. A refusal or a failed step is
reported on L</err>. Takes C<--dry-run>, C<-r>, C<--no-color> and
C<--help>; the other options of F<raider> are accepted and have no effect,
as for the session commands. A word after it or a machine format is a
usage error: the report is for humans only.

=head2 provider_usage

The C<raider provider inspect --help> text.

=head2 provider_command

    my $exit = $main->provider_command(inspect => @argv);

C<raider provider inspect TARGET [options]> through
L<Langertha::Raider::CLI::Provider>. Takes C<--allow-internal>, a document
format (C<--json>, C<--msgpack>, C<--yaml>; no stream), C<--no-color> and
C<--help>; the other options of F<raider> are accepted and have no effect,
as for the session commands. Exactly one target is a must.

=head2 provider_usage_error

    my $problem = $main->provider_usage_error($opt, $config_cmd);

Why C<--provider> or C<--allow-internal> cannot go with the rest of the
command line, or C<undef>. C<--provider> decides the engine and its URL,
so it excludes C<-e>, C<-o engine=> and C<-o url=>, and it does not go with
C<config explain>; C<--allow-internal> only goes with C<--provider>.

=head2 resolve_session

    my $id = $main->resolve_session($store, '3f2a');

The whole id of the session a command-line reference names -- the id, a
unique start of it or its four hex digits
(L<Langertha::Raider::SessionStore/resolve>). An unknown or ambiguous
reference is reported on L</err> and gives C<undef>.

=head2 new_session

    my $session = $main->new_session($app, $machine);

Starts the session a one-shot run is recorded in
(L<Langertha::Raider::Application/create_session>) and names it on L</err>
(with a machine format the document names it instead). A session that
cannot be written is reported and the run goes on without one.

=head2 interrupt_startup

    $main->interrupt_startup(TERM => $machine, $t0);

Ends raider on a C<SIGINT> or C<SIGTERM> that arrives with a machine
format before the run starts: the C<interrupted> document (or its
C<run.finished>), then death by the signal, as for an interrupted run
(L<Langertha::Raider::CLI::Runner/interrupt>).

=head1 SEE ALSO

=over

=item * L<raider>

=item * L<Langertha::Raider::CLI>

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
