package Langertha::Raider::Application;
# ABSTRACT: Internal application service that builds and runs a raider for a workspace
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use IO::Async::Loop;
use Future::AsyncAwait;
use Net::Async::MCP;
use MCP::Run::Bash;
use Path::Tiny;
use Scalar::Util qw( blessed refaddr weaken );
use Time::HiRes ();
use Langertha::Raider::HallTools qw( build_hall_tools_server );

use Langertha::Raider::FileTools qw( build_file_tools_server );
use Langertha::Raider::WebTools  qw( build_web_tools_server );
use Langertha::Raider::PerlTools qw( build_perl_tools_server );
use Langertha::Raider::Packs     qw( build_packs );
use Langertha::Raider::Config;
use Langertha::Raider::Instructions;
use Langertha::Raider::Detect;
use Langertha::Raider::EngineResolver;
use Langertha::Raider::ToolEffects;
use Langertha::Raider::SessionStore;
use Langertha::Raider;



has engine_name => (
  is       => 'ro',
  isa      => 'Str',
  lazy     => 1,
  builder  => '_build_engine_name',
  init_arg => 'engine',
);

sub _build_engine_name { $_[0]->engine_resolver->engine_name }


has engine_resolver => (
  is       => 'ro',
  isa      => 'Langertha::Raider::EngineResolver',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_engine_resolver',
);

sub engine_resolver_class { 'Langertha::Raider::EngineResolver' }

# The resolver gets what was passed to the constructor (-e, -m, -k), so
# its answers and those of the attributes here are the same.
sub _build_engine_resolver {
  my ($self) = @_;
  my $explicit = $self->_explicit;
  return $self->engine_resolver_class->new(
    config         => $self->config,
    engine_options => $self->engine_options,
    ( $explicit->{engine}  ? ( engine  => $self->engine_name ) : () ),
    ( $explicit->{model}   ? ( model   => $self->model )       : () ),
    ( $explicit->{api_key} ? ( api_key => $self->api_key )     : () ),
    ( $self->has_provider  ? ( provider => $self->provider )   : () ),
  );
}


has provider => (
  is        => 'ro',
  isa       => 'HashRef',
  predicate => 'has_provider',
);


has model => (
  is        => 'ro',
  isa       => 'Str',
  lazy      => 1,
  predicate => 'has_explicit_model',
  builder   => '_build_model',
);

sub _build_model { $_[0]->engine_resolver->model }

sub has_model {
  my ($self) = @_;
  return 1 if $self->has_explicit_model;
  return length($self->model) ? 1 : 0;
}


sub api_key_env { $_[0]->engine_resolver->api_key_env }


has api_key => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_api_key',
);


has mission => (
  is       => 'ro',
  isa      => 'Str',
  lazy     => 1,
  init_arg => undef,
  builder  => '_build_mission',
);

has _explicit_mission => (
  is        => 'ro',
  isa       => 'Str',
  init_arg  => 'mission',
  predicate => '_has_explicit_mission',
);


has bare => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

sub _build_mission {
  my ($self) = @_;
  my @items = ( $self->_instructions_text, $self->_tools_text );

  my @skills = $self->_load_skill_texts;
  push @items, "Loaded skills (domain knowledge the user enabled for this session):\n\n"
    .join("\n\n", @skills)."\n" if @skills;

  my @pack_texts = $self->packs->skill_texts;
  push @items, "Active packs:\n\n".join("\n\n", @pack_texts)."\n" if @pack_texts;

  return join "\n\n---\n", @items;
}

# The instructions item: the -M text, or the default persona with the
# project instructions file (.raider/instructions.md, else .raider.md).
sub _instructions_text {
  my ($self) = @_;
  return $self->_explicit_mission if $self->_has_explicit_mission;
  my $base = $self->_persona_text;
  return $base if $self->bare;
  my $instructions = $self->instructions;
  my $custom = $instructions->text;
  $base .= "\n\n---\nUser's custom instructions (from ".$instructions->file."):\n\n$custom\n"
    if defined $custom;
  return $base;
}

# The tool description item, derived from the tool servers mounted for
# this raider (ADR 0005) -- the same servers the catalogue comes from; -M
# never replaces it (ADR 0014).
sub _tools_text {
  my ($self) = @_;
  my @tools = $self->_mounted_tools;
  return 'Working directory: '.$self->root."\n\n"
    ."Tools (MCP):\n"
    .join('', map { '  - '.$self->_tool_signature($_)."\n" } @tools);
}

# The MCP::Tool objects of the mounted tool servers, in mount order --
# what the prompt describes, the engine offers and Langertha::Raider::Skill
# documents.
sub _mounted_tools { map { @{ $_->tools } } @{ $_[0]->_tool_servers } }

# name(required, ..., [optional], ...) from the tool's input schema: the
# required parameters in their schema order, then the optional ones sorted.
sub _tool_signature {
  my ($self, $tool) = @_;
  my $schema   = $tool->input_schema // {};
  my @required = @{ $schema->{required} // [] };
  my %required = map { $_ => 1 } @required;
  my @optional = sort grep { !$required{$_} } keys %{ $schema->{properties} // {} };
  return $tool->name.'('.join(', ', @required, map { '['.$_.']' } @optional).')';
}

# The default persona: what the agent is (persona_intro), how it works,
# and how a turn ends (persona_turn_end). The first and the last part
# depend on the surface the agent is reached through.
sub _persona_text {
  my ($self) = @_;
  return $self->persona_intro."\n".$self->_persona_body.$self->persona_turn_end;
}


sub persona_intro { <<'EOM' }
You are Langertha, viking shield-maiden. Autonomous agent on user's
machine. No pause, no abort, no ask to stop. You do things.
EOM

sub persona_turn_end { <<'EOM' }
You have no yield / ask / abort tool. Task done: plain text reply. User
answers in the next turn.
EOM

# Points at the instructions file in use (.raider.md in a legacy project).
sub _persona_body {
  my ($self) = @_;
  my $label = $self->instructions->label;
  return <<"EOM";
Name, persona, tone are defaults. User can rename you, rewrite your
background, or change persona entirely via C<$label> in working dir.
If present, its content appended below as user's custom instructions.
User's custom instructions override this default where they conflict.

How you work:
  - User turn = task. Pursue with tools until done. Unlimited iterations.
  - Read before write. No guessing file contents.
  - After write_file / edit_file: verify. Re-read, or run check (perl -c,
    tests, etc.).
  - Small targeted edits > full rewrites.
  - bash is full shell, not sandbox. Use freely.
  - Skip irreversible ops (rm -rf, git reset --hard, force pushes) unless
    user explicit ask.

EOM
}


has root => (
  is      => 'ro',
  isa     => 'Str',
  default => sub { Path::Tiny->cwd->stringify },
);


has allowed_commands => (
  is        => 'ro',
  isa       => 'ArrayRef[Str]',
  predicate => 'has_allowed_commands',
);


has max_iterations => (
  is      => 'ro',
  isa     => 'Int',
  default => 10_000,
);


has on_event => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_on_event',
);


has on_journal_error => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_on_journal_error',
);


has perl => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


sub perl_tools_enabled { $_[0]->perl_tools_grant->{enabled} }


sub perl_tools_grant {
  my ($self) = @_;
  return { enabled => 1, reason => $self->source_label('perl') } if $self->perl;
  my $yml = $self->_load_yml_options->{perl};
  if (defined $yml) {
    my $where = exists $self->_cli_app_options->{perl} ? $self->source_label('engine_options')
      : $self->config->value_label($self->engine_name, 'perl');
    return { enabled => $yml ? 1 : 0, reason => 'perl: '.( $yml ? 'true' : 'false' ).' ('.$where.')' };
  }
  my $packs = $self->packs;
  my @by = map { 'pack '.$_.' ('.$packs->sources->{$_}{source}.')' }
    grep { grep { $_ eq 'perl' } @{ $packs->packs_by_name->{$_}->tools } }
    @{ $packs->enabled_pack_names };
  return @by ? { enabled => 1, reason => join(', ', @by) } : { enabled => 0, reason => 'not requested' };
}


has preferred_lib_target => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_preferred_lib_target',
);


has pack_names => (
  is        => 'ro',
  isa       => 'ArrayRef[Str]',
  predicate => 'has_pack_names',
);


has no_pack_names => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
);


has detect => (
  is        => 'ro',
  isa       => 'Bool',
  predicate => 'has_detect_flag',
);


has packs => (
  is      => 'ro',
  isa     => 'Langertha::Raider::Packs::Collection',
  lazy    => 1,
  builder => '_build_packs',
);

sub detect_class { 'Langertha::Raider::Detect' }

sub _build_packs {
  my ($self) = @_;
  # --bare: only --pack counts, not packs:, defaults or detection.
  my ( $list, $source, $reason ) = !$self->bare ? $self->_explicit_packs
    : $self->has_pack_names ? ( $self->pack_names, flag => $self->source_label('pack_names') )
    :                         ( [] );

  my $collection = build_packs(root => $self->root);

  if ($list && ref $list eq 'ARRAY' && ( @$list || $self->bare )) {
    # Explicit packs — enable exactly those
    for my $name (@{$collection->all_pack_names}) {
      $collection->disable($name);
    }
    for my $name (@$list) {
      $collection->enable($name, $source, $reason);
    }
  }
  $collection->disable($_, flag => $self->source_label('no_pack_names')) for @{$self->no_pack_names};
  $self->_detect_packs($collection);

  return $collection;
}

# The explicit pack list with its source: --pack, then -o packs=, then
# packs: in .raider.yml.
sub _explicit_packs {
  my ($self) = @_;
  return ( $self->pack_names, flag => $self->source_label('pack_names') ) if $self->has_pack_names;
  my $opt = $self->_cli_app_options->{packs};
  return ( $opt, flag => $self->source_label('engine_options packs') ) if defined $opt;
  my $engine = $self->engine_name;
  return ( $self->config->options($engine)->{packs}, config => $self->config->value_label($engine, 'packs').' packs:' );
}


sub detection_state {
  my ($self) = @_;
  return ( 0, $self->source_label('bare') ) if $self->bare;
  return ( $self->detect ? ( 1, $self->source_label('detect') ) : ( 0, $self->source_label('no_detect') ) ) if $self->has_detect_flag;
  return ( 0, 'detect: false' ) unless $self->_detect_settings->{enabled};
  return ( 1, 'default' );
}

# detect: and no_detect: from .raider.yml, -o on top.
sub _detect_settings {
  my ($self) = @_;
  my $yml = $self->_load_yml_options;
  return $self->config->normalize_detect($yml->{detect}, $yml->{no_detect});
}

sub _detect_packs {
  my ($self, $collection) = @_;
  my %detections;
  $collection->detections(\%detections);
  my ( $enabled ) = $self->detection_state;
  return unless $enabled;

  my $settings = $self->_detect_settings;
  my %rules;
  for my $name (@{$collection->all_pack_names}) {
    my $pack = $collection->packs_by_name->{$name};
    next unless $pack->has_detect;
    $rules{$name} = [ 'pack default', $pack->detect, $pack->path.'/pack.yml detect' ];
  }
  $rules{$_} = [ $self->config->detect_rule_label($self->engine_name, $_), $settings->{rules}{$_}, 'detect.'.$_ ]
    for keys %{$settings->{rules}};

  my %no_pack = map { $_ => 1 } @{$self->no_pack_names};
  my $detect = $self->detect_class->new(root => $self->root);
  for my $name (sort keys %rules) {
    my ( $from, $rule, $label ) = @{$rules{$name}};
    $self->detect_class->validate_rule($rule, $label);
    my $record = sub {
      my ( $result, $reason, $notes ) = @_;
      $detections{$name} = { rule_from => $from, result => $result, reason => $reason, notes => $notes // [] };
    };
    my $skip = !$collection->packs_by_name->{$name} ? 'unknown pack'
             : $no_pack{$name}                     ? $self->source_label('no_pack_names')
             : $settings->{off}{$name}             ? $settings->{off}{$name}
             : $collection->is_active($name)       ? 'already active'
             :                                        undef;
    if ($skip) {
      $record->(skipped => $skip);
      next;
    }
    my $result = $detect->evaluate($rule, $label);
    unless ($result->{matched}) {
      $record->('not matched', $result->{reason}, $result->{notes});
      next;
    }
    if (my $holder = $collection->enable_detected($name, $result->{reason})) {
      my $kind = $collection->sources->{$holder}{source} eq 'detected' ? 'detected' : 'explicit';
      $record->(skipped => $kind.' '.$holder.' holds exclusive group '.$collection->packs_by_name->{$name}->exclusive_group);
      next;
    }
    $record->(matched => $result->{reason});
  }
  return;
}


sub redetect_packs {
  my ($self) = @_;
  my $collection = $self->packs;
  for my $name (@{ [ @{$collection->active_pack_names} ] }) {
    $collection->disable($name) if ($collection->sources->{$name}{source} // '') eq 'detected';
  }
  $self->_detect_packs($collection);
  return grep { ($collection->sources->{$_}{source} // '') eq 'detected' } @{$collection->active_pack_names};
}


has max_context_tokens => (
  is      => 'ro',
  isa     => 'Int',
  default => 40_000,
);


has context_compress_threshold => (
  is      => 'ro',
  isa     => 'Num',
  default => 0.7,
);


has skill_sources => (
  is      => 'ro',
  isa     => 'ArrayRef[HashRef]',
  lazy    => 1,
  builder => '_build_skill_sources',
);


has cli_skill_sources => (
  is        => 'ro',
  isa       => 'ArrayRef[HashRef]',
  predicate => 'has_cli_skill_sources',
);


has config => (
  is         => 'ro',
  isa        => 'Langertha::Raider::Config',
  lazy_build => 1,
);

sub _build_config {
  my ($self) = @_;
  return Langertha::Raider::Config->new(root => $self->root);
}


has instructions => (
  is         => 'ro',
  isa        => 'Langertha::Raider::Instructions',
  lazy_build => 1,
);

sub instructions_class { 'Langertha::Raider::Instructions' }

sub _build_instructions {
  my ($self) = @_;
  return $self->instructions_class->new(root => $self->root);
}

# Which settings were passed to the constructor (the command-line flags), for
# explain_config. Lazy attributes cannot tell that apart once built.
has _explicit => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => undef,
  default  => sub { {} },
);

sub BUILD {
  my ($self, $args) = @_;
  $self->_explicit->{$_} = 1 for grep { exists $args->{$_} } qw( engine model api_key perl );
}

sub _build_skill_sources {
  my ($self) = @_;
  return [] if $self->bare;
  return [ $self->config->skill_specs(
    $self->engine_name,
    @{ $self->_cli_app_options->{skills} // [] },
    $self->has_cli_skill_sources ? @{$self->cli_skill_sources} : (),
  ) ];
}

sub _load_skill_texts {
  my ($self) = @_;
  my @out;
  for my $spec (@{$self->skill_sources}) {
    my $type = $spec->{type} // 'dir';
    my $rel  = $spec->{path};
    next unless defined $rel && length $rel;
    my $base = Path::Tiny::path($rel);
    $base = Path::Tiny::path($self->root)->child($rel) unless $base->is_absolute;
    next unless $type eq 'file' || -d $base;

    my @files;
    if ($type eq 'file') {
      # Single markdown file — $base is that file, not a directory.
      my $f = Path::Tiny::path($rel);
      $f = Path::Tiny::path($self->root)->child($rel) unless $f->is_absolute;
      next unless -f $f;
      @files = ($f);
    }
    elsif ($type eq 'claude') {
      # Claude layout: $base/<skill>/SKILL.md
      for my $dir ($base->children) {
        next unless -d $dir;
        my $f = $dir->child('SKILL.md');
        push @files, $f if -f $f;
      }
    }
    else {
      my $glob = $spec->{glob} // '*.md';
      push @files, $base->children(qr/\Q$glob\E$/);
      # Fallback: recurse if nothing matched at the top level
      if (!@files) {
        @files = grep { -f $_ && /\.md$/ } $base->children;
      }
    }

    for my $f (sort @files) {
      my $name = $type eq 'claude' ? $f->parent->basename : $f->basename;
      my $body = eval { $f->slurp_utf8 } // next;
      # Strip YAML frontmatter if present.
      $body =~ s/\A---\s*\n.*?\n---\s*\n//s;
      push @out, "### Skill: $name\n\n$body";
    }
  }
  return @out;
}


has engine_options => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

# The -o pairs that configure raider itself, the list keys split on commas
# as they would read from .raider.yml.
sub _cli_app_options {
  my ($self) = @_;
  my $opts = $self->engine_options;
  my %app;
  for my $key (grep { $self->config->is_app_key($_) } keys %$opts) {
    my $value = $opts->{$key};
    $value = [ split /,/, $value ] if ($key eq 'packs' || $key eq 'skills') && !ref $value;
    $app{$key} = $value;
  }
  return \%app;
}

sub _cli_engine_options { $_[0]->engine_resolver->cli_engine_options }

sub _load_yml_options {
  my ($self) = @_;
  my %app = %{ $self->_cli_app_options };
  delete $app{skills};
  return { %{ $self->config->options($self->engine_name) }, %app };
}

sub _engine_yml_options { $_[0]->engine_resolver->engine_yml_options }

has loop => (
  is      => 'ro',
  isa     => 'IO::Async::Loop',
  lazy    => 1,
  default => sub { IO::Async::Loop->new },
);

has _engine => (is => 'ro', lazy => 1, builder => '_build_engine');
has _raider => (is => 'ro', lazy => 1, builder => '_build_raider', predicate => '_has_raider');
has _mcps   => (is => 'ro', lazy => 1, builder => '_build_mcps', predicate => '_has_mcps');

# The active tool set (ADR 0005): the MCP servers mounted for this raider.
# The engine's clients (_mcps) and the prompt's tool description
# (_tools_text) both come from it. _remount_tool_servers brings it in line
# again when the Perl tools grant changes.
has _tool_servers => (is => 'ro', lazy => 1, builder => '_build_tool_servers', predicate => '_has_tool_servers');

# The servers the set is assembled from, each built once, so a remount
# keeps the servers (and their clients) that stay mounted.
has _stock_tool_servers => (is => 'ro', lazy => 1, builder => '_build_stock_tool_servers');
has _perl_tool_server   => (is => 'ro', lazy => 1, builder => '_build_perl_tool_server');
has _hall_tool_server   => (is => 'ro', lazy => 1, builder => '_build_hall_tool_server');

sub _build_api_key { $_[0]->engine_resolver->api_key }

sub _engine_class { $_[0]->engine_resolver->engine_class }

sub _build_mcps {
  my ($self) = @_;
  return [ map { $self->_mcp_client($_) } @{ $self->_tool_servers } ];
}

sub _mcp_client {
  my ($self, $server) = @_;
  my $client = Net::Async::MCP->new(server => $server);
  $self->loop->add($client);
  return $client;
}

sub _build_tool_servers {
  my ($self) = @_;
  return [
    @{ $self->_stock_tool_servers },
    ( $self->perl_tools_enabled ? $self->_perl_tool_server : () ),
    ( $self->_hall_tool_server // () ),
  ];
}

sub _build_stock_tool_servers {
  my ($self) = @_;

  my $files = build_file_tools_server(root => $self->root);

  my $bash = MCP::Run::Bash->new(
    tool_name         => 'bash',
    tool_description  => 'Run a shell command with bash -c. Returns exit code, stdout, and stderr. Use this for ls, grep, find, git, cat, running tests, any shell pipeline — anything you would type at a terminal.',
    working_directory => $self->root,
    ($self->has_allowed_commands ? (allowed_commands => $self->allowed_commands) : ()),
    timeout => 120,
  );

  my $web = build_web_tools_server(loop => $self->loop);

  return [ $files, $bash, $web ];
}

sub _build_perl_tool_server {
  my ($self) = @_;
  my $lib_target = $self->has_preferred_lib_target
    ? $self->preferred_lib_target
    : ($self->_load_yml_options->{preferred_lib_target} // undef);
  return build_perl_tools_server(
    root       => $self->root,
    loop       => $self->loop,
    lib_target => $lib_target,
  );
}

# Hall-side tools: when we were spawned by raider-hall, expose
# telegram_reply / hall_status / hall_spawn so the agent can talk back.
sub _build_hall_tool_server {
  my ($self) = @_;
  return unless $ENV{RAIDER_HALL_SOCKET} && -S $ENV{RAIDER_HALL_SOCKET};
  return build_hall_tools_server(socket => $ENV{RAIDER_HALL_SOCKET});
}

# Remounts the tool set after the Perl tools grant changed (/pack,
# /reload): assembles it again, keeps the servers and clients that stay,
# adds clients for new servers and drops the clients of unmounted ones.
# Both arrays change in place -- the engine holds this very _mcps array as
# its mcp_servers, so the raider's next tool gather sees the new set.
# Returns true when the set changed. Before the set is built there is
# nothing to remount; the lazy build reads the current grant.
sub _remount_tool_servers {
  my ($self) = @_;
  return 0 unless $self->_has_tool_servers;
  my $servers = $self->_tool_servers;
  my $want    = $self->_build_tool_servers;
  return 0 if join(',', map { refaddr $_ } @$servers) eq join(',', map { refaddr $_ } @$want);
  if ($self->_has_mcps) {
    my $mcps = $self->_mcps;
    my %client = map { refaddr($servers->[$_]) => $mcps->[$_] } 0..$#$servers;
    my @clients = map { delete $client{refaddr $_} // $self->_mcp_client($_) } @$want;
    $self->loop->remove($_) for values %client;
    @$mcps = @clients;
  }
  @$servers = @$want;
  return 1;
}

sub _build_engine {
  my ($self) = @_;
  return $self->engine_resolver->build_engine(mcp_servers => $self->_mcps);
}

# Engine constructor arguments (Langertha::Raider::EngineResolver/engine_args).
sub _engine_args {
  my ($self) = @_;
  return $self->engine_resolver->engine_args(mcp_servers => $self->_mcps);
}

# The plugins of the raider, as name + {args} pairs for
# Langertha::Raider/plugins; a surface adds its own in front.
sub _raider_plugins {
  my ($self) = @_;
  weaken(my $app = $self);
  # Events last, so it reports the tool calls that actually run.
  return ( '+Langertha::Raider::Plugin::Situation',
    '+Langertha::Raider::Plugin::Events', { on_event => sub { $app->event(@_) if $app } } );
}

sub _build_raider {
  my ($self) = @_;
  my @plugins = $self->_raider_plugins;
  return Langertha::Raider->new(
    engine                     => $self->_engine,
    mission                    => $self->mission,
    max_iterations             => $self->max_iterations,
    max_context_tokens         => $self->max_context_tokens,
    context_compress_threshold => $self->context_compress_threshold,
    (@plugins ? (plugins => \@plugins) : ()),
  );
}


async sub raid_f {
  my ($self, @messages) = @_;
  for my $mcp (@{$self->_mcps}) {
    await $mcp->initialize;
  }
  my $raider = $self->_raider;
  # A cancel_run that came before the raider was there.
  $raider->cancel if $self->_run && $self->_run->{cancelled};
  return await $raider->raid_f(@messages);
}


sub run {
  my ($self, @messages) = @_;
  my $f = $self->raid_f(@messages);
  $self->loop->await($f);
  return $f->get;
}


# The ADR 0015 event types the journal records from the events of a run;
# run.finished is written by end_run.
my %JOURNAL_TYPE = map { $_ => 1 } qw( run.started message tool.call tool.result );

# The run in progress: { session, run, on_event, t0 }.
has _run => (
  is        => 'rw',
  init_arg  => undef,
  predicate => 'has_run',
  clearer   => '_clear_run',
);

sub run_prompt {
  my ( $self, $text, %o ) = @_;
  return unless defined $text && length $text;
  $self->begin_run(%o);
  $self->event('message', role => 'user', content => $text);

  my $result;
  unless (eval { $result = $self->run($text); 1 }) {
    my $error = $@;
    chomp $error;
    return $self->end_run(failed => error => $error);
  }
  if (blessed $result && $result->can('is_cancelled') && $result->is_cancelled) {
    return { %{ $self->end_run('cancelled') }, result => $result };
  }
  $self->event('message', role => 'assistant', content => "$result");
  my $metrics = $self->raider->metrics;
  my $end = $self->end_run(completed => metrics => $metrics);
  return { %$end, result => $result, response => "$result", metrics => $metrics };
}


sub begin_run {
  my ( $self, %o ) = @_;
  my $session = $o{session};
  $self->_run({
    session  => $session,
    run      => $session ? $session->next_run : undef,
    on_event => $o{on_event},
    t0       => Time::HiRes::time(),
  });
  $self->event('run.started', engine => $self->engine_name, $self->has_model ? ( model => $self->model ) : ());
  $self->event('run.state', state => 'running');
  return;
}


sub end_run {
  my ( $self, $status, %fields ) = @_;
  my $run = $self->_run or return;
  my $elapsed = 0 + sprintf('%.3f', Time::HiRes::time() - $run->{t0});
  my %end = (
    status  => $status,
    ( map { defined $fields{$_} ? ( $_ => $fields{$_} ) : () } qw( error signal ) ),
    elapsed => $elapsed,
  );
  if (my $session = $run->{session}) {
    my $metrics = $fields{metrics} // eval { $self->raider->metrics };
    $self->_append($run, 'run.finished', run => $run->{run}, %end, $metrics ? ( metrics => $metrics ) : ());
    $end{session} = { id => $session->id, path => ''.$session->path };
  }
  $self->event('run.state', state => $status);
  $self->_clear_run;
  # A cancel that came too late for the raid must not hit the next run.
  $self->_raider->clear_cancel if $self->_has_raider;
  return \%end;
}


sub cancel_run {
  my ( $self ) = @_;
  my $run = $self->_run or return 0;
  $run->{cancelled} = 1;
  $self->_raider->cancel if $self->_has_raider;
  return 1;
}


sub event {
  my ( $self, $type, %payload ) = @_;
  if (my $run = $self->_run) {
    $self->_append($run, $type, run => $run->{run}, %payload) if $run->{session} && $JOURNAL_TYPE{$type};
    $run->{on_event}->($type, %payload) if $run->{on_event};
  }
  $self->on_event->($type, %payload) if $self->has_on_event;
  return;
}


sub record {
  my ( $self, $session, $type, %fields ) = @_;
  return $self->_append({ session => $session }, $type, %fields);
}

# Appends to the session of $run (a run, or just { session }); reports
# only the first failure of each $run.
sub _append {
  my ( $self, $run, $type, %fields ) = @_;
  my $session = $run->{session};
  return 1 if eval { $session->append($type, %fields); 1 };
  my $error = $@;
  return 0 if $run->{journal_failed}++;
  if ($self->has_on_journal_error) {
    $self->on_journal_error->($session, $error);
  }
  else {
    warn 'session '.$session->id.' not fully saved: '.$error;
  }
  return 0;
}


sub raider { $_[0]->_raider }


sub loaded_skill_names {
  my ($self) = @_;
  my @names;
  for my $spec (@{$self->skill_sources}) {
    my $type = $spec->{type} // 'dir';
    my $rel  = $spec->{path};
    next unless defined $rel && length $rel;
    my $base = Path::Tiny::path($rel);
    $base = Path::Tiny::path($self->root)->child($rel) unless $base->is_absolute;
    if ($type eq 'file') {
      push @names, $base->basename if -f $base;
      next;
    }
    next unless -d $base;
    if ($type eq 'claude') {
      for my $dir (sort $base->children) {
        next unless -d $dir;
        push @names, $dir->basename if -f $dir->child('SKILL.md');
      }
    }
    else {
      for my $f (sort $base->children) {
        push @names, $f->basename if -f $f && $f =~ /\.md$/;
      }
    }
  }
  return @names;
}


has session_store => (
  is       => 'ro',
  isa      => 'Langertha::Raider::SessionStore',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_session_store',
);

sub session_store_class { 'Langertha::Raider::SessionStore' }

sub _build_session_store {
  my ($self) = @_;
  return $self->session_store_class->new(root => $self->root);
}


sub create_session {
  my ($self) = @_;
  return $self->session_store->create;
}


sub open_session {
  my ($self, $id) = @_;
  return $self->session_store->open($id);
}


sub replay_session {
  my ($self, $session) = @_;
  my $journal = $session->journal;
  my $raider  = $self->raider;
  $raider->add_history($_->{role}, $_->{content}) for @{ $journal->history_messages };
  $raider->add_session_history(@{ $journal->session_history_messages });
  return $journal;
}


sub fork_session {
  my ($self, $id) = @_;
  my $store = $self->session_store;
  my $history = $store->read($id)->history_messages;
  my $session = $store->create(forked_from => $id);
  $session->append('message', role => $_->{role}, content => $_->{content}) for @$history;
  $session->release;
  return { id => $session->id, path => ''.$session->path, forked_from => $id, messages => scalar @$history };
}


sub remove_session {
  my ($self, $id) = @_;
  my $store = $self->session_store;
  my $path = ''.$store->path_of($id);
  $store->remove($id);
  return $path;
}


sub reload_mission {
  my ($self) = @_;
  my $remounted = $self->_remount_tool_servers;
  my $new = $self->_build_mission;
  # Hot-swap on the running raider, history and metrics stay.
  my $raider = $self->_raider;
  $raider->_set_mission($new);
  # A raid resumed from a continuation re-gathers its tools too.
  $raider->_tools_dirty(1) if $remounted;
  return $new;
}


sub mission_source {
  my ($self) = @_;
  return $self->source_label('mission') if $self->_has_explicit_mission;
  my $instructions = $self->instructions;
  return !$self->bare && $instructions->file_exists ? $instructions->label : 'default';
}


sub source_labels { {} }

sub source_label {
  my ($self, $key) = @_;
  return $self->source_labels->{$key} // $key;
}


sub explain_config {
  my ($self) = @_;
  my $engine   = $self->engine_name;
  my $report   = $self->config->explain($engine);
  my $explicit = $self->_explicit;
  my $app_opts = $self->_cli_app_options;
  my $opts     = { %{ $self->_cli_engine_options }, %$app_opts };
  my $opt_label = $self->source_label('engine_options');

  # Config file values as candidates: [ source, value, shadowed,
  # merged_with ]
  my ( %yml, @yml_skills );
  for my $v (@{ $report->{values} }) {
    my $candidate = [
      $self->_yml_source($v->{source}),
      $v->{value},
      [ map { $self->_yml_source($_) } @{ $v->{shadowed} } ],
      ( $v->{merged_with} ? [ map { $self->_yml_source($_) } @{ $v->{merged_with} } ] : () ),
    ];
    if ($v->{merged}) {
      push @yml_skills, { %$v, source => $candidate->[0], shadowed => [] };
      next;
    }
    $yml{ $v->{key} } = { applies_to => $v->{applies_to}, candidate => $candidate };
  }
  my %from_yml = map { $_ => $yml{$_}{candidate} } keys %yml;

  my $env_var = $self->engine_resolver->env_var_for_engine($engine);
  my $env_key = defined $env_var && length($ENV{$env_var} // '') ? $env_var : undef;
  my $default_model = $self->engine_resolver->default_model_for_engine($engine);
  my $yml_key = $from_yml{api_key};

  my @values = (
    $self->_explain_entry(engine => 'raider', [
      $explicit->{engine} ? [ $self->source_label('engine'), $engine ] : undef,
      defined $opts->{engine} ? [ $opt_label, $opts->{engine} ] : undef,
      $from_yml{engine},
    ], [ $env_key ? 'env '.$env_key : 'default', $engine ]),
    $self->_explain_entry(model => 'engine', [
      $explicit->{model} ? [ $self->source_label('model'), $self->model ] : undef,
      defined $opts->{model} ? [ $opt_label, $opts->{model} ] : undef,
      $from_yml{model},
    ], defined $default_model ? [ 'default', $default_model ] : undef),
    $self->_explain_entry(api_key => 'engine', [
      $explicit->{api_key} ? [ $self->source_label('api_key'), '(set)' ] : undef,
      defined $opts->{api_key} ? [ $opt_label, '(set)' ] : undef,
      $yml_key ? [ $yml_key->[0], '(set)', $yml_key->[2] ] : undef,
    ], $env_key ? [ 'env '.$env_key, '(set)' ] : undef),
  );

  my %flag = (
    ( $self->has_pack_names ? ( packs => [ $self->source_label('pack_names'), $self->pack_names ] ) : () ),
    ( $explicit->{perl} && $self->perl ? ( perl => [ $self->source_label('perl'), 1 ] ) : () ),
    ( $self->has_detect_flag
      ? ( detect => [ $self->source_label($self->detect ? 'detect' : 'no_detect'), $self->detect ? 1 : 0 ] ) : () ),
  );
  my %key = map { $_ => 1 } keys %$opts, keys %yml, keys %flag;
  delete @key{qw( engine model api_key skills project_tools )};
  my @ignored = @{ $report->{ignored} };
  push @ignored, { key => $opt_label.' project_tools', reason => 'only ~/.raider/config.yml grants tools to projects' }
    if exists $opts->{project_tools};
  for my $key (sort keys %key) {
    my $applies_to = $self->config->is_app_key($key) ? 'raider' : 'engine';
    push @values, $self->_explain_entry($key, $applies_to, [
      $flag{$key} // ( exists $opts->{$key} ? [ $opt_label, $opts->{$key} ] : undef ),
      $from_yml{$key},
    ]);
  }

  push @values, @yml_skills;
  push @values, {
    key        => 'skills',
    value      => $app_opts->{skills},
    source     => $opt_label,
    shadowed   => [],
    merged     => 1,
    applies_to => 'raider',
  } if $app_opts->{skills};
  push @values, {
    key        => 'skills',
    value      => $self->cli_skill_sources,
    source     => $self->source_label('cli_skill_sources'),
    shadowed   => [],
    merged     => 1,
    applies_to => 'raider',
  } if $self->has_cli_skill_sources;

  my ( $detecting, $why ) = $self->detection_state;
  return {
    %$report,
    values        => \@values,
    ignored       => \@ignored,
    ( $report->{project_tools}
      ? ( project_tools => { %{ $report->{project_tools} }, tools => $self->_project_tools_report($report->{project_tools}) } )
      : () ),
    detection     => $detecting ? 'on' : 'off ('.$why.')',
    instructions  => $self->mission_source,
    bare          => $self->bare ? 1 : 0,
    packs         => $self->packs->activation_report,
    skipped_packs => $self->packs->skipped_packs,
    perl_tools    => $self->perl_tools_grant,
    tools         => $self->_tool_effects_report,
    ignored_instructions_files => [ $self->instructions->ignored_files ],
  };
}

# One entry per mounted tool: name, source (engine:N, the 1-based mount
# position -- the name the internal gate sees) and its effect classes from
# Langertha::Raider::ToolEffects, undef when the table does not know it.
sub _tool_effects_report {
  my ($self) = @_;
  my $n = 0;
  return [ map {
    my $source = 'engine:'.++$n;
    map { { name => $_->name, source => $source, effects => $self->_tool_effects_class->effects_for($_->name) } }
      @{ $_->tools };
  } @{ $self->_tool_servers } ];
}

sub _tool_effects_class { 'Langertha::Raider::ToolEffects' }

# One entry per tool name that project_tools names or an active pack
# requests: the matching selectors that grant it, the packs that request
# it, and whether raider knows the name (a built-in or mounted tool, or a
# tool group). Information only: the active tool set does not follow it.
sub _project_tools_report {
  my ($self, $project_tools) = @_;
  my ( %granted, %requested );
  for my $s (@{ $project_tools->{selectors} }) {
    for my $name (@{ $s->{tools} }) {
      $granted{$name} //= [];
      push @{ $granted{$name} }, $s->{selector} if $s->{matched};
    }
  }
  my $packs = $self->packs;
  for my $pack (@{ $packs->enabled_pack_names }) {
    push @{ $requested{$_} }, 'pack '.$pack for @{ $packs->packs_by_name->{$pack}->tools };
  }
  my %mounted = map { $_->name => 1 } $self->_mounted_tools;
  my %group   = map { $_ => 1 } $self->_tool_group_names;
  return [ map {
    my $name = $_;
    {
      name         => $name,
      granted_by   => $granted{$name} // [],
      requested_by => $requested{$name} // [],
      known        => $group{$name} ? 'tool group'
                    : $mounted{$name} || $self->_tool_effects_class->effects_for($name) ? 'tool'
                    : undef,
    }
  } sort keys %{ { %granted, %requested } } ];
}

# The tool groups raider grants by name today: what a pack's tools: may
# request (perl, the Perl tools of perl_tools_grant).
sub _tool_group_names { qw( perl ) }

sub _yml_source { $_[0]->config->layer_label($_[1]) }

# One explain entry from candidates [ source, value, shadowed,
# merged_with ], highest priority first; the fallback counts only when no
# candidate is set.
sub _explain_entry {
  my ($self, $key, $applies_to, $candidates, $fallback) = @_;
  my @have = grep { defined } @$candidates;
  @have = ($fallback) if !@have && $fallback;
  return unless @have;
  my ($win, @rest) = @have;
  return {
    key        => $key,
    value      => $win->[1],
    source     => $win->[0],
    shadowed   => [ @{ $win->[2] // [] }, map { ( $_->[0], @{ $_->[3] // [] }, @{ $_->[2] // [] } ) } @rest ],
    applies_to => $applies_to,
    ( $win->[3] ? ( merged_with => $win->[3] ) : () ),
  };
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Application - Internal application service that builds and runs a raider for a workspace

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $app = Langertha::Raider::Application->new(
      root           => '/path/to/project',
      engine_options => { temperature => 0.2 },
    );

    my $result = $app->run('Explore the repo and summarize it.');
    my $raider = $app->raider;                   # the Langertha::Raider

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The application service the surfaces share (ADR 0002): for one workspace
(L</root>) it reads the project config file (L<Langertha::Raider::Config>:
F<.raider/config.yml>, else the legacy F<.raider.yml>; below, F<.raider.yml>
stands for whichever is in use, laid over the home file
F<~/.raider/config.yml>), picks
the engine through L<Langertha::Raider::EngineResolver>, activates the
packs (L<Langertha::Raider::Packs>, ADR 0012), compiles the mission (ADR
0004, ADR 0014), mounts the tool servers -- files
(L<Langertha::Raider::FileTools>), C<bash> (L<MCP::Run::Bash>), web
(L<Langertha::Raider::WebTools>), the Perl tools
(L<Langertha::Raider::PerlTools>) when granted, the Hall tools when
spawned by a Hall -- and builds the L<Langertha::Raider> that runs the
raids. It opens, creates and replays the sessions of the project
(L</session_store>, ADR 0015) and records every run in the session's
journal (L</run_prompt>), handing the run's events on to the surface. It
prints nothing; presentation such as the live trace belongs to
the surface, see L<Langertha::Raider::CLI>.

=head2 engine_name

Langertha engine class shortcut (e.g. C<'anthropic'>, C<'openai'>,
C<'deepseek'>, C<'groq'>, C<'mistral'>, C<'gemini'>, C<'ollama'>), passed as
C<engine>. Defaults to C<-o engine=>, then to C<engine:> in F<.raider.yml>,
then to the first C<*_API_KEY> environment variable found, then to
C<'anthropic'> (L<Langertha::Raider::EngineResolver/engine_name>).

=head2 engine_resolver

The L<Langertha::Raider::EngineResolver> that picks engine, model and API
key from the flags, the C<-o> options, F<.raider.yml> and the
environment, and builds the engine.

=head2 provider

The completed provider activation of C<raider --provider>
(L<Langertha::Raider::Provider::Activation/activate_f>), or none. It
decides engine, model and URL; see
L<Langertha::Raider::EngineResolver/provider>.

=head2 model

Model identifier to pass to the engine. Defaults to C<model> in
L</engine_options>, then C<model:> in F<.raider.yml>, then the per-engine
cheap default. An explicit C<model> always wins; this is the model the
engine is built with.

=head2 api_key_env

Name of the environment variable used for the current engine's API key
(for display / debugging). Returns undef for engines that don't use an API
key (e.g. ollama).

=head2 api_key

API key for the engine. Defaults to C<api_key> in L</engine_options>, then
C<api_key:> in F<.raider.yml>, then an engine-appropriate environment
variable. An explicit C<api_key> always wins.

=head2 mission

System prompt of the Raider, compiled from separate items (ADR 0004,
ADR 0014): the instructions (a generic assistant persona plus the project
instructions file, L</instructions>), the tool description, the loaded
skills and the active packs. The tool description lists the tools of the mounted tool servers
-- the same servers the engine gets -- each as C<name(required, [optional])>
from its input schema (ADR 0005); a tool that is not mounted is not
described. A C<mission> passed to the constructor (C<-M>) replaces the
instructions item only, also across L</reload_mission>; the other items
still apply. With L</bare> the skills, the instructions file and all packs not
switched on by C<--pack> or C</pack> are left out.

=head2 bare

C<--bare>: an isolated context. No instructions file (F<.raider.md>,
F<.raider/instructions.md>), no skills, no pack
detection, and no packs from C<packs:> or C<enabled_by_default>;
C<--pack NAME> and C</pack NAME> still switch a pack on explicitly. What
remains is the instructions (the default persona, or the C<-M> text) and
the tool description.

=head2 persona_intro

The first paragraph of the default persona: who the agent is and where it
runs. The command line (L<Langertha::Raider::CLI>) says it is a CLI.

=head2 persona_turn_end

The last paragraph of the default persona: how the agent ends a turn and
who answers next.

=head2 root

Working directory for tool operations. Defaults to the current process cwd.
File tools are confined to this directory, including realpath checks for
symlink escapes; bash commands inherit it as their default working directory.

=head2 allowed_commands

Optional arrayref restricting which bash commands may run (first word match).
When undef, any command is allowed.

=head2 max_iterations

Maximum tool-calling iterations per raid. Defaults to 10_000 — effectively
unlimited, so a raid only ends when the model itself stops emitting tool
calls. The conversation history is preserved between raids, so the next user
message in the REPL simply continues the same thread.

Set this to a smaller number if you want a hard safety cap.

=head2 on_event

Optional code reference called as C<< $on_event->($type, %payload) >> for
every event of the application (L</event>): the run events of
L</run_prompt> and every C<tool.call> and C<tool.result> of a raid, which
come from L<Langertha::Raider::Plugin::Events>. A surface that follows
one run passes its consumer to L</run_prompt> instead.

=head2 on_journal_error

Optional code reference called as C<< $on_journal_error->($session, $error) >>
when an event cannot be written to a session journal (a full disk): once
per run, and once per L</record>. The run goes on. Without it the error
is a C<warn>.

=head2 perl

Enable the PerlTools MCP server (perl_eval, perl_check, perl_cpanm).
Off by default; set via C<--perl> CLI flag or C<perl: true> in F<.raider.yml>.
Without either, the tools also come with the C<perl> pack, which is
detected in a Perl workspace; see L</perl_tools_enabled>.

=head2 perl_tools_enabled

Whether the PerlTools server is mounted: C<--perl> turns it on; else an
explicit C<perl:> (in F<.raider.yml> or C<-o perl=>) decides either way;
else it is on when an active pack requests the C<perl> tools (the bundled
C<perl> pack, detected by F<cpanfile>, F<dist.ini>, F<Makefile.PL> or
F<lib/**/*.pm>). Granting a pack's request here stands in for the local
tool policy of ADR 0005, which does not exist yet; C<perl: false> is the
local denial. A pack switched on or off later is followed by
L</reload_mission>, which remounts the server to match.

=head2 perl_tools_grant

    my $grant = $app->perl_tools_grant;
    # { enabled => 1, reason => 'pack perl (detected)' }

L</perl_tools_enabled> with the reason: L</perl> by its L</source_label>
(C<--perl> on the command line), C<perl: true> or C<perl: false> with
where it was set (C<.raider.yml> or the label of C<engine_options>, C<-o>), the active
packs requesting the tools with their activation source, or
C<not requested>.

=head2 preferred_lib_target

Override the default local::lib target for perl_cpanm. When unset,
defaults to F<.raider/lib/> for standalone raiders. Can be set via
C<preferred_lib_target> in F<.raider.yml>.

=head2 pack_names

Optional list of pack names supplied by the CLI, usually from repeatable
C<--pack NAME>. When present, these override the C<packs:> list in
F<.raider.yml>.

=head2 no_pack_names

Pack names switched off from the command line (repeatable C<--no-pack
NAME>). They win over C<--pack>, C<packs:>, the bundled defaults and
detection.

=head2 detect

Pack detection from the command line: C<0> for C<--no-detect>, C<1> for
C<--detect>. When not given, C<detect:> in F<.raider.yml> decides; the
default is on.

=head2 packs

L<Langertha::Raider::Packs::Collection> of the installed packs: those in
F<< L</root>/.raider/packs/ >>, F<~/.raider/packs/>, the bundled
C<share/packs/> and C<$RAIDER_PACK_DIRS>, the first place winning for a
name (L<Langertha::Raider::Packs/build_packs>). Which are
enabled, highest priority first (ADR 0012); with L</bare> only
C<--pack NAME> applies:

=over

=item 1. C<--no-pack NAME> switches a pack off; C<--pack NAME> (or
C<-o packs=a,b>) enables the listed ones exclusively; C<--no-detect> /
C<--detect> switch detection off or on.

=item 2. C<packs:> in F<.raider.yml> (C<[caveman, git-guru]>) enables the
listed ones exclusively when no flag named packs; C<detect: false> and
C<no_detect: [NAME]> switch detection off entirely or per pack.

=item 3. Packs whose detection rule matches L</root> are added.

=back

Without explicit packs the bundled defaults (C<enabled_by_default>) are
on.

Detection rules come from a pack's F<pack.yml> (C<detect:>, the pack
default) and from C<detect:> in F<~/.raider/config.yml> and
F<.raider.yml>, which replace the pack default per pack name, the
project's rule over the home's. Each rule is evaluated against L</root> with
L<Langertha::Raider::Detect> when L</packs> is built and on
L</redetect_packs> (C</reload>), never per model call. A detected pack is
added to the enabled ones; in an exclusive group it gives way to an
explicit pack and replaces a bundled default. The outcome per pack is in
L<Langertha::Raider::Packs::Collection/activation_report>. An invalid rule
croaks.

Detection only decides which packs are active, it grants nothing (ADR
0005). Rules from the project's F<.raider.yml> or F<.raider/config.yml>
are evaluated and packs
from its F<.raider/packs/> are loaded right away: the workspace trust
decision of ADR 0004, which is meant to gate both, does not exist yet.

=head2 detection_state

    my ( $on, $why ) = $app->detection_state;

Whether pack detection runs, and what decided it: L</bare> or L</detect>
by their L</source_label> (C<--bare>, C<--detect>, C<--no-detect> on the
command line), C<detect: false> or C<default>.

=head2 redetect_packs

    my @detected = $app->redetect_packs;

Drops the packs that were enabled by detection, evaluates the rules again
against L</root> and returns the names of the packs detected now. Packs
enabled any other way stay as they are. C</reload> calls it.

=head2 max_context_tokens

Trigger history auto-compression once the last prompt exceeds
C<context_compress_threshold * max_context_tokens>. Defaults to 40_000, which
keeps the running session comfortably under typical per-minute rate limits
(Anthropic org default: 50k input tokens/min on Haiku).

=head2 context_compress_threshold

Fraction of L</max_context_tokens> at which compression kicks in. Defaults to
C<0.7>.

=head2 skill_sources

ArrayRef of skill-source specs to load and append to the mission. Each spec
is a hashref:

    { type => 'claude', path => '.claude/skills' }  # Claude Code SKILL.md tree
    { type => 'dir',    path => 'my-skills', glob => '*.md' }

Defaults to the C<skills> entries of F<.raider.yml> (see
L<Langertha::Raider::Config>) followed by L</cli_skill_sources>. Passing
C<skill_sources> explicitly replaces both. With L</bare> there are none.

=head2 cli_skill_sources

ArrayRef of skill-source specs from the command line (C<--claude>,
C<--openai>, C<--skills DIR>). They are added to the F<.raider.yml> skills,
duplicates dropped.

=head2 config

The L<Langertha::Raider::Config> of L</root>: F<.raider/config.yml>, else
F<.raider.yml>, over F<~/.raider/config.yml>.

=head2 instructions

The L<Langertha::Raider::Instructions> of L</root>: the project
instructions file, F<.raider/instructions.md>, else F<.raider.md>.

=head2 engine_options

HashRef of the C<-o KEY=VALUE> options. Engine attributes (e.g.
C<temperature>, C<response_size>, C<seed>) are forwarded to the engine
constructor, merged on top of values loaded from C<.raider.yml> in the
working directory. Raider's own keys (see
L<Langertha::Raider::Config/is_app_key>) configure raider like their
F<.raider.yml> counterparts and override them; C<packs> and C<skills> take
a comma-separated list.

=head2 raid_f

    my $result = await $app->raid_f($prompt);

Async variant: drives one raid iteration and returns the
L<Langertha::Raider::Result>.

=head2 run

    my $result = $app->run($prompt);

Synchronous convenience wrapper around L</raid_f>. Runs the I/O loop until the
raid completes and returns the result (which stringifies to the final text).

=head2 run_prompt

    my $outcome = $app->run_prompt($text,
      session  => $session,                                   # optional
      on_event => sub { my ( $type, %payload ) = @_; ... },   # optional
    );

Runs C<$text> as one run (L</run>) and records it, whichever surface
asks: in the journal of the L<Langertha::Raider::Session> as the
session's next run (ADR 0015) -- C<run.started>, the user input as
C<message>, every C<tool.call> and C<tool.result> with the whole result
text, the final answer as C<message>, and C<run.finished> with the end
state and the raider's metrics, also when the run failed. A journal write
that fails goes to L</on_journal_error>; the run goes on.

Every event of the run goes to C<on_event> (and L</on_event>) through
L</event>: the journal types and C<run.state> (C<running>, then the end
state), as ADR 0013 names them.

Returns the outcome as a hash reference: C<status> (C<completed>,
C<failed>, or C<cancelled> after L</cancel_run>), C<elapsed> (seconds, to
the millisecond), C<result> (the L<Langertha::Raider::Result>, also of a
cancelled run), C<response> (its text) and C<metrics> of a completed run,
C<error> of a failed one, and C<session> (C<id>, C<path>) when there is
one. An empty C<$text> runs nothing and returns nothing.

=head2 begin_run

    $app->begin_run(session => $session, on_event => $consumer);

Starts a run as L</run_prompt> does, for a surface that drives L</run>
itself: the run gets the next run id of C<session>, C<run.started> (engine
and model) and C<run.state> C<running>. L</end_run> ends it.

=head2 end_run

    my $end = $app->end_run(interrupted => signal => 'TERM');

Ends the run in progress, if there is one: C<run.finished> with
C<$status> and the given C<error> and C<signal> into the journal, with the
given C<metrics> or else the raider's, then C<run.state> with C<$status>.
Returns C<status>, C<elapsed>, the C<error> and C<signal> given and, with a
session, C<session> (C<id>, C<path>) -- or nothing outside a run. A
surface calls it for a run it ends itself, as the command line does for a
signal.

=head2 cancel_run

    $app->cancel_run;

Cancels the run in progress (ADR 0009): its raid stops at the next safe
point (L<Langertha::Raider/cancel>) and L</run_prompt> ends the run as
C<cancelled> -- C<run.finished> with that status, and a tool call cut off
gets its C<tool.result> with status C<cancelled>. Tool subprocesses are
not signalled here; that is the surface's to do. Only records the
request, so a signal handler may call it. Outside a run it does nothing
and returns false.

=head2 event

    $app->event('tool.call', call => 'c1', name => 'bash', arguments => { ... });

One event of the application, handed to every consumer: the session
journal of the run in progress for the types it records (with the run's
C<run> id), the C<on_event> of that run, and L</on_event>.

=head2 record

    $app->record($session, 'history.cleared');

Appends one event outside a run to the session journal. A write that
fails goes to L</on_journal_error> and returns false.

=head2 raider

Returns the underlying L<Langertha::Raider> instance (lazily built).

=head2 loaded_skill_names

Returns a list of skill names currently discoverable from the configured
L</skill_sources>. Intended for banner/status display.

=head2 session_store

The L<Langertha::Raider::SessionStore> of the project in L</root> (ADR
0003, ADR 0015), built on first use.

=head2 create_session

    my $session = $app->create_session;

A new session in L</session_store>, open for writing and locked
(L<Langertha::Raider::SessionStore/create>).

=head2 open_session

    my $session = $app->open_session($id);

Opens the session C<$id> of L</session_store> for writing; croaks C<...
is in use> while another raider holds it
(L<Langertha::Raider::SessionStore/open>).

=head2 replay_session

    my $journal = $app->replay_session($session);

Replays the journal the L<Langertha::Raider::Session> was opened with into
L</raider> (ADR 0015): C<history> from the C<message> events of the runs
that got an answer, C<session_history> from all events. Nothing is
executed. Returns the L<Langertha::Raider::Session::Journal>.

=head2 fork_session

    my $fork = $app->fork_session($id);
    # { id, path, forked_from, messages }

A new session in L</session_store> whose C<session.created> names the
session C<$id> in C<forked_from>, and which takes over its working
history -- what a resume would replay into C<history>
(L<Langertha::Raider::Session::Journal/history_messages>) -- as
C<message> events outside any run. The original is only read (no lock
needed) and never changed. Returns the new session's C<id> and C<path>,
C<forked_from> and how many C<messages> it took over.

=head2 remove_session

    my $path = $app->remove_session($id);

Deletes the session C<$id> of L</session_store>, journal and lock file
(L<Langertha::Raider::SessionStore/remove>, which croaks C<session ID is
in use> while another raider has it open). Returns the journal's path.

=head2 reload_mission

Rebuilds the mission (e.g. after the instructions file has been edited) and swaps it
into the underlying L<Langertha::Raider>. An explicit L</mission> is kept.
When L</perl_tools_grant> changed since the tool servers were mounted
(C</pack>, C</reload>), the PerlTools server is mounted or unmounted first,
so the engine offers the same tools the new mission describes from the
next raid on; a raid resumed from a pending question re-gathers them too.

=head2 mission_source

Where the instructions item of L</mission> comes from: the
L</source_label> of C<mission> (C<-M> on the command line) for a mission
passed to the constructor; the L<Langertha::Raider::Instructions/label> of
the instructions file (C<.raider/instructions.md> or C<.raider.md>) when
it customizes the default persona (never with L</bare>); C<default>
otherwise.

=head2 source_label

    my $label = $app->source_label('pack_names');   # 'pack_names', '--pack' in the CLI

How reports name a setting that was passed to the constructor: in
L</explain_config>, L</perl_tools_grant>, L</detection_state>,
L</mission_source> and the pack sources. The keys are C<engine>,
C<model>, C<api_key>, C<engine_options>, C<engine_options packs>,
C<pack_names>, C<no_pack_names>, C<perl>, C<detect>, C<no_detect>,
C<bare>, C<mission> and C<cli_skill_sources>. A surface names its own
way of setting them in L</source_labels>; without, the label is the key.

=head2 source_labels

The labels of L</source_label> by key; none here. The command line
(L<Langertha::Raider::CLI>) returns its flags.

=head2 explain_config

    my $report = $app->explain_config;

Where each effective setting came from, constructor arguments included.
The shape of L<Langertha::Raider::Config/explain>, with C<source> (and
C<shadowed>) naming an argument by its L</source_label> (the command line
names its flags: C<-e>, C<-m>, C<-k>, C<-o>, C<--pack>, C<--perl>,
C<--claude/--openai/--skills>), a layer of the config file by its
L<Langertha::Raider::Config/label> (C<.raider.yml>, C<.raider.yml default:>,
C<.raider/config.yml openai:>), a layer of the home file
F<~/.raider/config.yml> (C<home>, C<home default:>, C<home openai:>), an
environment variable (C<env OPENAI_API_KEY>) or C<default>. A value merged
from both files (C<no_detect>, C<detect>) names the home layer in
C<merged_with>. API key values
are never included. Builds no engine. C<file> is the config file in use and
C<ignored_files> the config files next to it that are not loaded
(L<Langertha::Raider::Config/ignored_files>); C<home_file> is the home
file, present only when it is loaded.

C<detection> says whether pack detection runs (C<on>, or C<off> with what
switched it off) and C<packs> is the
L<Langertha::Raider::Packs::Collection/activation_report>: each pack with
its source (C<flag>, C<config>, C<default>, C<detected>, C<manual>), its
C<origin> (C<project>, C<home>, C<shipped>, C<env>) and, for detection
rules, the clause that matched or failed. C<skipped_packs> is
L<Langertha::Raider::Packs::Collection/skipped_packs>. C<perl_tools> is
L</perl_tools_grant>: whether the Perl tools are mounted, and why.

C<instructions> is L</mission_source> and C<bare> is L</bare>.
C<ignored_instructions_files> are the instructions files that are present
but not used (L<Langertha::Raider::Instructions/ignored_files>): a legacy
F<.raider.md> next to F<.raider/instructions.md>.

C<tools> lists the mounted tools, each with its C<name>, its C<source>
(C<engine:N>) and C<effects>: what it can do, from a static built-in table
(C<read>, C<write>, C<network>, C<code>, C<message>; empty when it only
steers the run), or undef when the table does not know the tool. Information
only -- nothing is enforced by it.

C<project_tools> is present when F<~/.raider/config.yml> has one (ADR 0011;
L<Langertha::Raider::Config/project_tools>): the C<file> and C<label> it
was read from, C<selectors> with whether each matches L</root> and why,
and C<tools>, one entry per tool name that a selector names or an active
pack requests (the C<tools:> of its F<pack.yml>; a project has no other
way to request a tool yet): C<granted_by>, the matching selectors naming
it (empty: not granted); C<requested_by>, the requesting packs
(C<pack perl>); and C<known>, C<tool> for a built-in or mounted tool,
C<tool group> for C<perl>, undef for a name raider does not know (not an
error). Information only -- the mounted tools do not follow it yet. A
C<project_tools> in the project file, inside a section, or given with
C<-o> is not read and is listed in C<ignored>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider>

=item * L<Langertha::Raider::CLI>

=item * L<Langertha::Raider::EngineResolver>

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
