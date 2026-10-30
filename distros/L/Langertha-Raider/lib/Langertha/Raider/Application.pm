package Langertha::Raider::Application;
# ABSTRACT: Internal application service that builds and runs a raider for a workspace
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use IO::Async::Loop;
use Future;
use Future::AsyncAwait;
use JSON::MaybeXS ();
use Net::Async::MCP;
use Carp qw( croak );
use Path::Tiny;
use Scalar::Util qw( blessed refaddr weaken );
use Time::HiRes ();
use Langertha::Raider::HallTools qw( build_hall_tools_server );

use Langertha::Raider::FileTools qw( build_file_tools_server );
use Langertha::Raider::FileTools::ReadState;
use Langertha::Raider::WebTools  qw( build_web_tools_server );
use Langertha::Raider::PerlTools qw( build_perl_tools_server );
use Langertha::Raider::SearchTools;
use Langertha::Raider::TodoTools;
use Langertha::Raider::AskTools;
use Langertha::Raider::PlanTools;
use Langertha::Raider::Approval;
use Langertha::Raider::Loadguard;
use Langertha::Raider::BashTools;
use Langertha::Raider::CronTools;
use Langertha::Raider::SkillTools qw( build_skill_tools_server );
use Langertha::Raider::SlashCommand;
use Langertha::Raider::Packs     qw( build_packs );
use Langertha::Raider::Config;
use Langertha::Raider::Instructions;
use Langertha::Raider::Context;
use Langertha::Raider::Detect;
use Langertha::Raider::EngineResolver;
use Langertha::Raider::Provider::Binding;
use Langertha::Raider::ToolEffects;
use Langertha::Raider::Permissions;
use Langertha::Raider::Hooks;
use Langertha::Raider::MCP;
use Langertha::Raider::MCP::Resources;
use Langertha::Raider::ToolNames;
use Langertha::Raider::SessionStore;
use Langertha::Raider::Subagent;
use Langertha::Raider::Tasks;
use Langertha::Raider::Worktree;
use Langertha::Raider::WorktreeTools;
use Langertha::Raider::Result;
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


has claude => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has context => (
  is       => 'ro',
  isa      => 'Langertha::Raider::Context',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_context',
);

sub context_class { 'Langertha::Raider::Context' }

sub _build_context {
  my ($self) = @_;
  my @profiles = $self->_skill_profiles;
  my $claude = $self->_load_yml_options->{claude};
  $claude = 1 if !defined $claude && grep { $_ eq 'claude' } @profiles;
  my $context = $self->context_class->new(
    root           => $self->root,
    bare           => $self->bare ? 1 : 0,
    force_claude   => $self->claude ? 1 : 0,
    config_claude  => $claude,
    skill_specs    => $self->skill_sources,
    want_agents_md => ( grep { $_ eq 'openai' } @profiles ) ? 1 : 0,
  );
  $context->apply_env;
  return $context;
}

# The profile keywords (claude, openai) of the skills: items of the config
# file, -o skills= and the command line.
sub _skill_profiles {
  my ($self) = @_;
  return $self->config->profiles($self->engine_name,
    @{ $self->_cli_app_options->{skills} // [] },
    $self->has_cli_skill_sources ? @{ $self->cli_skill_sources } : ());
}

sub _build_mission {
  my ($self) = @_;
  return $self->compile_mission($self->_instructions_text, $self->_tool_servers);
}


sub compile_mission {
  my ($self, $instructions, $servers, %opt) = @_;
  my $memory = $opt{memory} // 1;
  my $has_skill = grep { $_->name eq 'skill' } map { @{ $_->tools } } @$servers;
  my $listing = $self->context->skill_catalog->prompt_text;
  my $skills = $has_skill ? undef : $listing;
  my @items = ( $instructions,
    ( $memory
      ? ( grep { !defined $skills || $_ ne $skills } $self->context->prompt_items )
      : ( $has_skill && defined $listing ? $listing : () ) ),
    $self->_tools_text($servers, $opt{working_directory}) );

  my @pack_texts = $memory ? $self->packs->skill_texts : ();
  push @items, "Active packs:\n\n".join("\n\n", @pack_texts)."\n" if @pack_texts;

  return join "\n\n---\n", @items;
}

# The instructions item: the -M text, or the default persona with the
# project instructions file (.raider/instructions.md, else .raider.md).
sub _instructions_text {
  my ($self) = @_;
  return $self->_explicit_mission if $self->_has_explicit_mission;
  my $base = $self->claude_persona_off ? $self->claude_base_text : $self->_persona_text;
  return $base if $self->bare;
  my $instructions = $self->instructions;
  my $custom = $instructions->text;
  $base .= "\n\n---\nUser's custom instructions (from ".$instructions->file."):\n\n$custom\n"
    if defined $custom;
  return $base;
}

sub instructions_text { $_[0]->_instructions_text }


# The tool description item, derived from the tool servers mounted for
# this raider (ADR 0005) -- the same servers the catalogue comes from; -M
# never replaces it (ADR 0014). A subagent passes its own servers.
sub _tools_text {
  my ($self, $servers, $working_directory) = @_;
  my @tools = map { @{ $_->tools } } @{ $servers // $self->_tool_servers };
  return 'Working directory: '.( $working_directory // $self->working_root )."\n\n"
    ."Tools (MCP):\n"
    .join('', map { '  - '.$self->_tool_signature($_)."\n" } @tools);
}

# The MCP::Tool objects of the mounted tool servers, in mount order --
# what the prompt describes, the engine offers and Langertha::Raider::Skill
# documents.
sub _mounted_tools { map { @{ $_->tools } } @{ $_[0]->_tool_servers } }

sub mounted_tools { $_[0]->_mounted_tools }


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


sub claude_persona_off { $_[0]->context->mode eq 'claude' ? 1 : 0 }

sub claude_base_text { <<'EOM' }
You are an interactive agent that helps users with software engineering
tasks. Use the instructions below and the tools available to you to assist
the user. Project and user instructions (CLAUDE.md) override these defaults
where they conflict.

How you work:
  - The user's turn is the task. Pursue it with tools until it is done.
  - Read a file before you change it. Do not guess file contents.
  - After you write or edit a file, verify: re-read it, or run a check
    (syntax check, tests).
  - Prefer small targeted edits to full rewrites.
  - bash is a full shell, not a sandbox. Do not run irreversible operations
    (rm -rf, git reset --hard, force pushes) unless the user asks for them.
  - When the task is done, reply in plain text. The user answers in the next
    turn.
EOM

# Points at the instructions file in use (.raider.md in a legacy project,
# CLAUDE.md in a Claude project, both when a raider project reads the
# Claude layout).
sub _persona_body {
  my ($self) = @_;
  my $label = $self->_instructions_label;
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

sub _instructions_label {
  my ($self) = @_;
  my $label = $self->instructions->label;
  return $label if $self->bare || !$self->context->claude_layout;
  return $label.' or CLAUDE.md';
}


has root => (
  is      => 'ro',
  isa     => 'Str',
  default => sub { Path::Tiny->cwd->stringify },
);


has working_root => (
  is       => 'ro',
  isa      => 'Str',
  init_arg => undef,
  lazy     => 1,
  default  => sub { $_[0]->root },
  writer   => '_set_working_root',
);

has worktree_session => (
  is       => 'ro',
  isa      => 'Maybe[HashRef]',
  init_arg => undef,
  writer   => '_set_worktree_session',
);

# The mission names the working root: compiled again before the next run
# once it moved (ADR 0032 §3).
has _mission_stale => (is => 'rw', isa => 'Bool', default => 0, init_arg => undef);

# The default names of enter_worktree: session-N, counted per application.
has _worktree_counter => (is => 'rw', isa => 'Int', default => 0, init_arg => undef);

# The servers of the root-bound tools for the working root while it is not
# the root: { root => DIR, files => S, search => S, perl => S }.
has _working_servers => (is => 'ro', isa => 'HashRef', init_arg => undef, default => sub { {} });


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


has max_agent_depth => (
  is         => 'ro',
  isa        => 'Int',
  lazy_build => 1,
);

sub _build_max_agent_depth { $_[0]->_max_agent_depth_source->{value} }

# Where max_agent_depth comes from (ADR 0027 section 8): { value, source,
# ignored => [ { key, reason }, ... ] } -- source 'config', 'env NAME' or
# 'default'; ignored lists the values that did not fit.
sub _max_agent_depth_source {
  my ($self) = @_;
  my @ignored;
  my $depth = $self->_load_yml_options->{max_agent_depth};
  if (defined $depth) {
    return { value => 0 + $depth, source => 'config', ignored => [] }
      if !ref $depth && $depth =~ /\A\d+\z/;
    push @ignored, { key => 'max_agent_depth', reason => 'not a non-negative integer' };
  }
  my $var = 'CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH';
  my $claude = $self->context->claude_layout;   # builds the context: settings env applied
  my $env = $ENV{$var};
  if ($claude && defined $env && length $env) {
    return { value => 0 + $env, source => 'env '.$var, ignored => \@ignored }
      if $env =~ /\A\d+\z/ && $env > 0;
    push @ignored, { key => 'env '.$var, reason => 'not a positive integer' };
  }
  return { value => 3, source => 'default', ignored => \@ignored };
}

has max_concurrent_agents => (
  is         => 'ro',
  isa        => 'Int',
  lazy_build => 1,
);

sub _build_max_concurrent_agents { $_[0]->_max_concurrent_agents_source->{value} }

# Where max_concurrent_agents comes from (ADR 0027 section 9), in the shape
# of _max_agent_depth_source.
sub _max_concurrent_agents_source {
  my ($self) = @_;
  my @ignored;
  my $limit = $self->_load_yml_options->{max_concurrent_agents};
  if (defined $limit) {
    return { value => 0 + $limit, source => 'config', ignored => [] }
      if !ref $limit && $limit =~ /\A\d+\z/ && $limit > 0;
    push @ignored, { key => 'max_concurrent_agents', reason => 'not a positive integer' };
  }
  my $var = 'CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS';
  my $claude = $self->context->claude_layout;   # builds the context: settings env applied
  my $env = $ENV{$var};
  if ($claude && defined $env && length $env) {
    return { value => 0 + $env, source => 'env '.$var, ignored => \@ignored }
      if $env =~ /\A\d+\z/ && $env > 0;
    push @ignored, { key => 'env '.$var, reason => 'not a positive integer' };
  }
  return { value => 20, source => 'default', ignored => \@ignored };
}

has agent_models => (
  is         => 'ro',
  isa        => 'HashRef',
  lazy_build => 1,
);

sub _build_agent_models {
  my ($self) = @_;
  my $models = $self->_load_yml_options->{agent_models};
  return ref $models eq 'HASH' ? { %$models } : {};
}


sub worktree_base_ref {
  my ($self) = @_;
  my $value;
  if ($self->context->claude_layout) {
    my $settings = $self->context->settings;
    my $entry = $settings ? $settings->worktree_base_ref : undef;
    $value = $entry ? $entry->{value} : undef;
  }
  else {
    $value = $self->_load_yml_options->{worktree_base_ref};
  }
  return defined $value && !ref $value && $value eq 'head' ? 'head' : 'fresh';
}

sub worktrees_dir {
  my ($self, $top) = @_;
  return path($top)->child( $self->context->claude_layout ? '.claude' : '.raider', 'worktrees' )->stringify;
}


has _meta_notes => (is => 'ro', isa => 'ArrayRef', init_arg => undef, default => sub { [] });

sub note_meta {
  my ($self, $text) = @_;
  push @{ $self->_meta_notes }, $text;
  return;
}

sub take_meta_notes { splice @{ $_[0]->_meta_notes } }


has leaving => (is => 'ro', isa => 'Bool', init_arg => undef, default => 0, writer => '_set_leaving');


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


has on_ask_user => (
  is        => 'rw',
  isa       => 'Maybe[CodeRef]',
  predicate => 'has_on_ask_user',
);


has on_permission_request => (
  is        => 'rw',
  isa       => 'Maybe[CodeRef]',
  predicate => 'has_on_permission_request',
);


has on_plan_review => (
  is        => 'rw',
  isa       => 'Maybe[CodeRef]',
  predicate => 'has_on_plan_review',
);


has permission_mode => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  predicate => 'has_permission_mode',
);


has skip_permissions => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has permissions => (
  is         => 'ro',
  isa        => 'Langertha::Raider::Permissions',
  lazy_build => 1,
);

sub permissions_class { 'Langertha::Raider::Permissions' }

# The session rules a policy read again (reload_permissions) keeps.
has _permissions_session_rules => (is => 'rw', isa => 'ArrayRef', writer => '_set_permissions_session_rules', init_arg => undef);

sub _build_permissions {
  my ($self) = @_;
  my $settings = $self->context->settings;
  my $cli = $self->skip_permissions
    ? { value => 'bypassPermissions', source => $self->source_label('skip_permissions') }
    : $self->has_permission_mode && defined $self->permission_mode
      ? { value => $self->permission_mode, source => $self->source_label('permission_mode') }
      : undef;
  my $wt = $self->worktree_session;
  return $self->permissions_class->from_sources(
    root     => $self->working_root,
    ( $wt ? ( worktree_isolation => { top => $wt->{top}, worktree => $wt->{path} } ) : () ),
    cli_mode => $cli,
    ( $self->_permissions_session_rules ? ( session_rules => $self->_permissions_session_rules ) : () ),
    sources  => [ $self->config->permissions, ( $settings ? $settings->permissions : () ) ],
    source_servers => $self->configured_mcp->source_servers,   # configured MCP servers are foreign (ADR 0029)
    # Claude layout: the file tools reach outside the root, the gate asks (ADR 0023).
    ask_outside_roots => ( $self->context->mode eq 'claude' ? 1 : 0 ),
  );
}


sub set_permission_mode {
  my ($self, $mode, $why, %o) = @_;
  my $from = $self->permissions->set_mode($mode, $why);
  $self->_mode_set_at_runtime(1);
  $self->event('permission.mode', from => $from, to => $mode, why => $why // 'session',
    defined $o{call} ? ( call => $o{call} ) : ());
  # Entering plan mode mounts exit_plan_mode for the next request.
  if ($mode eq 'plan' && !$self->_plan_mode_seen) {
    $self->_plan_mode_seen(1);
    if    ($self->_has_raider)       { $self->reload_mission }
    elsif ($self->_has_tool_servers) { $self->_remount_tool_servers }
  }
  return $from;
}

has _mode_set_at_runtime => (is => 'rw', isa => 'Bool', default => 0, init_arg => undef);


sub reload_permissions {
  my ($self) = @_;
  return unless $self->has_permissions;
  my $old = $self->permissions;
  my $config = $self->config;
  $config->$_ for qw( clear_file clear_uses_home clear_data clear_home_data );
  $self->_set_permissions_session_rules($old->session_rules);
  $self->clear_permissions;
  my $new = $self->permissions;
  $new->set_mode($old->mode, $old->mode_source) if $self->_mode_set_at_runtime;
  return $new;
}


sub tool_gate {
  my ($self, %for) = @_;
  weaken(my $app = $self);
  return sub {
    return { verdict => 'deny', reason => 'the application is gone' } unless $app;
    my $verdict = $app->_permission_gate($_[1], %for);
    $app->_note_plan_call($_[1]) if !%for && $verdict->{verdict} eq 'allow';
    return $verdict;
  };
}

# The id of the main run's enter_plan_mode or exit_plan_mode call the gate
# just let run, by tool name: its handler (_enter_plan_mode,
# _exit_plan_mode) gets no call context, and names the call in its
# permission.* events with it (ADR 0034).
has _plan_calls => (is => 'ro', isa => 'HashRef', init_arg => undef, default => sub { {} });

sub _note_plan_call {
  my ($self, $call) = @_;
  my $name = $call->{name} // '';
  $self->_plan_calls->{$name} = $call->{call}
    if defined $call->{call} && $name =~ /\A(?:enter|exit)_plan_mode\z/;
  return;
}

sub _take_plan_call {
  my ($self, $name) = @_;
  my $id = delete $self->_plan_calls->{$name};
  return defined $id ? ( call => $id ) : ();
}

# The tool gate of the raider (ADR 0005, ADR 0021): the policy decides; an
# ask without anyone to approve it is refused with a reason that says how to
# allow it. Emits permission.denied for every call that does not run. %for
# is what tool_gate got: policy, on_event, binding. The model reads Claude
# Code's sentence first, then raider's reason (ADR 0026).
sub _permission_gate {
  my ($self, $call, %for) = @_;
  my $policy = $for{policy} // $self->permissions;
  # A run in a worktree does not edit the main checkout (ADR 0032 §3): before any rule or mode.
  if (defined(my $refusal = $policy->main_checkout_refusal($call))) {
    my $verdict = { verdict => 'deny', by => 'worktree', reason => $refusal, mode => $policy->mode };
    $self->_permission_event(\%for, 'permission.denied', $call, $verdict, by => 'worktree');
    return { %$verdict, message => $refusal };
  }
  my $verdict = $self->_with_hook_decision($call, $policy->decide($call));
  # A worktree outside raider's own directories: always asked, only
  # bypassPermissions skips it (ADR 0032 §4).
  if ($verdict->{verdict} ne 'deny' && $policy->mode ne 'bypassPermissions'
      && defined( my $question = $self->_worktree_path_question($call, $policy) )) {
    $verdict = { verdict => 'ask', by => 'worktree', reason => $question, mode => $policy->mode, once_only => 1 };
  }
  return $verdict if $verdict->{verdict} eq 'allow';
  if ($verdict->{verdict} eq 'deny') {
    $self->_permission_event(\%for, 'permission.denied', $call, $verdict, by => $verdict->{by});
    return { %$verdict, message => $self->_denied_text($call, $verdict->{reason}) };
  }
  my $unattended = $for{unattended} ? $for{unattended}->() : undef;
  if (!defined $unattended && (my $ask = $self->on_permission_request)) {
    return $self->_ask_permission($ask, $call, $verdict, \%for);
  }
  # A hook that asks is not lifted by a rule; there is nothing to configure.
  # Neither is the question about a worktree, which only bypassPermissions skips.
  my $by = $verdict->{by} // '';
  my $reason = $verdict->{reason}.'; nobody can approve it'.( defined $unattended ? ': '.$unattended : ' in this run' ).'. '
    .( $by eq 'hook' ? '' : $by eq 'worktree' ? 'Only --permission-mode bypassPermissions skips this question. '
      : $self->_how_to_allow($call, $policy).' ' )
    .'Do not retry the same call; go on without it or say what you need.';
  $self->_permission_event(\%for, 'permission.denied', $call, $verdict, by => 'noninteractive', reason => $reason);
  return { %$verdict, verdict => 'deny', by => 'noninteractive', reason => $reason,
    message => $self->_denied_text($call, $reason) };
}

# Claude Code's words for a call that is refused without the person saying
# no -- "Permission to use Bash with command CMD has been denied." -- with the
# tool named as the model knows it, then raider's reason.
sub _denied_text {
  my ($self, $call, $reason) = @_;
  my $name = $call->{name} // '';
  my $command = ref $call->{arguments} eq 'HASH' ? $call->{arguments}{command} : undef;
  my $text = 'Permission to use '.$name
    .( $name eq 'bash' && defined $command && !ref $command ? ' with command '.$command : '' )
    .' has been denied.';
  return $text unless defined $reason && length $reason;
  return $text.' Reason: '.$reason.( $reason =~ /[.!?]\z/ ? '' : '.' );
}

# Claude Code's words for a call the person said no to; the reason they gave
# follows as Claude Code puts it (ADR 0026).
sub _rejected_text {
  my ($self, $why) = @_;
  my $text = "The user doesn't want to proceed with this tool use. The tool use was rejected "
    .'(eg. if it was a file edit, the new_string was NOT written to the file). ';
  return $text.'To tell you how to proceed, the user said:'."\n".$why if defined $why && length $why;
  return $text.'STOP what you are doing and wait for the user to tell you how to proceed.';
}

# Puts a call the policy asks about to the person (on_permission_request):
# once -> an approval of exactly this call; session -> the suggested rule as
# a session rule; no -> refused with the person's reason.
sub _ask_permission {
  my ($self, $ask, $call, $verdict, $for) = @_;
  $for //= {};
  my $policy = $for->{policy} // $self->permissions;
  # A question no rule can answer (once_only) offers no rule for the session.
  my $rule   = $verdict->{once_only} ? undef : $policy->suggest_rule($call);
  $self->_permission_event($for, 'permission.asked', $call, $verdict, ( defined $rule ? ( suggested_rule => $rule ) : () ));
  my $answer = $ask->({
    tool      => $call->{name},
    source    => $call->{source},
    arguments => $call->{arguments},
    reason    => $verdict->{reason},
    rule      => $rule,
  });
  my $choice = ref $answer eq 'HASH' ? $answer->{answer} // 'no' : 'no';
  my @call_id = defined $call->{call} ? ( call => $call->{call} ) : ();
  if ($choice eq 'session' && defined $rule) {
    $policy->add_session_rule($rule);
    my $again = $policy->decide($call);
    if ($again->{verdict} eq 'allow') {
      $self->_gate_event($for, 'permission.granted', tool => $call->{name}, @call_id, scope => 'session', rule => $rule, mode => $policy->mode);
      return $again;
    }
    $choice = 'once';   # the rule does not cover the call after all: this call only
  }
  if ($choice eq 'once' || $choice eq 'session') {
    my %binding  = $self->_approval_binding($for);
    my $approval = Langertha::Raider::Approval->for_call(%binding, call => $call);
    # The approval binds this exact call; held against it as it is about to run.
    if ($approval->covers($self->_approval_binding($for), call => $call)) {
      $self->_gate_event($for, 'permission.granted', tool => $call->{name}, @call_id, scope => 'once', mode => $policy->mode);
      return { verdict => 'allow', by => 'user', reason => 'approved once by the user', mode => $policy->mode };
    }
  }
  my $why = ref $answer eq 'HASH' ? $answer->{reason} : undef;
  my $text = $self->_rejected_text($why);
  $self->_permission_event($for, 'permission.denied', $call, $verdict, by => 'user', reason => $text);
  return { %$verdict, verdict => 'deny', by => 'user', reason => $text, message => $text };
}

# Session, run and policy revision an approval is bound to. A run without a
# session (a library run, --no-session) has a stable stand-in per
# application, so Approval->for_call never lacks a field. A sub-run's
# binding (tool_gate binding) names its own session and run.
sub _approval_binding {
  my ($self, $for) = @_;
  $for //= {};
  my $policy = $for->{policy} // $self->permissions;
  my %own = $for->{binding} ? $for->{binding}->() : ();
  my $run = $self->_run;
  my $session = $run ? $run->{session} : undef;
  return (
    session_id      => $own{session_id} // ( $session ? $session->id : $self->_local_session_id ),
    run_id          => $own{run_id} // ( $run && defined $run->{run} ? $run->{run} : 'run' ),
    policy_revision => $policy->policy_revision,
  );
}

has _local_session_id => (is => 'ro', isa => 'Str', lazy => 1, builder => '_build__local_session_id', init_arg => undef);

sub _build__local_session_id { 'local-'.$$.'-'.refaddr($_[0]) }

# How a person allows a call that asked: a rule (the suggested one) in a
# config file, or a mode.
sub _how_to_allow {
  my ($self, $call, $policy) = @_;
  $policy //= $self->permissions;
  my $rule = $policy->suggest_rule($call);
  my @files = ( '.raider/config.yml (permissions: allow:)',
    ( $self->context->claude_layout ? '.claude/settings.json (permissions.allow)' : () ) );
  # A path outside the root: acceptEdits does not reach it, an additional directory does (ADR 0023).
  my $outside = $policy->ask_outside_roots && $policy->outside_paths($call) ? 1 : 0;
  return 'To allow it, add '.( defined $rule ? "a rule such as '".$rule."'" : 'an allow rule' )
    .' to '.join(' or ', @files)
    .( $outside ? ', add the directory to additionalDirectories (additional_directories)' : '' )
    .', or run raider with --permission-mode '
    .( !$outside && ( $call->{name} // '' ) =~ /\A(?:write_file|edit_file|multi_edit)\z/ ? 'acceptEdits' : 'bypassPermissions' ).'.';
}

sub _permission_event {
  my ($self, $for, $type, $call, $verdict, %more) = @_;
  $self->_gate_event($for, $type,
    tool => $call->{name},
    # The call's id within the raid (ADR 0034), as on its tool.call.
    ( defined $call->{call} ? ( call => $call->{call} ) : () ),
    ( defined $call->{source} ? ( tool_source => $call->{source} ) : () ),
    mode => $verdict->{mode},
    ( defined $verdict->{rule} ? ( rule => $verdict->{rule} ) : () ),
    ( defined $verdict->{source} ? ( source => $verdict->{source} ) : () ),
    reason => $verdict->{reason},
    %more,
  );
  return;
}

# A PreToolUse hook's allow or ask (the call's 'hook', ADR 0022) weighed
# against the policy's verdict as Claude Code weighs them: hook decisions
# never bypass permission rules. A deny -- by a rule, by plan mode -- stays.
# allow lifts only an ask of the mode (the prompt), never an ask rule. ask
# turns an allow (by a rule or the mode) into an ask.
sub _with_hook_decision {
  my ($self, $call, $verdict) = @_;
  my $hook = $call->{hook};
  return $verdict unless ref $hook eq 'HASH' && defined $hook->{decision};
  return $verdict if $verdict->{verdict} eq 'deny';
  my $why = $hook->{reason};
  if ($hook->{decision} eq 'allow') {
    return $verdict unless $verdict->{verdict} eq 'ask' && ( $verdict->{by} // '' ) eq 'mode';
    return { %$verdict, verdict => 'allow', by => 'hook', reason => $why // 'allowed by a PreToolUse hook' };
  }
  if ($hook->{decision} eq 'ask' && $verdict->{verdict} eq 'allow') {
    return { %$verdict, verdict => 'ask', by => 'hook', reason => $why // 'a PreToolUse hook asks before this call' };
  }
  return $verdict;
}


has hooks => (
  is         => 'ro',
  isa        => 'Maybe[Langertha::Raider::Hooks]',
  init_arg   => undef,
  lazy_build => 1,
);

sub hooks_class { 'Langertha::Raider::Hooks' }

sub _build_hooks {
  my ($self) = @_;
  return unless $self->context->claude_layout;
  weaken(my $app = $self);
  return $self->hooks_class->from_context($self->context,
    loop       => $self->loop,
    if_matcher => sub { $app ? $app->permissions->rule_matches(@_) : undef },
    # Subagents are briefed by raider itself (ADR 0020 section 6): the briefing
    # plugin's briefing-preload must not load the skills a second time.
    native_briefing => 1,
  );
}

sub tool_hook {
  my ($self, %for) = @_;
  weaken(my $app = $self);
  return sub { $app ? $app->_pre_tool_use_f($_[1], %for) : Future->done({}) };
}

# The common fields of every hook input: the session (its journal is the
# transcript -- raider's JSONL, not Claude Code's format) and the mode.
sub _hook_input {
  my ($self, %more) = @_;
  my $run = $self->_run;
  my $session = $run ? $run->{session} : undef;
  return {
    session_id      => $session ? $session->id : $self->_local_session_id,
    ( $session ? ( transcript_path => ''.$session->path ) : () ),
    permission_mode => $self->permissions->mode,
    cwd             => $self->working_root,
    %more,
  };
}

# Waits on the loop for a hook future, as run() waits for a raid.
sub _await_hooks {
  my ($self, $f) = @_;
  $self->loop->await($f);
  return $f->get;
}

# PreToolUse for the canonical call of the raider (see tool_hook); %for is
# what tool_hook got: input, on_event, on_stop.
sub _pre_tool_use_f {
  my ($self, $call, %for) = @_;
  my $hooks = $self->hooks;
  return Future->done({}) unless $hooks && $hooks->has_hooks('PreToolUse');
  weaken(my $app = $self);
  return $hooks->run_f( PreToolUse => $self->_hook_input(
    ( $for{input} ? $for{input}->() : () ),
    tool_name  => $call->{name},
    tool_input => $call->{arguments},
  ), tool_source => $call->{source} )->then(sub {
    my ( $r ) = @_;
    return Future->done({}) unless $app;
    $app->_report_hooks($r, $for{on_event}, call => $call->{call});
    $app->_hook_stopped($for{on_stop}) if $r->stopped;
    my $arguments = $r->updated_input;
    if (defined( my $context = $r->context )) {
      my $key = refaddr( $arguments // $call->{arguments} );
      $app->_tool_hook_context->{$key} = $app->_hook_tag($r->event, $call->{name}).' hook additional context: '.$context;
    }
    my $decision = $r->decision;
    return Future->done({
      decision  => $decision,
      reason    => defined $decision ? 'PreToolUse hook: '.( $r->reason // $decision ) : undef,
      # A deny is worded as Claude Code words it (Hooks::Result->deny_message).
      ( $decision // '' ) eq 'deny' ? ( message => $r->deny_message // $app->_hook_tag($r->event, $call->{name}).' hook blocked the tool call' ) : (),
      arguments => $arguments,
    });
  });
}

# PreToolUse context waiting for its call's result, by the arguments hash
# the raider runs the call with (taken by the ClaudeHooks plugin).
has _tool_hook_context => (is => 'ro', isa => 'HashRef', init_arg => undef, default => sub { {} });

sub _take_tool_hook_context {
  my ($self, $arguments) = @_;
  return unless ref $arguments;
  return delete $self->_tool_hook_context->{ refaddr($arguments) };
}

# 'PostToolUse:Bash' -- the event with the tool's Claude name, as Claude Code
# labels hook output.
sub _hook_tag {
  my ($self, $event, $tool) = @_;
  return $event unless defined $tool;
  return $event.':'.( Langertha::Raider::ToolNames->claude_name($tool) // $tool );
}

# A continue: false of a tool hook: the sub-run's on_stop, else the run is
# cancelled.
sub _hook_stopped {
  my ($self, $on_stop) = @_;
  return $on_stop->() if $on_stop;
  return $self->cancel_run(reason => 'hook_stopped');
}

# Every hook of a result as hook.ran, its errors, systemMessages and a stop
# as hook.message (ADR 0022). stdout and stderr go into the journal cut at
# 2000 characters. To $emit (a sub-run's or the caller's stream), else to
# event. A tool hook's caller passes the call's id, 'call' of hook.ran (ADR
# 0034).
sub _report_hooks {
  my ($self, $r, $emit, %o) = @_;
  weaken(my $app = $self);
  $emit //= sub { $app->event(@_) if $app };
  my $cut = sub { my ( $s ) = @_; length $s > 2000 ? substr($s, 0, 2000).'... (cut)' : $s };
  for my $run (@{ $r->runs }) {
    $emit->('hook.ran',
      hook_event => $run->{event},
      ( defined $o{call} ? ( call => $o{call} ) : () ),
      source     => $run->{source},
      command    => $run->{command},
      outcome    => $run->{outcome},
      ( map { defined $run->{$_} ? ( $_ => $run->{$_} ) : () } qw( plugin matcher args exit duration_ms message ) ),
      ( map { defined $run->{$_} && length $run->{$_} ? ( $_ => $cut->($run->{$_}) ) : () } qw( stdout stderr ) ),
    );
  }
  $emit->('hook.message', hook_event => $r->event, kind => 'error', text => $_) for @{ $r->errors };
  $emit->('hook.message', hook_event => $r->event, kind => 'system', text => $_) for @{ $r->system_messages };
  $emit->('hook.message', hook_event => $r->event, kind => 'stopped',
    text => $r->stop_reason // 'a '.$r->event.' hook stopped the run') if $r->stopped;
  return;
}

# The SessionStart bookkeeping: the session the hooks last started for, and
# how the next one starts (startup, resume, clear).
has _hook_session        => (is => 'rw', isa => 'Maybe[Str]', init_arg => undef);
has _hook_session_source => (is => 'rw', isa => 'Maybe[Str]', init_arg => undef);
has _hook_config_reported => (is => 'rw', isa => 'Bool', default => 0, init_arg => undef);


sub note_history_cleared {
  my ($self) = @_;
  $self->_hook_session(undef);
  $self->_hook_session_source('clear');
  $self->_todo_tools->clear_tasks;
  $self->_todos([]);
  $self->_stop_conversation_agents;
  $self->close_worktree_session('clear');
  return;
}

# A new conversation (ADR 0027): the background agents of the main one are
# stopped without notifying -- nobody is left to read it -- and what waits
# for main is dropped; the run of the loop lets them end, at most two
# seconds. Background shells belong to the session: they go on, and notify.
sub _stop_conversation_agents {
  my ($self) = @_;
  return unless $self->_has_tasks;
  my $tasks = $self->tasks;
  my @agents = $tasks->running(kind => 'agent', recipient => 'main', background => 1);
  $tasks->stop($_->{id}, quiet => 1) for @agents;
  my @futures = grep { defined && !$_->is_ready } map { $_->{future} } @agents;
  if (@futures) {
    my $loop = $self->loop;
    $loop->await(Future->wait_any(
      Future->wait_all(map { $_->without_cancel } @futures),
      $loop->delay_future(after => 2),
    ));
  }
  $tasks->discard('main');
  return;
}

# Before a prompt goes to the model, in the Claude layout (ADR 0022):
# SessionStart once per session (startup, resume, clear), the results of
# async hooks of earlier turns, then UserPromptSubmit. Returns { prompt }
# -- the text with the hooks' context in front, as system-reminders -- or
# { error, reason } when a hook blocked or stopped the prompt (reason
# hook_blocked or hook_stopped, ADR 0034). With no_prompt_hook
# (a turn of notifications) UserPromptSubmit does not run.
sub _hooks_before_prompt {
  my ($self, $hooks, $text, %o) = @_;
  my @context;
  unless ($self->_hook_config_reported) {
    $self->_hook_config_reported(1);
    $self->event('hook.message', hook_event => 'config', kind => 'error', text => $_) for @{ $hooks->config_errors };
  }

  my $sid = $self->_hook_input->{session_id};
  unless (defined $self->_hook_session && $self->_hook_session eq $sid) {
    my $source = $self->_hook_session_source // 'startup';
    $self->_hook_session($sid);
    $self->_hook_session_source(undef);
    if ($hooks->has_hooks('SessionStart')) {
      my $r = $self->_await_hooks($hooks->run_f( SessionStart => $self->_hook_input(
        source => $source, ( $self->has_model ? ( model => $self->model ) : () ),
      ) ));
      $self->_report_hooks($r);
      return { error => 'A SessionStart hook stopped the session'.( defined $r->stop_reason ? ': '.$r->stop_reason : '' ),
        reason => 'hook_stopped' } if $r->stopped;
      push @context, [ 'SessionStart', $r->context ] if defined $r->context;
    }
  }

  for my $r ($hooks->take_async_results) {
    $self->_report_hooks($r);
    push @context, map { [ $r->event, $_ ] } grep { defined } $r->context, @{ $r->system_messages };
  }

  if (!$o{no_prompt_hook} && $hooks->has_hooks('UserPromptSubmit')) {
    my $r = $self->_await_hooks($hooks->run_f( UserPromptSubmit => $self->_hook_input( prompt => $text ) ));
    $self->_report_hooks($r);
    return { error => 'The prompt was blocked by a UserPromptSubmit hook'.( defined $r->reason ? ': '.$r->reason : '' ),
      reason => 'hook_blocked' } if $r->blocked;
    return { error => 'A UserPromptSubmit hook stopped the run'.( defined $r->stop_reason ? ': '.$r->stop_reason : '' ),
      reason => 'hook_stopped' } if $r->stopped;
    push @context, [ 'UserPromptSubmit', $r->context ] if defined $r->context;
  }

  return { prompt => join "\n\n",
    ( map { "<system-reminder>\n".$_->[0].' hook additional context: '.$_->[1]."\n</system-reminder>" } @context ), $text };
}


sub stop_hook_limit { 8 }

# After the model answered, in the Claude layout (ADR 0022): the Stop
# hooks. A block (decision block, exit 2) or additionalContext sends their
# feedback back as the next user message, with stop_hook_active true, at
# most stop_hook_limit times; the turns in between go into the journal as
# messages. Returns the last result.
sub _hooks_after_answer {
  my ($self, $result) = @_;
  my $hooks = $self->hooks or return $result;
  my $active = 0;
  for (my $round = 0; ; $round++) {
    return $result unless blessed $result && $result->can('is_final') && $result->is_final;
    return $result if $self->_run && $self->_run->{cancelled};
    return $result unless $hooks->has_hooks('Stop');
    my $r = $self->_await_hooks($hooks->run_f( Stop => $self->_hook_input(
      stop_hook_active       => $active ? JSON::MaybeXS->true : JSON::MaybeXS->false,
      last_assistant_message => "$result",
    ) ));
    $self->_report_hooks($r);
    return $result if $r->stopped;
    my @feedback = ( $r->blocked ? ( @{ $r->reasons } ? @{ $r->reasons } : '(no reason given)' ) : () ),
      ( defined $r->context ? $r->context : () );
    return $result unless @feedback;
    if ($round >= $self->stop_hook_limit) {
      $self->event('hook.message', hook_event => 'Stop', kind => 'error',
        text => 'Stop hooks kept the run going '.$self->stop_hook_limit.' times in a row; it ends here');
      return $result;
    }
    my $feedback = "Stop hook feedback:\n".join("\n", @feedback);
    $self->event('message', role => 'assistant', content => "$result");
    $self->event('message', role => 'user', content => $feedback, hook => 'Stop');
    $active = 1;
    $result = $self->run($feedback);
  }
}


sub shutdown_hooks {
  my ($self) = @_;
  return unless $self->has_hooks && $self->hooks;
  $self->_await_hooks($self->hooks->shutdown);
  return;
}


has configured_mcp => (
  is         => 'ro',
  isa        => 'Langertha::Raider::MCP',
  init_arg   => undef,
  lazy_build => 1,
  writer     => '_set_configured_mcp',
);

sub mcp_class        { 'Langertha::Raider::MCP' }
sub mcp_config_class { 'Langertha::Raider::MCP::Config' }

# The person's answers about project servers in this session (ADR 0029 §7),
# shared by every model the application builds.
has _mcp_session_approvals => (is => 'ro', isa => 'HashRef', init_arg => undef, default => sub { {} });

sub _build_configured_mcp { $_[0]->_new_mcp }

sub _new_mcp {
  my ($self, %more) = @_;
  weaken(my $app = $self);
  return $self->mcp_class->new(
    config    => $self->mcp_config_class->from_context($self->context, config => $self->config,
      session_approvals => $self->_mcp_session_approvals,
      bypass_approval   => ( $self->skip_permissions || ( $self->permission_mode // '' ) eq 'bypassPermissions' ) ? 1 : 0),
    loop      => $self->loop,
    %more,
    # A server announced new tools: the next iteration gathers them again.
    on_tools_changed => sub {
      my ( $server ) = @_;
      return unless $app;
      $app->_raider->_tools_dirty(1) if $app->_has_raider;
      $app->event('mcp.tools_changed', name => $server->name, scope => $server->spec->{scope});
    },
    on_status => sub {
      my ( $server ) = @_;
      return unless $app && $server->status =~ /\A(?:starting|connected|failed|stopped)\z/;
      $app->event('mcp.server', name => $server->name, scope => $server->spec->{scope},
        transport => $server->transport, status => $server->status, reason => $server->reason,
        tools => scalar( () = $server->tool_names ));
    },
  );
}

sub shutdown_mcp {
  my ($self) = @_;
  return unless $self->has_configured_mcp;
  $self->loop->await($self->configured_mcp->stop_f);
  return;
}


sub reload_mcp {
  my ($self) = @_;
  return unless $self->has_configured_mcp;
  my $old = $self->configured_mcp;
  my $new = $self->_new_mcp( previous => $old );
  my $count = @{ $old->clients };
  $new->clients;   # takes over what it keeps from $old
  $self->_set_configured_mcp($new);
  splice @{ $self->_mcps }, 0, $count, @{ $new->clients } if $self->_has_mcps;
  %{ $self->permissions->source_servers } = %{ $new->source_servers } if $self->has_permissions;
  $self->loop->await($old->stop_f);
  return $new;
}

sub reconnect_mcp {
  my ($self, $which) = @_;
  my $mcp = $self->configured_mcp;
  my @names = !defined $which || $which eq 'all' ? map { $_->name } @{ $mcp->clients } : ($which);
  my @done;
  for my $name (@names) {
    my ( $old, $new ) = $mcp->replace($name) or next;
    if ($self->_has_mcps) {
      $_ = $new for grep { refaddr $_ == refaddr $old } @{ $self->_mcps };
    }
    $self->loop->await($old->stop_f);
    $self->loop->await($new->start_f);
    push @done, $name;
  }
  return @done;
}

sub mcp_pids { $_[0]->has_configured_mcp ? $_[0]->configured_mcp->pids : () }


sub mcp_report {
  my ($self) = @_;
  my $mcp = $self->configured_mcp;
  my $config = $mcp->config;
  my $target = $config->approval_target;
  return {
    servers            => $mcp->report,
    errors             => $config->errors,
    warnings           => $config->env_warnings,
    trust              => $config->trust,
    approvals_go_to    => $target ? $target->{label} : undef,
    startup_timeout_ms => $config->startup_timeout_ms,
    tool_timeout_ms    => $config->tool_timeout_ms,
  };
}

sub mcp_notes { $_[0]->configured_mcp->notes }


sub mcp_prompts {
  my ($self) = @_;
  return [] unless $self->has_configured_mcp;
  my @out;
  for my $client (@{ $self->configured_mcp->clients }) {
    next unless $client->has_prompts;
    my $list = eval { $self->loop->await(my $f = $client->list_prompts_f); $f->get } or next;
    push @out, map { +{
      command     => 'mcp__'.$client->key.'__'.$_->{name},
      server      => $client->name,
      name        => $_->{name},
      description => $_->{description} // '',
      arguments   => [ map { +{ name => $_->{name}, required => $_->{required} ? 1 : 0 } }
                       grep { ref $_ eq 'HASH' && defined $_->{name} } @{ ref $_->{arguments} eq 'ARRAY' ? $_->{arguments} : [] } ],
    } } @$list;
  }
  return \@out;
}


sub mcp_prompt_request {
  my ($self, $command, $arguments) = @_;
  my ($key, $name) = $command =~ /\Amcp__(.+?)__(.+)\z/s or return;
  my $mcp = $self->configured_mcp;
  my ($client) = grep { defined $_->key && $_->key eq $key } @{ $mcp->clients } or return;
  $self->loop->await($client->start_f);
  return unless $client->has_prompts;
  my $listed = eval { $self->loop->await(my $f = $client->list_prompts_f); $f->get } or return;
  my ($prompt) = grep { $_->{name} eq $name } @$listed or return;
  my @declared = grep { ref $_ eq 'HASH' && defined $_->{name} } @{ ref $prompt->{arguments} eq 'ARRAY' ? $prompt->{arguments} : [] };
  my @given = split ' ', $arguments // '';
  my $usage = '/'.$command.join('', map { ' '.( $_->{required} ? $_->{name} : '['.$_->{name}.']' ) } @declared);
  return { error => 'MCP prompt '.$command.' takes '.scalar(@declared).' argument'.( @declared == 1 ? '' : 's' )
    .' (usage: '.$usage.'), got '.scalar(@given) } if @given > @declared;
  my %args;
  @args{ map { $_->{name} } @declared[0 .. $#given] } = @given if @given;
  my @missing = grep { $_->{required} && !defined $args{ $_->{name} } } @declared;
  return { error => 'Missing required argument'.( @missing == 1 ? '' : 's' ).' for MCP prompt '.$command.': '
    .join(', ', map { $_->{name} } @missing).' (usage: '.$usage.')' } if @missing;
  my $got = eval { $self->loop->await(my $f = $client->get_prompt_f($name, \%args)); $f->get };
  unless ($got) {
    my $error = ( split /\n/, ''.( $@ || 'no answer' ) )[0];
    return { error => 'MCP prompt '.$command.' failed: '.$error };
  }
  my $text = join "\n\n", grep { length } map { $self->_mcp_prompt_message_text($_) }
    grep { ref $_ eq 'HASH' } @{ ref $got->{messages} eq 'ARRAY' ? $got->{messages} : [] };
  return { error => 'MCP prompt '.$command.' returned no text' } unless length $text;
  return { prompt => '<command-message>'.$command." is running\x{2026}</command-message>\n"
    .'<command-name>/'.$command."</command-name>\n"
    .'<command-args>'.( $arguments // '' )."</command-args>\n\n".$text };
}

# The text of one prompt message: its content block (or blocks) as text.
sub _mcp_prompt_message_text {
  my ($self, $message) = @_;
  my $content = $message->{content};
  my @blocks = ref $content eq 'ARRAY' ? @$content : ( $content );
  return join "\n", grep { length } map {
    my $b = $_;
    ref $b ne 'HASH' ? ( defined $b && !ref $b ? $b : '' )
      : ( $b->{type} // '' ) eq 'text' ? ( $b->{text} // '' )
      : ( $b->{type} // '' ) eq 'resource' && ref $b->{resource} eq 'HASH'
        ? ( $b->{resource}{text} // '[resource '.( $b->{resource}{uri} // '' ).': binary content not shown]' )
      : '['.( $b->{type} // 'content' ).' content not shown]'
  } @blocks;
}

sub ask_mcp_approvals {
  my ($self, $ask) = @_;
  my $config = $self->configured_mcp->config;
  my @answers;
  for my $server ($config->pending) {
    last if ( $self->_mcp_session_approvals->{'*'} // '' ) eq 'approved';
    my $answer = $ask->($server);
    next unless defined $answer && $answer =~ /\A(?:approve|all|reject)\z/;
    my $written = $config->record_approval($server->{name}, $answer);
    push @answers, { name => $server->{name}, answer => $answer, written => $written };
  }
  $self->reload_mcp if @answers;
  return @answers;
}

# A permission.* event of the gated run: to the sub-run's on_event, else to
# the application's stream.
sub _gate_event {
  my ($self, $for, $type, %payload) = @_;
  return $for->{on_event}->($type, %payload) if $for && $for->{on_event};
  $self->event($type, %payload);
  return;
}


has loadguard => (
  is      => 'ro',
  isa     => 'Langertha::Raider::Loadguard',
  lazy    => 1,
  builder => '_build_loadguard',
);

sub _build_loadguard { Langertha::Raider::Loadguard->new }


has bash_tools => (
  is       => 'ro',
  isa      => 'Langertha::Raider::BashTools',
  lazy     => 1,
  builder  => '_build_bash_tools',
  init_arg => undef,
);

# The shell tools as asynchronous tools of a raider (ADR 0027), for the shell
# tools' own server only.
sub _shell_async_tools {
  my ($self, %caller) = @_;
  weaken(my $app = $self);
  return $self->bash_tools->async_tools(%caller, applies => sub { $app && $app->_serves_shell_tools($_[0]) });
}

sub _build_bash_tools {
  my ($self) = @_;
  weaken(my $app = $self);
  return Langertha::Raider::BashTools->new(
    loop              => $self->loop,
    # A run nobody can answer (a single prompt) watches at most 10 minutes (ADR 0031).
    unattended        => sub { $app && !$app->has_on_permission_request ? 1 : 0 },
    working_directory => $self->root,
    ( $self->has_allowed_commands ? ( allowed_commands => $self->allowed_commands ) : () ),
    validator         => $self->loadguard->validator,
    tasks             => $self->tasks,
  );
}


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
  elsif ($self->claude_persona_off) {
    # Claude mode: no persona, so no pack that is on only by default
    # (caveman); explicit and detected packs stay.
    for my $name (@{ [ @{$collection->enabled_pack_names} ] }) {
      next unless ($collection->sources->{$name}{source} // '') eq 'default';
      $collection->disable($name, layout => 'Claude mode: no packs by default');
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
  isa       => 'ArrayRef',
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
  croak 'Unknown permission mode '.$self->permission_mode.' (one of '.join(', ', $self->permissions_class->modes).')'
    if $self->has_permission_mode && defined $self->permission_mode
      && !$self->permissions_class->is_mode($self->permission_mode);
  croak 'permission_mode and skip_permissions: only one of them'
    if $self->skip_permissions && $self->has_permission_mode && defined $self->permission_mode;
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
  $self->config->normalize_bools(\%app);
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
has _skill_tool_server  => (is => 'ro', lazy => 1, builder => '_build_skill_tool_server', clearer => '_clear_skill_tool_server');
has _agent_tool_server  => (is => 'ro', lazy => 1, builder => '_build_agent_tool_server', clearer => '_clear_agent_tool_server');
has _agent_tools        => (is => 'ro', lazy => 1, builder => '_build_agent_tools', clearer => '_clear_agent_tools');

sub _build_api_key { $_[0]->engine_resolver->api_key }

sub _engine_class { $_[0]->engine_resolver->engine_class }

# The configured MCP servers (ADR 0029) lead the list, so their engine:N
# stay the same whatever raider's own servers do (_remount_tool_servers).
sub _build_mcps {
  my ($self) = @_;
  return [ @{ $self->configured_mcp->clients }, map { $self->_mcp_client($_) } @{ $self->_tool_servers } ];
}

sub _mcp_client {
  my ($self, $server) = @_;
  my $client = Net::Async::MCP->new(server => $server);
  $self->loop->add($client);
  if ($server->name eq $self->bash_tools->server->name) {
    my $clients = $self->_bash_clients;
    delete @$clients{ grep { !defined $clients->{$_} } keys %$clients };
    weaken($clients->{refaddr $client} = $client);
  }
  return $client;
}

# The MCP clients of the shell tools' server (or of a subagent's filtered
# copy of it), held weakly: the raiders' asynchronous shell tools stand in
# for those and leave a tool of the same name from any other source alone.
has _bash_clients => (is => 'ro', init_arg => undef, default => sub { {} });

# True when $mcp is a client the application made for its shell tools'
# server: the applies of the raiders' asynchronous shell tools.
sub _serves_shell_tools {
  my ($self, $mcp) = @_;
  return 0 unless ref $mcp;
  my $client = $self->_bash_clients->{refaddr $mcp};
  return $client && refaddr $client == refaddr $mcp ? 1 : 0;
}

sub _build_tool_servers {
  my ($self) = @_;
  return [
    @{ $self->_stock_tool_servers },
    ( $self->perl_tools_enabled ? $self->_perl_tool_server : () ),
    ( $self->_hall_tool_server // () ),
    ( $self->_skill_tool_server // () ),
    $self->_enter_plan_tool_server,
    ( $self->_agent_tool_server // () ),
    $self->_worktree_tool_server,
    ( $self->_plan_tool_wanted ? $self->_plan_tool_server : () ),
    ( @{ $self->configured_mcp->clients } ? $self->_mcp_resources->tool_server : () ),
  ];
}

# The resources of the configured MCP servers (ADR 0029 Addendum 1): the
# list/read tools, mounted when servers are configured, and the
# @server:uri mentions of a prompt.
has _mcp_resources => (is => 'ro', lazy => 1, builder => '_build_mcp_resources');

sub mcp_resources_class { 'Langertha::Raider::MCP::Resources' }

sub _build_mcp_resources {
  my ($self) = @_;
  weaken(my $app = $self);
  return $self->mcp_resources_class->new(
    servers => sub { $app ? $app->configured_mcp->clients : [] },
    loop    => $self->loop,
  );
}

# exit_plan_mode (ADR 0021): mounted once the application has been in plan
# mode, and kept mounted after (it then answers "not in plan mode").
# enter_plan_mode (ADR 0025): always mounted.
has _plan_mode_seen => (is => 'rw', isa => 'Bool', default => 0, init_arg => undef);
has _plan_tools => (is => 'ro', lazy => 1, builder => '_build_plan_tools');
has _plan_tool_server => (is => 'ro', lazy => 1, builder => '_build_plan_tool_server');
has _enter_plan_tool_server => (is => 'ro', lazy => 1, builder => '_build_enter_plan_tool_server');

sub _plan_tool_wanted {
  my ($self) = @_;
  $self->_plan_mode_seen(1) if $self->permissions->mode eq 'plan';
  return $self->_plan_mode_seen;
}

sub _build_plan_tools {
  my ($self) = @_;
  weaken(my $app = $self);
  return Langertha::Raider::PlanTools->new(
    handler       => sub { $app ? $app->_exit_plan_mode(@_) : ( 'the application is gone', 1 ) },
    enter_handler => sub { $app ? $app->_enter_plan_mode : ( 'the application is gone', 1 ) },
  );
}

sub _build_plan_tool_server { $_[0]->_plan_tools->server }

sub _build_enter_plan_tool_server { $_[0]->_plan_tools->enter_server }

# What enter_plan_mode answers once the gate let it run (the person agreed,
# a rule allows it, or bypassPermissions): the mode becomes plan; Claude
# Code's words, with raider's tool names.
sub _enter_plan_mode {
  my ($self) = @_;
  my @call_id = $self->_take_plan_call('enter_plan_mode');
  $self->set_permission_mode('plan', 'enter_plan_mode', @call_id) unless $self->permissions->mode eq 'plan';
  return ( "Entered plan mode. You should now focus on exploring the codebase and designing an implementation approach.\n\n"
    ."In plan mode, you should:\n"
    ."1. Thoroughly explore the codebase to understand existing patterns\n"
    ."2. Identify similar features and architectural approaches\n"
    ."3. Consider multiple approaches and their trade-offs\n"
    ."4. Use ask_user if you need to clarify the approach\n"
    ."5. Design a concrete implementation strategy\n"
    ."6. When ready, use exit_plan_mode to present your plan for approval\n\n"
    .'Remember: DO NOT write or edit any files yet. This is a read-only exploration and planning phase.', 0 );
}

# What exit_plan_mode answers: the plan put to the person (on_plan_review),
# approved -> mode default; refused -> stays in plan, an error result with
# the feedback; nobody to ask -> stays in plan, an error result: the plan is
# the final answer. In Claude Code's words where it has them (ADR 0026).
sub _exit_plan_mode {
  my ($self, $plan) = @_;
  my @call_id = $self->_take_plan_call('exit_plan_mode');
  my $mode = $self->permissions->mode;
  return ( '<tool_use_error>You are not in plan mode. To enter plan mode, call the enter_plan_mode tool first. '
    .'If your plan was already approved, continue with implementation.</tool_use_error>', 1 )
    unless $mode eq 'plan';
  my $review = $self->on_plan_review;
  return ( $self->_denied_text({ name => 'exit_plan_mode' },
    'nobody can approve the plan in this run. Stay in plan mode and give the plan as your final answer.'), 1 )
    unless $review;
  $self->event('permission.asked', tool => 'exit_plan_mode', @call_id, mode => $mode, reason => 'review of the plan');
  my $answer = $review->($plan) // {};
  if ($answer->{approve}) {
    $self->set_permission_mode('default', 'exit_plan_mode', @call_id);
    return ( 'User has approved your plan. You can now start coding. Start with updating your todo list if applicable'
      ."\n\nThe permission mode is now default.\n\n## Approved Plan:\n".( $plan // '' ), 0 );
  }
  return ( $self->_rejected_text($answer->{feedback}), 1 );
}

#### The working root: enter_worktree and exit_worktree (ADR 0032 §3-§6)


sub worktree_class       { 'Langertha::Raider::Worktree' }
sub worktree_tools_class { 'Langertha::Raider::WorktreeTools' }

has _worktree_git => (is => 'ro', init_arg => undef, lazy => 1, default => sub { $_[0]->worktree_class->new });

# enter_worktree and exit_worktree (ADR 0032 §4): tools of the main run only,
# mounted next to agent; a subagent never gets them.
has _worktree_tool_server => (is => 'ro', init_arg => undef, lazy => 1, builder => '_build_worktree_tool_server');

sub _build_worktree_tool_server {
  my ($self) = @_;
  weaken(my $app = $self);
  my $claude = $self->context->claude_layout;
  return $self->worktree_tools_class->new(
    enter_handler => sub { $app ? $app->_enter_worktree(@_) : ( 'the application is gone', 1 ) },
    exit_handler  => sub { $app ? $app->_exit_worktree(@_) : ( 'the application is gone', 1 ) },
    worktrees_dir => $claude ? '.claude/worktrees/' : '.raider/worktrees/',
    base_setting  => $claude ? 'worktree.baseRef' : 'worktree_base_ref',
  )->server;
}

# The two directories below the main checkout $top that hold the worktrees
# of raider and Claude Code: a path inside one needs no question (ADR 0032 §4).
sub _own_worktree_dirs {
  my ($self, $top) = @_;
  return map { path($top)->child($_, 'worktrees')->stringify } qw( .claude .raider );
}

# A path argument as an absolute path: relative to the root, the real path
# when it exists.
sub _worktree_abs_path {
  my ($self, $path) = @_;
  my $abs = path($path)->absolute($self->root);
  my $real = eval { $abs->realpath };
  return defined $real ? "$real" : "$abs";
}

# The question the gate puts before enter_worktree with a path outside the
# worktree directories of raider and Claude Code; nothing for any other call.
sub _worktree_path_question {
  my ($self, $call, $policy) = @_;
  return unless ( $call->{name} // '' ) eq 'enter_worktree' && $policy->is_builtin_call($call);
  my $in = ref $call->{arguments} eq 'HASH' ? $call->{arguments} : {};
  my $path = $in->{path};
  return unless defined $path && !ref $path && length $path && !defined $in->{name};
  my $top = $self->_worktree_git->repository_top($self->root);
  return if $top->{error};   # the tool itself says why it cannot
  my $abs = $self->_worktree_abs_path($path);
  my @dirs = $self->_own_worktree_dirs($top->{top});
  return if grep { index($abs, $_.'/') == 0 } @dirs;
  return 'enter_worktree would move the session into '.$abs.', which is outside '
    .join(' and ', map { $_.'/' } @dirs).'; the user is asked every time';
}

# The working root and the policy move to $root; with $wt (the worktree
# session) the policy refuses edits into the main checkout, without it it is
# back at the root. The mission is compiled again before the next run.
sub _move_working_root {
  my ($self, $root, $wt) = @_;
  $self->_set_worktree_session($wt);
  $self->_set_working_root($root);
  %{ $self->_working_servers } = ();
  $self->permissions->move_to(root => $root,
    $wt ? ( worktree_isolation => { top => $wt->{top}, worktree => $wt->{path} } ) : ());
  $self->_mission_stale(1);
  return;
}

# The same subdirectory of the worktree at $path as the root is of its
# working tree: made in a worktree this session created ($make), else the
# worktree's top when an entered one does not have it.
sub _root_in_worktree {
  my ($self, $path, $make) = @_;
  my $git = $self->_worktree_git;
  my $tree = $git->toplevel($self->root);
  return $path if $tree->{error};
  my $sub = path($self->root)->realpath->relative($tree->{top})->stringify;
  return $path if $sub eq '.' || $sub =~ m{\A\.\.(?:/|\z)};
  my $dir = path($path)->child($sub);
  $dir->mkpath if $make && !-d $dir;
  return -d $dir ? $dir->stringify : $path;
}

# worktree.entered / worktree.exited (ADR 0032 §6): into the run in
# progress, else into the session the worktree was entered in.
sub _worktree_event {
  my ($self, $wt, $type, %payload) = @_;
  $self->caller_event($wt->{session}, $type, path => $wt->{path}, branch => $wt->{branch}, %payload);
  return;
}

sub _entered_text {
  my ($self, $wt) = @_;
  return "Entered worktree at \x{201C}".$wt->{path}."\x{201D} on branch \x{201C}".( $wt->{branch} // 'HEAD' )."\x{201D}."
    .' The session is now working in the worktree. Use exit_worktree to leave mid-session; '
    .( $wt->{created}
      ? 'when the session ends it is removed if unchanged and kept otherwise.'
      : 'it was entered by path, so it stays on disk when the session ends.' );
}

# What enter_worktree answers once the gate let it run (ADR 0032 §4).
sub _enter_worktree {
  my ($self, $in) = @_;
  my $git = $self->_worktree_git;
  my $top = $git->repository_top($self->root);
  return ( 'enter_worktree needs a git repository; '.$self->root.' is not inside one.', 1 ) if $top->{error};
  return defined $in->{path} ? $self->_enter_worktree_path($in->{path}, $top->{top})
    : $self->_enter_worktree_name($in->{name}, $top->{top});
}

sub _enter_worktree_name {
  my ($self, $name, $top) = @_;
  my $git = $self->_worktree_git;
  if (my $wt = $self->worktree_session) {
    return ( 'Already working in the worktree '.$wt->{path}
      .'; pass path to switch to another one, or exit_worktree first.', 1 );
  }
  my $dir = path($self->worktrees_dir($top));
  $name //= $self->_next_worktree_name($dir, $top);
  my $path = $dir->child($name)->stringify;
  my $branch = 'worktree-'.$name;
  return ( 'Worktree '.$name.' exists; pass path to enter it.', 1 )
    if -e $path || $git->branch_exists($top, $branch);
  my $base = $git->base_ref($self->working_root, $self->worktree_base_ref);
  return ( 'enter_worktree: '.$base->{error}, 1 ) if $base->{error};
  my $tree = $git->toplevel($self->working_root);
  return ( 'enter_worktree: '.$tree->{error}, 1 ) if $tree->{error};
  my $made = $git->create(source => $tree->{top}, path => $path, branch => $branch, base => $base->{commit});
  return ( 'enter_worktree: '.$made->{error}, 1 ) if $made->{error};
  my $wt = {
    path    => $made->{path},
    branch  => $branch,
    top     => $top,
    base    => $base->{commit},
    created => 1,
    session => $self->has_run ? $self->_run->{session} : undef,
  };
  $wt->{root} = $self->_root_in_worktree($wt->{path}, 1);
  $self->_move_working_root($wt->{root}, $wt);
  $self->_worktree_event($wt, 'worktree.entered', created => JSON::MaybeXS->true);
  return ( $self->_entered_text($wt), 0 );
}

# session-N, the first N whose directory and branch are free.
sub _next_worktree_name {
  my ($self, $dir, $top) = @_;
  my $git = $self->_worktree_git;
  while (1) {
    my $n = $self->_worktree_counter + 1;
    $self->_worktree_counter($n);
    my $name = 'session-'.$n;
    return $name unless -e $dir->child($name) || $git->branch_exists($top, 'worktree-'.$name);
  }
}

sub _enter_worktree_path {
  my ($self, $path, $top) = @_;
  my $git = $self->_worktree_git;
  my $abs = $self->_worktree_abs_path($path);
  my $list = $git->list($top);
  return ( 'enter_worktree: '.$list->{error}, 1 ) if $list->{error};
  my ($entry) = grep { $self->_worktree_abs_path($_->{path}) eq $abs } @{ $list->{worktrees} };
  return ( $abs.' is not a worktree of the repository at '.$top.' (git worktree list).', 1 ) unless $entry;
  return ( $abs.' is the main checkout; pass the path of a linked worktree.', 1 ) if $entry->{main};
  my $old = $self->worktree_session;
  return ( 'Already working in the worktree '.$abs.'; nothing changed.', 0 ) if $old && $old->{path} eq $abs;
  return ( 'enter_worktree: '.$abs.' does not exist.', 1 ) unless -d $abs;
  # The worktree left behind stays on disk untouched and is no longer tracked.
  my $wt = {
    path    => $abs,
    branch  => $entry->{branch},
    top     => $top,
    created => 0,
    session => $self->has_run ? $self->_run->{session} : undef,
  };
  $wt->{root} = $self->_root_in_worktree($abs);
  $self->_move_working_root($wt->{root}, $wt);
  $self->_worktree_event($wt, 'worktree.entered', created => JSON::MaybeXS->false);
  return ( $self->_entered_text($wt), 0 );
}

# What exit_worktree answers once the gate let it run (ADR 0032 §4).
sub _exit_worktree {
  my ($self, $in) = @_;
  my $wt = $self->worktree_session or return ( 'No worktree session is active; nothing changed.', 0 );
  my $root = $self->root;
  my $branch = $wt->{branch} // 'HEAD';
  if ($in->{action} eq 'keep') {
    $self->_move_working_root($root);
    $self->_worktree_event($wt, 'worktree.exited', removed => JSON::MaybeXS->false, reason => 'exit_worktree');
    return ( 'Left the worktree '.$wt->{path}.'; it stays on branch '.$branch.'. Working directory: '.$root.'.', 0 );
  }
  return ( $wt->{path}.' was entered by path, not created by this session; use action "keep".', 1 )
    unless $wt->{created};
  my $git = $self->_worktree_git;
  unless ($in->{discard_changes}) {
    my $changes = $git->changes($wt->{path}, $wt->{base});
    return $self->_worktree_kept($wt, $changes->{error}) if $changes->{error};
    if (@{ $changes->{status} } || $changes->{commits}) {
      my $n = $changes->{commits};
      return ( join("\n", 'The worktree '.$wt->{path}.' has changes; nothing was removed.',
        ( @{ $changes->{status} } ? ( 'git status --porcelain:', @{ $changes->{status} } ) : () ),
        $n.' commit'.( $n == 1 ? '' : 's' ).' beyond its base.',
        'Pass discard_changes: true to remove it anyway.'), 1 );
    }
  }
  $self->_move_working_root($root);
  my $removed = $git->remove(dir => $wt->{top}, path => $wt->{path}, branch => $wt->{branch},
    $in->{discard_changes} ? ( force => 1 ) : ());
  return $self->_worktree_kept($wt, $removed->{error}) if $removed->{error};
  $self->_worktree_event($wt, 'worktree.exited', removed => JSON::MaybeXS->true, reason => 'exit_worktree');
  return ( 'Removed the worktree '.$wt->{path}.' and its branch '.$branch.'. Working directory: '.$root.'.', 0 );
}

# A removal git refused: the working root is back at the root, the worktree
# stays (ADR 0032 §4).
sub _worktree_kept {
  my ($self, $wt, $error) = @_;
  $self->_move_working_root($self->root) if $self->worktree_session;
  $self->_worktree_event($wt, 'worktree.exited', removed => JSON::MaybeXS->false, reason => 'exit_worktree');
  return ( 'worktree kept: '.$error.'. Working directory: '.$self->root.'.', 1 );
}


sub close_worktree_session {
  my ($self, $reason) = @_;
  my $wt = $self->worktree_session or return;
  $self->_move_working_root($self->root);
  my $removed = 0;
  if ($wt->{created}) {
    my $git = $self->_worktree_git;
    my $branch = $wt->{branch} // 'HEAD';
    my $changes = $git->changes($wt->{path}, $wt->{base});
    if ($changes->{error}) {
      $self->note_meta('worktree '.$wt->{path}.' kept on branch '.$branch.' ('.$changes->{error}.')');
    }
    elsif (@{ $changes->{status} } || $changes->{commits}) {
      $self->note_meta('worktree '.$wt->{path}.' kept on branch '.$branch.' (has changes)');
    }
    else {
      my $r = $git->remove(dir => $wt->{top}, path => $wt->{path}, branch => $wt->{branch});
      $r->{error}
        ? $self->note_meta('worktree '.$wt->{path}.' kept on branch '.$branch.' ('.$r->{error}.')')
        : ( $removed = 1 );
    }
  }
  $self->_worktree_event($wt, 'worktree.exited', removed => $removed ? JSON::MaybeXS->true : JSON::MaybeXS->false,
    reason => $reason);
  return;
}

# The tool of $name in the server of the root-bound tools of $kind (files,
# search, perl) for the working root -- nothing while the working root is
# the root, whose servers are mounted. Built once per working root.
sub _working_root_tool {
  my ($self, $kind, $name) = @_;
  my $root = $self->working_root;
  return if $root eq $self->root;
  my $cache = $self->_working_servers;
  %$cache = ( root => $root ) unless ( $cache->{root} // '' ) eq $root;
  my $server = $cache->{$kind} //= $self->_root_bound_server($kind, $root);
  my ($tool) = grep { $_->name eq $name } @{ $server->tools };
  return $tool;
}

sub _root_bound_server {
  my ($self, $kind, $root) = @_;
  return $self->_file_tools_server($self->_main_file_tools_args, root => $root) if $kind eq 'files';
  return $self->_search_tools_server(root => $root) if $kind eq 'search';
  return $self->_perl_tools_server(root => $root);
}

# The mounted server of the root-bound tools of $kind, made to follow the
# working root (ADR 0032 §3): every call of one of its tools runs the tool of
# the same name of the server for the working root at that moment. The
# server, its tools, names and schemas stay -- the engine's clients, the
# mission's tool list and /reload are not touched -- and a call already
# running finishes where it started. A subagent never gets these tools: its
# root-bound tools are its own (Langertha::Raider::Subagent).
sub _follow_working_root {
  my ($self, $server, $kind) = @_;
  weaken(my $app = $self);
  for my $tool (@{ $server->tools }) {
    my ( $here, $name ) = ( $tool->code, $tool->name );
    $tool->code(sub {
      my ( $t, @args ) = @_;
      my $there = $app ? eval { $app->_working_root_tool($kind, $name) } : undef;
      return $t->text_result($name.': the working directory '.$app->working_root.' cannot be used: '.( "$@" =~ s/\s+\z//r ), 1)
        if $app && $@;
      return $here->($t, @args) unless $there;
      local $there->{context} = $t->{context};
      return $there->code->($there, @args);
    });
  }
  return $server;
}

# The hider of the search tools: hides the files a Read deny or ask rule
# names, when there is one -- of $policy (default the application's).
sub _search_hider {
  my ($self, $policy) = @_;
  $policy //= $self->permissions;
  return unless $policy->read_rules_active;
  return sub { $policy->hides_read($_[0]) };
}


sub subagent_class { 'Langertha::Raider::Subagent' }

# The agent tools (ADR 0020 §3, ADR 0027 §5: agent, send_message) of the
# main run, at depth 0, when max_agent_depth lets it start subagents. Every
# call runs a subagent of the run in progress: its tool set, session, the
# call's id (from its context: calls of one turn run at the same time, ADR
# 0027 §9) and event stream -- caller_event, so a background agent that ends
# between runs still journals into the session it was started from.
sub _build_agent_tools {
  my ($self) = @_;
  return unless $self->max_agent_depth > 0;
  weaken(my $app = $self);
  return $self->subagent_class->agent_tools(
    app    => $self,
    depth  => 0,
    caller => sub {
      my (%ctx) = @_;
      my $session = $app->has_run ? $app->_run->{session} : undef;
      return {
        servers  => $app->_tool_servers,
        session  => $session,
        call     => $ctx{call} // $ctx{id},
        event    => sub { $app->caller_event($session, @_) if $app },
        policy   => $app->permissions,
        task_id  => undef,
        detached => 0,
        root     => $app->working_root,
      };
    },
  );
}

sub _build_agent_tool_server {
  my ($self) = @_;
  my $tools = $self->_agent_tools or return;
  return $tools->server;
}

# agent and send_message as asynchronous tools of the main raider (ADR 0027
# §9), through the agent tools mounted at the time of the call -- a reload
# builds new ones, the raider stays.
sub _async_agent_tools {
  my ($self) = @_;
  weaken(my $app = $self);
  my $via = sub {
    my ($name) = @_;
    return sub {
      my $tools = $app ? $app->_agent_tools : undef;
      return Future->done({ content => [ { type => 'text', text => 'unknown tool '.$name } ], isError => JSON::MaybeXS->true })
        unless $tools;
      return $tools->call_f($name, @_);
    };
  };
  return {
    agent        => { code => $via->('agent'), concurrent => 1 },
    send_message => { code => $via->('send_message') },
  };
}

# The foreground subagents of the main run running right now, by refaddr
# (held weakly), so cancel_run reaches them (Langertha::Raider::Subagent/run).
# Background subagents are not here: the first Ctrl-C leaves them running.
has _live_subagents => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { {} },
);

# The token ledger (ADR 0026): model => { input_tokens, output_tokens,
# cache_read_tokens, cache_write_tokens, calls }.
my @USAGE_FIELDS = qw( input_tokens output_tokens cache_read_tokens cache_write_tokens );
has _usage => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { {} },
);


has tasks => (
  is        => 'ro',
  isa       => 'Langertha::Raider::Tasks',
  init_arg  => undef,
  lazy      => 1,
  builder   => '_build_tasks',
  predicate => '_has_tasks',
);

# The model call of web_fetch's prompt (ADR 0026): the page and the
# question as one user message to web_fetch_engine, on the run's loop;
# its tokens are the event model.usage (purpose web_fetch). A Future of the
# answer text.
sub _web_fetch_answer_f {
  my ($self, $text) = @_;
  my $engine = $self->web_fetch_engine;
  weaken(my $app = $self);
  return $engine->chat_f(messages => [ { role => 'user', content => $text } ])->then(sub {
    my ($response) = @_;
    if ($app && blessed $response && $response->can('has_usage') && $response->has_usage) {
      my $usage = $response->usage;
      my %usage = (
        purpose       => 'web_fetch',
        model         => ( $response->can('model') && defined $response->model ? $response->model : $engine->chat_model ),
        input_tokens  => $usage->input_tokens,
        output_tokens => $usage->output_tokens,
        defined $usage->cached_tokens      ? ( cache_read_tokens  => $usage->cached_tokens )      : (),
        defined $usage->cache_write_tokens ? ( cache_write_tokens => $usage->cache_write_tokens ) : (),
      );
      $app->note_usage(%usage);
      $app->event('model.usage', %usage);
    }
    return Future->done("$response");
  });
}


has web_fetch_engine => (is => 'ro', lazy => 1, builder => '_build_web_fetch_engine', init_arg => undef);

sub _build_web_fetch_engine {
  my ($self) = @_;
  my $model = $self->_load_yml_options->{web_fetch_model};
  return $self->_engine unless defined $model && !ref $model && length $model;
  my $resolver = $self->engine_resolver;
  return $resolver->meta->clone_object($resolver, model => $model)->build_engine;
}


has scheduling => (
  is      => 'rw',
  isa     => 'Bool',
  default => 0,
);


has cron_tools => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CronTools',
  lazy     => 1,
  builder  => '_build_cron_tools',
  init_arg => undef,
);

sub _build_cron_tools {
  my ($self) = @_;
  return Langertha::Raider::CronTools->new( loop => $self->loop, tasks => $self->tasks, recipient => $self->cron_queue );
}

# The queue of the task registry the prompts of due cron jobs wait in (not
# main: they are no notifications, a turn in progress does not take them).
sub cron_queue { 'cron' }

# True when the cron tools are mounted (ADR 0031).
sub _cron_wanted {
  my ($self) = @_;
  return $self->scheduling && !( $ENV{CLAUDE_CODE_DISABLE_CRON} && $ENV{CLAUDE_CODE_DISABLE_CRON} !~ /\A(?:0|false|no|off)?\z/i ) ? 1 : 0;
}

sub tasks_class { 'Langertha::Raider::Tasks' }

sub _build_tasks {
  my ($self) = @_;
  return $self->tasks_class->new(loop => $self->loop);
}


sub caller_event {
  my ($self, $session, $type, %payload) = @_;
  return $self->event($type, %payload) if $self->has_run;
  $self->record($session, $type, %payload) if $session && $session->is_open && $self->is_journal_type($type);
  $self->on_event->($type, %payload) if $self->has_on_event;
  return;
}


sub background_running {
  my ($self) = @_;
  return 0 unless $self->_has_tasks;
  my $tasks = $self->tasks;
  return scalar( $tasks->running(kind => 'agent', recipient => 'main', background => 1) )
    + scalar( $tasks->running(kind => 'monitor', recipient => 'main') );
}

sub scheduled_pending {
  my ($self) = @_;
  return 0 unless $self->_has_tasks;
  return $self->tasks->pending($self->cron_queue);
}

sub take_scheduled {
  my ($self) = @_;
  return unless $self->_has_tasks;
  return $self->tasks->take($self->cron_queue);
}

sub idle_pending {
  my ($self) = @_;
  return $self->notifications_pending + $self->scheduled_pending;
}

sub idle_wait_f {
  my ($self) = @_;
  my $tasks = $self->tasks;
  return Future->wait_any( $tasks->wait_f('main'), $tasks->wait_f($self->cron_queue) );
}

sub notifications_pending {
  my ($self) = @_;
  return 0 unless $self->_has_tasks;
  return $self->tasks->pending('main');
}

sub take_notifications {
  my ($self) = @_;
  return unless $self->_has_tasks;
  return $self->tasks->take('main');
}

sub wait_for_notifications {
  my ($self) = @_;
  my $tasks = $self->tasks;
  $self->loop->await($tasks->wait_f('main')) while !$tasks->pending('main') && $self->background_running;
  return $tasks->pending('main');
}

# Takes what waits for the main conversation as user messages (journaled,
# a notification with notification 1); returns their texts. The app's
# raider asks before each model request but the first of a raid
# (Langertha::Raider/on_iteration).
sub _take_main_messages {
  my ($self) = @_;
  return unless $self->_has_tasks;
  my @texts;
  for my $m ($self->tasks->take_messages('main')) {
    $self->event('message', role => 'user', content => $m->{content}, ( $m->{notification} ? ( notification => 1 ) : () ));
    push @texts, $m->{content};
  }
  return @texts;
}

# True once something waits for the main conversation; while nothing does
# but background subagents of it run, runs the loop for them. False when
# neither, or once the run is cancelled.
sub _wait_main_messages {
  my ($self) = @_;
  my $tasks = $self->tasks;
  while (1) {
    return 1 if $tasks->pending('main');
    return 0 unless $self->background_running;
    $self->loop->await($self->_raider->_until_cancelled($tasks->wait_f('main')));
    return 0 if $self->run_cancelled;
  }
}

# A run that would end while background subagents of it run (ADR 0027
# section 3, a non-interactive run): waits for them, goes on with their
# notifications as the next message, until an answer leaves none.
sub _await_background {
  my ($self, $result) = @_;
  while (1) {
    return $result unless blessed $result && $result->can('is_final') && $result->is_final;
    return $result if $self->run_cancelled;
    unless ($self->_wait_main_messages) {
      return $self->run_cancelled ? Langertha::Raider::Result->cancelled('Cancelled') : $result;
    }
    $self->event('message', role => 'assistant', content => "$result");
    $result = $self->run($self->_take_main_messages);
    $result = $self->_hooks_after_answer($result);
  }
}


sub stop_background {
  my ($self, $grace) = @_;
  return 0 unless $self->_has_tasks;
  $self->_set_leaving(1);
  my @futures = $self->tasks->stop_all or return 0;
  my $loop = $self->loop;
  $loop->await(Future->wait_any(
    Future->wait_all(map { $_->without_cancel } @futures),
    $loop->delay_future(after => $grace // 2),
  ));
  return scalar @futures;
}

# The application going away cancels what still runs (ADR 0027 section 3).
sub DEMOLISH {
  my ($self, $in_global_destruction) = @_;
  return if $in_global_destruction || !$self->_has_tasks;
  $self->tasks->stop_all;
  return;
}

# The skill tool (ADR 0019 §4), when the context lists a skill; it renders
# through slash_renderer (ADR 0030 §2).
sub _build_skill_tool_server {
  my ($self) = @_;
  return unless $self->context->skill_tool_wanted;
  weaken(my $app = $self);
  return build_skill_tools_server(
    skills => $self->context->skill_catalog,
    render => sub { $app ? $app->skill_tool_text(@_) : { error => 'the application is gone' } },
  );
}


sub slash_command_class { 'Langertha::Raider::SlashCommand' }

sub slash_renderer {
  my ( $self, %o ) = @_;
  my $session  = $o{session};
  my $settings = $self->context->settings;
  return $self->slash_command_class->new(
    root          => $self->root,
    permissions   => $self->permissions,
    validator     => $self->loadguard->validator,
    session_id    => $session ? $session->id : undef,
    disable_shell => $settings && $settings->disable_skill_shell_execution ? 1 : 0,
  );
}


sub slash_run_request {
  my ( $self, $name, $arguments, %o ) = @_;
  my $catalog = $self->context->skill_catalog;
  my $entry = ref $name eq 'HASH' ? $name : $catalog->find_user_invocable($name);
  return unless $entry;
  my $session = ref $o{session} eq 'CODE' ? $o{session}->() : $o{session};
  my $renderer = $self->slash_renderer( session => $session );
  my $r = $renderer->render(
    entry        => $entry,
    body         => $catalog->body( $entry->{name} ),
    arguments    => $arguments,
    attach_files => 1,
  );
  return { error => $r->{error} } if defined $r->{error};
  my $model = ref $entry->{frontmatter} eq 'HASH' ? $entry->{frontmatter}{model} : undef;
  ( my $text = $r->{text} ) =~ s/\s+\z//;
  return {
    prompt => '<command-message>'.$entry->{name}." is running\x{2026}</command-message>\n"
      .'<command-name>/'.$entry->{name}."</command-name>\n"
      .'<command-args>'.( $arguments // '' )."</command-args>\n\n"
      .$text,
    allow_rules  => [ $renderer->allowed_tool_rules($entry) ],
    allow_source => $renderer->grant_source($entry),
    ( defined $model && !ref $model && length $model ? ( model => $model ) : () ),
    attach_reads => $r->{files_read},
  };
}


sub skill_tool_text {
  my ( $self, $entry, $arguments ) = @_;
  my $run = $self->_run;
  my $renderer = $self->slash_renderer( session => $run ? $run->{session} : undef );
  my $r = $renderer->render(
    entry     => $entry,
    body      => $self->context->skill_catalog->body( $entry->{name} ),
    arguments => $arguments,
  );
  return { error => $r->{error} } if defined $r->{error};
  $self->permissions->add_run_rules( [ $renderer->allowed_tool_rules($entry) ], $renderer->grant_source($entry) )
    if $run;
  return { text => $r->{text} };
}


sub resolve_run_model {
  my ( $self, $model ) = @_;
  return $self->context->agent_catalog->resolve_model( $model,
    engine_class => scalar eval { $self->_engine_class },
    engine_name  => $self->engine_name,
    agent_models => $self->agent_models,
  );
}

sub _build_stock_tool_servers {
  my ($self) = @_;

  # The roots are asked on every call, so /reload (reload_permissions) reaches the mounted tools.
  # The file and search tools follow the working root (ADR 0032 §3).
  weaken(my $app = $self);
  my $files = $self->_follow_working_root($self->_file_tools_server($self->_main_file_tools_args), 'files');

  my $bash = $self->bash_tools->server;

  my $web = build_web_tools_server(
    loop   => $self->loop,
    answer => sub { $app ? $app->_web_fetch_answer_f(@_) : Future->fail("the application is gone\n") },
  );

  my $search = $self->_follow_working_root($self->_search_tools_server, 'search');
  my $todo  = $self->task_tools ? $self->_todo_tools->task_server : $self->_todo_tools->server;
  my $ask    = Langertha::Raider::AskTools->new(
    answerer => sub { $app && $app->has_on_ask_user ? $app->on_ask_user : undef },
  )->server;

  return [ $files, $bash, $web, $search, $todo, $ask, ( $self->_cron_wanted ? $self->cron_tools->server : () ) ];
}

# The file tools of the main run: over file_read_state, asking the engine
# whether it sees images and reads PDFs.
sub _main_file_tools_args {
  my ($self) = @_;
  weaken(my $app = $self);
  return (
    read_state  => $self->file_read_state,
    sees_images => sub { $app ? $app->_engine_sees_images : 0 },
    reads_pdf   => sub { $app ? $app->_engine_reads_pdf : 0 },
  );
}

# A new server with the file tools over the root, with the additional
# directories and the confinement of the policy -- both asked on every call --
# and the given read_state, sees_images and reads_pdf. The application mounts one over
# file_read_state; a subagent one over a read state of its own (ADR 0023). A
# subagent in a worktree (ADR 0032) passes its root and its policy (a code
# ref answering it), whose additional directories and confinement then hold.
sub _file_tools_server {
  my ($self, %o) = @_;
  my $policy = $self->_tools_policy($o{policy});
  return build_file_tools_server(
    root        => $o{root} // $self->root,
    extra_roots => sub { my $p = $policy->(); $p ? [ $p->additional_directory_paths ] : [] },
    # Confined unless the policy asks for paths outside the roots (Claude layout, ADR 0023).
    confine     => sub { my $p = $policy->(); $p ? !$p->ask_outside_roots : 1 },
    ( $o{read_state} ? ( read_state => $o{read_state} ) : () ),
    ( exists $o{sees_images} ? ( sees_images => $o{sees_images} ) : () ),
    ( exists $o{reads_pdf} ? ( reads_pdf => $o{reads_pdf} ) : () ),
  );
}

# A new server with the search tools over the root (or $o{root}), with the
# additional directories, the confinement and the Read rules' hider of the
# application's policy (or of $o{policy}, a code ref answering one) -- asked
# on every call.
sub _search_tools_server {
  my ($self, %o) = @_;
  weaken(my $app = $self);
  my $policy = $self->_tools_policy($o{policy});
  return Langertha::Raider::SearchTools->new(
    root        => $o{root} // $self->root,
    extra_roots => sub { my $p = $policy->(); $p ? [ $p->additional_directory_paths ] : [] },
    confine     => sub { my $p = $policy->(); $p ? !$p->ask_outside_roots : 1 },
    hider       => sub { my $p = $policy->(); $app && $p ? $app->_search_hider($p) : undef },
  )->server;
}

# A code ref answering the policy the file and search tools ask on every
# call: $policy when given, else the application's permissions (so
# /reload reaches the mounted tools).
sub _tools_policy {
  my ($self, $policy) = @_;
  return $policy if $policy;
  weaken(my $app = $self);
  return sub { $app ? $app->permissions : undef };
}


has file_read_state => (
  is         => 'ro',
  isa        => 'Langertha::Raider::FileTools::ReadState',
  lazy_build => 1,
  init_arg   => undef,
);

sub _build_file_read_state { Langertha::Raider::FileTools::ReadState->new }

# Whether an image, or a PDF, that read_file finds can go back to the model as
# content: the engine says so itself (tool_result_images / tool_result_pdf,
# Langertha ADR 0039) -- no guessing from the wire name. Two questions: a model
# can take one and not the other.
sub _engine_sees_images { shift->_engine_supports( tool_result_images => @_ ) }
sub _engine_reads_pdf   { shift->_engine_supports( tool_result_pdf => @_ ) }

sub _engine_supports {
  my ($self, $cap, $engine) = @_;
  $engine //= $self->_has_raider ? $self->_raider->active_engine : $self->_engine;
  return $engine && $engine->can('supports') && $engine->supports($cap) ? 1 : 0;
}


has task_tools => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  builder => '_build_task_tools',
);

sub _build_task_tools {
  my $v = $ENV{RAIDER_ENABLE_TASKS};
  return 1 unless defined $v && length $v;
  return $v =~ /\A(?:0|false|no|off)\z/i ? 0 : 1;
}

has _todo_tools => (is => 'ro', lazy => 1, builder => '_build_todo_tools', init_arg => undef);

sub _build_todo_tools {
  my ($self) = @_;
  weaken(my $app = $self);
  return Langertha::Raider::TodoTools->new(
    on_update   => sub { $app->_todos_updated(@_) if $app },
    before_task => sub { $app ? $app->_task_hook(@_) : undef },
  );
}

# TaskCreated / TaskCompleted (ADR 0022): the hooks of the Claude layout run
# before the task tools change the list. Exit 2 (or decision "block") undoes
# the change and hands the hook's stderr to the model as the tool's error
# result, as Claude Code does; continue: false stops the run. Returns that
# text, or undef when the call may go on. A subagent's task list passes
# %for as tool_hook takes it (input, on_event, on_stop): its fields in the
# hook input, the reports to its journal, a stop cancels it.
sub _task_hook {
  my ($self, $event, $task, %for) = @_;
  my $hooks = $self->hooks;
  return unless $hooks && $hooks->has_hooks($event);
  my $r = $self->_await_hooks($hooks->run_f( $event => $self->_hook_input(
    ( $for{input} ? $for{input}->() : () ),
    task_id          => $task->{id},
    task_subject     => $task->{content},
    task_description => $task->{description},
  )));
  $self->_report_hooks($r, $for{on_event});
  $self->_hook_stopped($for{on_stop}) if $r->stopped;
  return unless $r->blocked;
  my $why = $r->reason;
  return $event.' hook error: '.( defined $why && length $why ? $why : 'blocked' );
}


has _todos => (
  is       => 'rw',
  isa      => 'ArrayRef',
  default  => sub { [] },
  init_arg => undef,
);

sub todos { [ map { { %$_ } } @{ $_[0]->_todos } ] }

sub _todos_updated {
  my ($self, $list) = @_;
  $self->_todos($list);
  $self->event('todo.updated', todos => $self->todos);
  return;
}

sub _build_perl_tool_server {
  my ($self) = @_;
  return $self->_follow_working_root($self->_perl_tools_server, 'perl');
}

# A new server with the Perl tools working in the root (or $o{root}: a
# worktree, ADR 0032), with the private lib of the root.
sub _perl_tools_server {
  my ($self, %o) = @_;
  my $lib_target = $self->has_preferred_lib_target
    ? $self->preferred_lib_target
    : ($self->_load_yml_options->{preferred_lib_target} // undef);
  return build_perl_tools_server(
    root       => $o{root} // $self->root,
    lib_root   => $self->root,
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
    my @configured = @{ $self->configured_mcp->clients };
    my %client = map { refaddr($servers->[$_]) => $mcps->[$_ + @configured] } 0..$#$servers;
    my @clients = map { delete $client{refaddr $_} // $self->_mcp_client($_) } @$want;
    $self->loop->remove($_) for values %client;
    @$mcps = ( @configured, @clients );
  }
  @$servers = @$want;
  return 1;
}

sub _build_engine {
  my ($self) = @_;
  return $self->engine_resolver->build_engine(mcp_servers => $self->_mcps);
}


sub build_subagent_engine {
  my ($self, %o) = @_;
  return $self->engine_resolver->build_engine(mcp_servers => $o{mcp_servers},
    defined $o{model} ? ( model => $o{model} ) : ());
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
  return $self->run_plugins(sub { $app->event(@_) if $app });
}


sub note_usage {
  my ( $self, %p ) = @_;
  my $model = defined $p{model} && length $p{model} ? $p{model} : 'unknown';
  my $m = $self->_usage->{$model} //= { map { $_ => 0 } @USAGE_FIELDS, 'calls' };
  $m->{$_} += $p{$_} // 0 for @USAGE_FIELDS;
  $m->{calls}++;
  return;
}


sub usage_stats {
  my ($self) = @_;
  my %models = map { $_ => { %{ $self->_usage->{$_} } } } keys %{ $self->_usage };
  my %total = map { $_ => 0 } @USAGE_FIELDS, 'calls';
  for my $m (values %models) { $total{$_} += $m->{$_} for keys %total }
  return { %total, models => \%models };
}


sub run_plugins {
  my ($self, $on_event, %hook) = @_;
  # Every raider's model calls reach the ledger, whoever consumes the events.
  my $consumer = $on_event;
  weaken(my $app = $self);
  $on_event = sub {
    $app->note_usage(@_[1 .. $#_]) if $app && $_[0] eq 'model.usage';
    return $consumer->(@_);
  };
  # The rule-driven test engine (-e mock) matches the prompt word for word, so
  # it gets the prompt as typed, without the [situation] line and its clock.
  my $virtual = $self->engine_resolver->engine_class eq 'Langertha::Engine::Virtual';
  # Events last, so it reports the tool calls that actually run -- and the
  # results as the model gets them, nested CLAUDE.md files and the hooks'
  # context (ClaudeHooks, PostToolUse) included.
  return ( ( $virtual ? () : '+Langertha::Raider::Plugin::Situation' ),
    '+Langertha::Raider::Plugin::NestedMemory', { context => $self->context },
    ( $self->context->claude_layout
      ? ( '+Langertha::Raider::Plugin::ClaudeHooks', { app => $self, on_event => $on_event, %hook } ) : () ),
    '+Langertha::Raider::Plugin::Events', { on_event => $on_event } );
}

# The main raider. Before every model request but the first of a raid it
# takes the notifications of background subagents that wait for the main
# conversation (ADR 0027 section 4).
sub _build_raider {
  my ($self) = @_;
  my @plugins = $self->_raider_plugins;
  weaken(my $app = $self);
  return Langertha::Raider->new(
    no_session_embeddings      => $self->session_embeddings->{enabled} ? 0 : 1,
    _tool_gate                 => $self->tool_gate,
    ( $self->context->claude_layout ? ( _tool_hook => $self->tool_hook ) : () ),
    async_tools                => { %{ $self->_async_agent_tools },
      %{ $self->_shell_async_tools(recipient => 'main', detached => 0,
        working_directory => sub { $app ? $app->working_root : undef }) } },
    engine                     => $self->_engine,
    mission                    => $self->mission,
    max_iterations             => $self->max_iterations,
    max_context_tokens         => $self->max_context_tokens,
    context_compress_threshold => $self->context_compress_threshold,
    (@plugins ? (plugins => \@plugins) : ()),
    on_iteration               => sub { $app ? [ $app->_take_main_messages ] : undef },
  );
}


sub session_embeddings {
  my ($self) = @_;
  return { enabled => 1 }
    if grep { $_->name =~ /^(?:raider_)?session_history\z/ } $self->_mounted_tools;
  return { enabled => 0, reason => 'no session history tool is mounted' };
}


async sub raid_f {
  my ($self, @messages) = @_;
  await $self->configured_mcp->start_f;   # the configured servers in parallel, never fails
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
  $self->_await_foreground_agents;
  return $f->get;
}

# A foreground subagent of the main run whose agent call a cancel cut off
# (ADR 0027 section 9) ends on the loop; the run ends after it, so its
# agent.finished and journal land inside the run, as when the call waited.
sub _await_foreground_agents {
  my ($self) = @_;
  return unless $self->_has_tasks;
  my @futures = grep { defined && !$_->is_ready } map { $_->{future} }
    $self->tasks->running(kind => 'agent', recipient => 'main', background => 0);
  $self->loop->await(Future->wait_all(map { $_->without_cancel } @futures)) if @futures;
  return;
}


# The reason of a run that ended with $status when the caller named none
# (ADR 0034); a cancel names its own (cancel_run).
my %DEFAULT_REASON = ( failed => 'error', interrupted => 'signal', refused => 'refused' );

# The ADR 0015 event types the journal records from the events of a run;
# run.finished is written by end_run.
my %JOURNAL_TYPE = map { $_ => 1 } qw( run.started message tool.call tool.result todo.updated
  permission.asked permission.granted permission.denied permission.mode hook.ran hook.message
  model.usage agent.started agent.finished agent.warning mcp.server mcp.tools_changed
  worktree.entered worktree.exited );


sub is_journal_type { $JOURNAL_TYPE{ $_[1] // '' } ? 1 : 0 }

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
  unless (eval { $self->begin_run(%o); 1 }) {
    my $error = $@;
    die $error unless $self->_run;
    chomp $error;
    return $self->end_run(failed => error => $error, reason => 'run_setup');
  }
  my $reminders = $o{reminders};
  $reminders = undef unless defined $reminders && length $reminders;
  $self->event('message', role => 'user', content => $reminders, notification => 1) if defined $reminders;
  $self->event('message', role => 'user', content => $text, ( $o{notification} ? ( notification => 1 ) : () ));

  # The Claude layout's hooks (ADR 0022): SessionStart, UserPromptSubmit
  # before the model sees the prompt, Stop after it answered. A turn of
  # notifications is no prompt of the user's: no UserPromptSubmit.
  my $prompt = $text;
  if (my $hooks = $self->hooks) {
    my $before = eval { $self->_hooks_before_prompt($hooks, $text, $o{notification} ? ( no_prompt_hook => 1 ) : ()) };
    unless ($before) {
      my $error = $@;
      chomp $error;
      return $self->end_run(failed => error => $error);
    }
    return $self->end_run(failed => error => $before->{error}, reason => $before->{reason})
      if defined $before->{error};
    $prompt = $before->{prompt};
  }
  $prompt = $reminders."\n\n".$prompt if defined $reminders;

  my $result;
  unless (eval {
    $prompt = $self->_with_resource_mentions($prompt);
    $result = $self->run($prompt);
    $result = $self->_hooks_after_answer($result);
    $result = $self->_await_background($result) if $o{wait_background};
    1;
  }) {
    my $error = $@;
    chomp $error;
    # The raider marks the ends it knows (max_iterations, engine_error).
    return $self->end_run(failed => error => $error,
      reason => $self->_has_raider ? $self->_raider->_end_reason : undef);
  }
  if (blessed $result && $result->can('is_cancelled') && $result->is_cancelled) {
    return { %{ $self->end_run('cancelled') }, result => $result };
  }
  $self->event('message', role => 'assistant', content => "$result");
  my $metrics = { %{ $self->raider->metrics }, usage => $self->usage_stats };
  my $end = $self->end_run(completed => metrics => $metrics);
  return { %$end, result => $result, response => "$result", metrics => $metrics };
}

# The prompt with the resources its @server:uri mentions name attached
# (ADR 0029 Addendum 1). The configured servers are started first (a no-op
# once they are); a prompt without a mention is returned as it is.
sub _with_resource_mentions {
  my ($self, $prompt) = @_;
  return $prompt unless $prompt =~ /@\S+:[A-Za-z][A-Za-z0-9+.-]*:\/\//;
  $self->loop->await($self->configured_mcp->start_f);
  my @blocks = $self->_mcp_resources->attachments($prompt);
  return @blocks ? join("\n\n", $prompt, @blocks) : $prompt;
}


sub begin_run {
  my ( $self, %o ) = @_;
  my $session = $o{session};
  $self->_todos([]) unless $self->task_tools;
  # The working root moved since the mission was compiled (ADR 0032 §3).
  if ($self->_mission_stale) {
    $self->_mission_stale(0);
    $self->reload_mission if $self->_has_raider;
  }
  $self->file_read_state->clear;
  %{ $self->_plan_calls } = ();
  $self->_seed_read_state;
  $self->slash_command_class->record_reads({ files_read => $o{attach_reads} }, $self->file_read_state)
    if ref $o{attach_reads} eq 'ARRAY';
  my $resolved = defined $o{model} && !ref $o{model} && length $o{model}
    ? $self->resolve_run_model($o{model}) : {};
  my $run_model = $resolved->{model};
  my $run = {
    session  => $session,
    run      => $session ? $session->next_run : undef,
    on_event => $o{on_event},
    t0       => Time::HiRes::time(),
  };
  $self->_run($run);
  $self->permissions->add_run_rules($o{allow_rules}, $o{allow_source} // 'run')
    if ref $o{allow_rules} eq 'ARRAY';
  # The tools the model sees, when they are settled now: while a configured
  # MCP server has not connected yet (raid_f starts them), they are not, and
  # the field is left out rather than guessed (ADR 0034).
  my $tools = eval { $self->raider->_tool_names_now };
  $self->event('run.started', engine => $self->engine_name,
    defined $run_model ? ( model => $run_model ) : $self->has_model ? ( model => $self->model ) : (),
    $session ? ( session => $session->id, run => $run->{run} ) : (),
    cwd             => $self->working_root,
    permission_mode => $self->permissions->mode,
    $tools ? ( tools => $tools ) : (),
    raider_version  => Langertha::Raider->VERSION);
  $self->event('run.state', state => 'running');
  $self->_use_run_model($run, $run_model) if defined $run_model;
  return;
}

# Puts the raider on an engine with $model for this run; end_run puts the
# engine it had back.
sub _use_run_model {
  my ( $self, $run, $model ) = @_;
  my $raider = $self->raider;
  my $engine = $self->build_subagent_engine( mcp_servers => $self->_mcps, model => $model );
  $run->{restore_engine} = $raider->override_engine($engine);
  return;
}

# The instructions files the context put into the prompt (CLAUDE.md, AGENTS.md,
# ...) count as read, as in Claude Code: the model has seen them (ADR 0023).
sub _seed_read_state {
  my ( $self ) = @_;
  my $state = $self->file_read_state;
  for my $item ( $self->context->instruction_items ) {
    my $bytes = eval { path( $item->{file} )->slurp_raw };
    $state->record( $item->{file}, bytes => $bytes ) if defined $bytes;
  }
  return;
}


sub end_run {
  my ( $self, $status, %fields ) = @_;
  my $run = $self->_run or return;
  my $elapsed = 0 + sprintf('%.3f', Time::HiRes::time() - $run->{t0});
  # Why a run that did not complete ended (ADR 0034): the code the caller
  # gives, else the one the status implies.
  my $reason = $status eq 'completed' ? undef
    : $fields{reason} // ( $status eq 'cancelled' ? $run->{cancel_reason} // 'user_cancel' : undef )
      // $DEFAULT_REASON{$status} // 'error';
  my %end = (
    status  => $status,
    defined $reason ? ( reason => $reason ) : (),
    ( map { defined $fields{$_} ? ( $_ => $fields{$_} ) : () } qw( error signal ) ),
    elapsed => $elapsed,
  );
  if (my $session = $run->{session}) {
    my $metrics = $fields{metrics} // eval { $self->raider->metrics };
    $self->_append($run, 'run.finished', run => $run->{run}, %end, $metrics ? ( metrics => $metrics ) : ());
    $end{session} = { id => $session->id, path => ''.$session->path };
  }
  $self->event('run.state', state => $status);
  # What begin_run set up for this run only (ADR 0030 §3).
  $self->permissions->clear_run_rules;
  $run->{restore_engine}->() if $run->{restore_engine};
  $self->_clear_run;
  # A cancel that came too late for the raid must not hit the next run.
  $self->_raider->clear_cancel if $self->_has_raider;
  return \%end;
}


sub cancel_run {
  my ( $self, %o ) = @_;
  my $run = $self->_run or return 0;
  $run->{cancelled} = 1;
  $run->{cancel_reason} //= $o{reason} // 'user_cancel';
  $self->_raider->cancel if $self->_has_raider;
  $_->cancel for grep { defined } values %{ $self->_live_subagents };
  return 1;
}


sub run_cancelled {
  my ( $self ) = @_;
  my $run = $self->_run;
  return $run && $run->{cancelled} ? 1 : 0;
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


sub loaded_skill_names { map { $_->{name} } $_[0]->context->skill_catalog->listed }


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
  # The task list the session left (task tools only; todo_write is the run's).
  if ($self->task_tools) {
    my $tasks = $journal->tasks;
    $self->_todo_tools->restore_tasks($tasks);
    $self->_todos($tasks);
  }
  # The hooks see the next run as a resumed session (SessionStart resume).
  $self->_hook_session(undef);
  $self->_hook_session_source('resume');
  return $journal;
}


sub fork_session {
  my ($self, $id) = @_;
  my $store = $self->session_store;
  my $journal = $store->read($id);
  my $history = $journal->history_messages;
  my $tasks   = $journal->tasks;
  my $session = $store->create(forked_from => $id);
  $session->append('message', role => $_->{role}, content => $_->{content}) for @$history;
  $session->append('todo.updated', todos => $tasks) if @$tasks;
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


sub reload_context {
  my ($self) = @_;
  $self->context->reload;
  $self->reload_permissions;
  $self->reload_mcp;   # after the config files were read again (ADR 0029)
  $self->_clear_skill_tool_server;
  # The hooks come from the settings and plugins just read again.
  if ($self->has_hooks && $self->hooks) {
    $self->hooks->shutdown;
    $self->clear_hooks;
    $self->_hook_config_reported(0);
  }
  $self->_clear_agent_tool_server;
  $self->_clear_agent_tools;
  return $self->context;
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
  return 'claude base' if $self->claude_persona_off;
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
    ( $self->claude ? ( claude => [ $self->source_label('claude'), 1 ] ) : () ),
    ( $self->has_detect_flag
      ? ( detect => [ $self->source_label($self->detect ? 'detect' : 'no_detect'), $self->detect ? 1 : 0 ] ) : () ),
  );
  my %key = map { $_ => 1 } keys %$opts, keys %yml, keys %flag;
  delete @key{qw( engine model api_key skills project_tools )};
  my @ignored = @{ $report->{ignored} };
  push @ignored, { key => $opt_label.' project_tools', reason => 'only ~/.raider/config.yml grants tools to projects' }
    if exists $opts->{project_tools};
  # max_agent_depth and max_concurrent_agents always listed: from the
  # config, else env or default.
  my ( %fallback, %no_candidates );
  for my $limit ( [ max_agent_depth => $self->_max_agent_depth_source ],
    [ max_concurrent_agents => $self->_max_concurrent_agents_source ] ) {
    my ( $name, $source ) = @$limit;
    push @ignored, @{ $source->{ignored} };
    $key{$name} = 1;
    $fallback{$name} = [ $source->{source}, $source->{value} ];
    $no_candidates{$name} = 1 unless $source->{source} eq 'config';
  }
  for my $key (sort keys %key) {
    my $applies_to = $self->config->is_app_key($key) ? 'raider' : 'engine';
    push @values, $self->_explain_entry($key, $applies_to, $no_candidates{$key} ? [] : [
      $flag{$key} // ( exists $opts->{$key} ? [ $opt_label, $opts->{$key} ] : undef ),
      $from_yml{$key},
    ], $fallback{$key});
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
  my $bindings = eval { $self->config->providers } // {};
  return {
    %$report,
    ( %$bindings ? ( providers => [ map { $self->_binding_class->summary($_, $bindings->{$_}) } sort keys %$bindings ] ) : () ),
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
    session_embeddings => $self->session_embeddings,
    tools         => $self->_tool_effects_report,
    permissions   => $self->permissions->report,
    mcp           => $self->mcp_report,
    ignored_instructions_files => [ $self->instructions->ignored_files ],
    %{ $self->context->report(
      engine_class => scalar eval { $self->_engine_class },
      engine_name  => $engine,
      agent_models => $self->agent_models,
    ) },
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

sub _binding_class { 'Langertha::Raider::Provider::Binding' }

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

version 0.504

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
(L<Langertha::Raider::FileTools>), C<bash> with C<bash_output>, C<kill_shell> and
C<monitor> (L<Langertha::Raider::BashTools>), the cron tools in the REPL
(L</scheduling>, L<Langertha::Raider::CronTools>), web
(L<Langertha::Raider::WebTools>), the Perl tools
(L<Langertha::Raider::PerlTools>) when granted, the Hall tools when
spawned by a Hall, the C<agent> and C<send_message> tools
(L<Langertha::Raider::AgentTools>, whose calls run as
L<Langertha::Raider::Subagent>) below L</max_agent_depth>, C<enter_worktree>
and C<exit_worktree> (L<Langertha::Raider::WorktreeTools>, which move the
L</working_root>) -- and builds the
L<Langertha::Raider> that runs the raids. It keeps the registry of its
subagents and background work and their notifications (L</tasks>, ADR
0027). It opens, creates and replays the sessions of the project
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
ADR 0014, ADR 0019), in this order: the instructions (a generic assistant
persona plus the project instructions file, L</instructions>; in Claude mode the
neutral L</claude_base_text> instead of the persona, L</claude_persona_off>); the context
items of L</context> (the Claude memory files, F<AGENTS.md> of
C<--openai>, the listing of the skills as C<name: description> --
L<Langertha::Raider::Context/prompt_items>); the tool description; the
active packs. Skill bodies are not in it: the model loads one with the
C<skill> tool. The tool description lists the tools of the mounted tool servers
-- the same servers the engine gets -- each as C<name(required, [optional])>
from its input schema (ADR 0005); a tool that is not mounted is not
described. A C<mission> passed to the constructor (C<-M>) replaces the
instructions item only, also across L</reload_mission>; the other items,
the Claude memory included, still apply. With L</bare> the context items,
the instructions file and all packs not switched on by C<--pack> or
C</pack> are left out.

=head2 bare

C<--bare>: an isolated context. No instructions file (F<.raider.md>,
F<.raider/instructions.md>), no layout (no Claude memory, settings or
plugins, layout mode C<bare>), no skills, no pack
detection, and no packs from C<packs:> or C<enabled_by_default>;
C<--pack NAME> and C</pack NAME> still switch a pack on explicitly. What
remains is the instructions (the default persona, or the C<-M> text) and
the tool description.

=head2 claude

C<--claude>: read the Claude Code layout (ADR 0019) in every layout mode
but C<bare>, whatever the configuration says. Without it, C<claude:> in
F<.raider.yml> (or the legacy C<skills: [claude]>) switches it on in a
raider project; a project with only Claude files is in Claude mode anyway.

=head2 context

The L<Langertha::Raider::Context> of L</root> (ADR 0019): layout mode,
the Claude memory, settings and plugins, the F<AGENTS.md> item and the
skill catalogue, from L</claude>, C<claude:> of the configuration,
L</skill_sources> and L</bare>. Built once; building it sets the C<env> of
the Claude settings in the process environment
(L<Langertha::Raider::Context/apply_env>), before any tool runs.

=head2 compile_mission

    my $mission = $app->compile_mission($instructions, \@tool_servers);
    my $bare    = $app->compile_mission($body, \@tool_servers, memory => 0);

A mission as L</mission> is built: the instructions item C<$instructions>,
the context items (L<Langertha::Raider::Context/prompt_items>), the tool
description of C<@tool_servers> and the active packs. The skill listing
is left out when C<@tool_servers> has no C<skill> tool. A subagent's
mission (L<Langertha::Raider::Subagent>) is compiled here with the agent's
body as C<$instructions> and its own tool set.

With C<< memory => 0 >> (the built-ins C<Explore> and C<Plan>, ADR 0027
E<sect>6) the mission is only C<$instructions>, the skill listing when
C<@tool_servers> has the C<skill> tool, and the tool description: no
Claude memory, no F<AGENTS.md>, no packs.

C<< working_directory => $dir >> names C<$dir> in the C<Working
directory:> line of the tool description instead of L</working_root> -- a subagent
in a worktree of its own (ADR 0032 E<sect>2), whose mission is otherwise
compiled for the caller's context.

=head2 instructions_text

    my $text = $app->instructions_text;

The instructions item of the L</mission>: the C<-M> text, or else the
default persona with the project instructions file
(C<.raider/instructions.md>, else C<.raider.md>) appended -- the persona
alone under C<bare>.

=head2 mounted_tools

    my @tools = $app->mounted_tools;

The L<MCP::Tool> objects of the mounted tool servers, in mount order --
what the prompt describes, the engine offers and L<Langertha::Raider::Skill>
documents.

=head2 persona_intro

The first paragraph of the default persona: who the agent is and where it
runs. The command line (L<Langertha::Raider::CLI>) says it is a CLI.

=head2 persona_turn_end

The last paragraph of the default persona: how the agent ends a turn and
who answers next.

=head2 claude_persona_off

True in layout mode C<claude> (ADR 0019 E<sect>1, no raider files, only
Claude Code ones): raider acts as Claude Code would, so its own default
persona (Langertha, the terse style) is not used -- the instructions item
is L</claude_base_text> and the F<CLAUDE.md> memory -- and the packs
switched on only by C<enabled_by_default> stay off (see L</packs>). A
C<-M> mission, C<--pack> / C<packs:> and a raider project that merely
reads the Claude layout (C<claude: true>, C<--claude>) are not affected.

=head2 claude_base_text

The neutral instructions item of Claude mode, in the manner of Claude
Code's own base prompt: no name, no persona, the working rules.

=head2 root

Working directory for tool operations. Defaults to the current process cwd.
File tools are confined to this directory, including realpath checks for
symlink escapes; bash commands inherit it as their default working directory.
While the session works in a worktree the tools work in L</working_root>
instead.

=head2 working_root

Where the session works right now (ADR 0032 E<sect>3): the directory the
file, search and shell tools (and the Perl tools when they are mounted)
work in, the root of L</permissions>, the C<cwd> of every hook input and
the C<Working directory:> line of the next mission compiled. It starts as
L</root>; C<enter_worktree> moves it into a git worktree -- the same
subdirectory of it when L</root> is a subdirectory of the repository --
and C<exit_worktree>, a new conversation and the end of the session
(L</close_worktree_session>) move it back. Everything else stays at
L</root>: the context and layout, configuration and settings,
instructions and skills, the session store and its journals, the
directory hook processes run in and C<CLAUDE_PROJECT_DIR>.

A tool call already running finishes where it started; the next one works
in the new working root. Subagents spawned meanwhile start in it
(L<Langertha::Raider::Subagent/caller_root>); an isolated one branches
from its C<HEAD> under C<head>, its worktree still under the main
checkout's top.

=head2 worktree_session

    my $wt = $app->worktree_session;
    # { path, branch, top, root, created => 1, base => '...', session => $session } or undef

The worktree C<enter_worktree> moved the session into, while it works
there: C<path> and C<branch> (undef for a detached C<HEAD>), C<top> (the
main checkout), C<root> (the L</working_root>), C<created> (made by this
session, so it may be removed; else entered by C<path> and only ever
left), C<base> (the commit a created one branched from) and C<session>
(the session it was entered in, which its C<worktree.exited> goes to).

=head2 allowed_commands

Optional arrayref restricting which bash commands may run (first word match).
When undef, any command is allowed.

=head2 max_iterations

Maximum tool-calling iterations per raid. Defaults to 10_000 — effectively
unlimited, so a raid only ends when the model itself stops emitting tool
calls. The conversation history is preserved between raids, so the next user
message in the REPL simply continues the same thread.

Set this to a smaller number if you want a hard safety cap.

=head2 max_agent_depth

How deep subagents may nest (ADR 0020 E<sect>4, ADR 0027 E<sect>8): the
main run has depth 0, its subagents depth 1, and a run at this depth gets
no C<agent> tool. From C<max_agent_depth> of the configuration (or
C<-o max_agent_depth=>), a non-negative integer -- C<0> mounts no C<agent>
tool at all; else, in the Claude layout only, from
C<CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH> of the environment (the Claude
settings C<env> included, L<Langertha::Raider::Context/apply_env>), a
positive integer; else 3, Claude Code's "up to three layers below the main
conversation". C<1> turns nesting off. A value that does not fit is
ignored, and C<config explain> lists it under C<ignored>.

=head2 max_concurrent_agents

How many subagent runs of the application may run at once (ADR 0027
E<sect>9) -- all depths, foreground and background, resumed ones too; a
spawn or a C<send_message> resume beyond it is refused with an error
result that tells the model not to retry now. From C<max_concurrent_agents>
of the configuration (or C<-o max_concurrent_agents=>), a positive
integer; else, in the Claude layout only, from
C<CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS> of the environment (the Claude
settings C<env> included), a positive integer; else 20, as Claude Code. A
value that does not fit is ignored, and C<config explain> lists it under
C<ignored>.

=head2 agent_models

The model per alias for agent files (ADR 0020 E<sect>5), from the mapping
C<agent_models> of the configuration, e.g.
C<< { sonnet => 'claude-sonnet-4-6' } >>; overrides
L<Langertha::Raider::Context::Agents/model_aliases> per alias. Defaults to
none.

=head2 worktree_base_ref

    my $mode = $app->worktree_base_ref;   # 'fresh' or 'head'

Where a new worktree branches from (ADR 0032 E<sect>2): C<worktree.baseRef>
of the Claude settings in the Claude layout
(L<Langertha::Raider::Context::Settings/worktree_base_ref>), else
C<worktree_base_ref> of the configuration. C<head> is the C<HEAD> of the
caller's working root; C<fresh> -- the default, and what any other value
counts as -- is C<origin/HEAD> when it resolves, else that C<HEAD>
(L<Langertha::Raider::Worktree/base_ref>).

=head2 worktrees_dir

    my $dir = $app->worktrees_dir($top);   # /repo/.claude/worktrees

The directory under the main checkout C<$top> that raider's worktrees live
in (ADR 0032 E<sect>2): F<.claude/worktrees> in the Claude layout, else
F<.raider/worktrees>.

=head2 note_meta

    $app->note_meta('agent agent_1 left its worktree /repo/.raider/worktrees/agent-1 on branch worktree-agent-1');

Queues a line for the person, outside any run: a surface shows it as a
meta line (L</take_meta_notes>). An isolated subagent cancelled without a
notification names its kept worktree this way (ADR 0032 E<sect>2).

=head2 take_meta_notes

    say_meta($_) for $app->take_meta_notes;

Takes the lines L</note_meta> queued, oldest first.

=head2 leaving

True once L</stop_background> ran: the person is leaving raider, and the
notifications of the subagents that end now reach nobody.

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

=head2 on_ask_user

Optional code reference a surface sets when a person can answer the model
during a run: called as C<< $on_ask_user->($question, \@options) >>, it puts
the question to the person and returns the answer as text (undef: none). It
makes the C<ask_user> tool work (L<Langertha::Raider::AskTools>); the REPL
sets it. Without it -- a one-shot run, the Hall, a cron job, ACP -- the
tool refuses with a plain error result and the model decides itself. Read
when the tool is called, so a surface may set it after the application is
built.

=head2 on_permission_request

Optional code reference a surface sets when a person can approve tool calls
during a run (the REPL does): called as C<< $on_permission_request->(\%request) >>
for every call L</permissions> asks about, with C<tool>, C<source>,
C<arguments>, C<reason> (why it asks) and C<rule> (the rule "yes, for this
session" would allow, undef when none can name the call safely). It returns
C<< { answer => 'once' } >>, C<< { answer => 'session' } >> or
C<< { answer => 'no', reason => $why } >> (undef counts as no). "once" runs
this exact call (an L<Langertha::Raider::Approval> bound to session, run,
tool, arguments and policy revision); "session" adds C<rule> as a session
rule; "no" refuses it, and the model gets the reason. Without it every such
call is refused. Read for every call, so a surface may set it after the
application is built.

=head2 on_plan_review

Optional code reference a surface sets when a person can review a plan:
called as C<< $on_plan_review->($plan) >> when the model calls
C<exit_plan_mode> in plan mode; returns C<< { approve => 1 } >> (the mode
becomes C<default>) or C<< { approve => 0, feedback => $text } >>. Without
it the model is told to give the plan as its final answer.

=head2 permission_mode

The permission mode chosen for this application (ADR 0021): C<default>,
C<acceptEdits>, C<auto>, C<plan> or C<bypassPermissions>. It wins over
C<permissions.default_mode> of the config files and C<defaultMode> of the
Claude settings. Croaks on construction with any other name. The command
line sets it with C<--permission-mode>.

=head2 skip_permissions

True: the mode is C<bypassPermissions> -- every tool call runs unless a deny
rule refuses it. The command line sets it with
C<--dangerously-skip-permissions>. Not together with L</permission_mode>.

=head2 permissions

The L<Langertha::Raider::Permissions> of the application: the mode (from
L</skip_permissions>, L</permission_mode>, C<permissions.default_mode> of
F<.raider/config.yml> then F<~/.raider/config.yml>, C<defaultMode> of the
Claude settings, else C<default>), the rules of the config files
(L<Langertha::Raider::Config/permissions>) and, in the Claude layout, of the
settings (L<Langertha::Raider::Context::Settings/permissions>), and their
additional directories. Every tool call of the raider passes it (the gate
of ADR 0005): a call it asks about runs only when a person approves it, and
without anyone to ask it is refused with a reason that says how to allow it.
Its root is the L</working_root>, and while that is a worktree it refuses
edits into the main checkout
(L<Langertha::Raider::Permissions/worktree_isolation>, ADR 0032 E<sect>3).

=head2 set_permission_mode

    my $from = $app->set_permission_mode( 'acceptEdits', '/permissions' );
    $app->set_permission_mode( 'plan', 'enter_plan_mode', call => 'c3' );

Switches the mode of L</permissions> (croaks on an unknown mode) and emits
C<permission.mode> with C<from>, C<to>, C<why> and the given C<call> (the
id of the tool call that switched it, ADR 0034). Returns the previous
mode.

=head2 reload_permissions

    $app->reload_permissions;

Reads the permission sources again (C</reload>): the rules, modes and
additional directories of the config files and the Claude settings. The
session rules stay, and so does a mode switched during the session
(C</permissions mode>, C<exit_plan_mode>). The mounted file and search tools
read the additional directories from the policy on every call, so a directory
added or removed in the sources is reachable or refused from the next call on.

=head2 tool_gate

    my $raider = Langertha::Raider->new( ..., _tool_gate => $app->tool_gate );

    # a sub-run (a subagent) with its own policy, journal and binding:
    my $gate = $app->tool_gate(
      policy   => $app->permissions->for_subrun,
      on_event => sub { my ( $type, %payload ) = @_; ... },
      binding  => sub { ( session_id => $id, run_id => $run ) },
      unattended => sub { $in_background ? 'this agent runs in the background' : undef },
    );

The gate every raider of the application gets (the C<_tool_gate> of
L<Langertha::Raider>, ADR 0005): L</permissions> decides each tool call.
A raider built on the application's engine -- the prompt builder, a
subagent -- takes it too, so no tool call passes without it.

A sub-run passes its own C<policy> (a L<Langertha::Raider::Permissions>,
usually L<Langertha::Raider::Permissions/for_subrun> of the caller's),
C<on_event> for the C<permission.*> events (default L</event>) and
C<binding>, the session and run ids an approval of a call is bound to
(default the run in progress). A call the policy asks about goes to the
same L</on_permission_request>: the person at the keyboard answers for the
sub-run too, and "for this session" lands in the session rules the policies
share. C<unattended> is asked at every such call: a reason (a background
subagent, ADR 0027 E<sect>3) means nobody is asked, and the call is refused
as in a run nobody can approve, with that reason.

Before any rule or mode, a policy with
L<Langertha::Raider::Permissions/worktree_isolation> refuses edits into the
main checkout (ADR 0032 E<sect>3): the result is
L<Langertha::Raider::Permissions/main_checkout_refusal>'s text as it
stands, with C<permission.denied> (C<by> C<worktree>).

=head2 hooks

The L<Langertha::Raider::Hooks> runner of the Claude layout (ADR 0022):
the hooks of the Claude settings and of the enabled plugins, on L</loop>,
with L<Langertha::Raider::Permissions/rule_matches> for their C<if> rules.
C<undef> outside the Claude layout -- a native or bare run runs no hooks.
C</reload> builds it again.

=head2 tool_hook

    my $raider = Langertha::Raider->new( ..., _tool_hook => $app->tool_hook );

    # a sub-run (a subagent): its own input fields, events and stop
    my $hook = $app->tool_hook(
      input    => sub { ( agent_id => $id, agent_type => $name ) },
      on_event => sub { my ( $type, %payload ) = @_; ... },
      on_stop  => sub { $subagent->cancel },
    );

The tool hook every raider of the application gets in the Claude layout
(the C<_tool_hook> of L<Langertha::Raider>): the C<PreToolUse> hooks, before the inputSchema
check and L</tool_gate>. A deny (or exit 2) refuses the call with the
hook's reason; C<updatedInput> replaces the arguments (translated back to
raider's names); an allow or ask goes on to the gate, which weighs it
against the rules and the mode (deny and ask rules always hold; allow only
spares the mode's question; ask asks even where a rule allows). The
C<additionalContext> is appended to the tool's result.

A sub-run passes C<input>, a code ref whose pairs go into every hook input
(a subagent's C<agent_id>, C<agent_type> and C<permission_mode>),
C<on_event> for the C<hook.ran> and C<hook.message> events (default
L</event>) and C<on_stop>, called on a C<continue: false> (default
L</cancel_run>).

=head2 note_history_cleared

    $app->note_history_cleared;   # /clear

The conversation starts over: the next run fires C<SessionStart> again
with source C<clear>, and the task list (L</todos>) is empty. The
background subagents of the conversation are stopped without a
notification and the notifications that wait for it are dropped (ADR
0027); background shells go on and still notify (ADR 0024). A worktree
session ends (L</close_worktree_session> with C<clear>, ADR 0032
E<sect>5). C</clear>, C</reset> and C</new> call it.

=head2 stop_hook_limit

How many times in a row C<Stop> hooks may keep one run going: 8, Claude
Code's cap. The next block is overridden and the run ends.

=head2 shutdown_hooks

    $app->shutdown_hooks;

Stops the async hooks still running and waits until they are gone
(L<Langertha::Raider::Hooks/shutdown>), as Claude Code does when a
C<-p> run ends. The command line calls it when it is done.

=head2 configured_mcp

The configured MCP servers of the application (ADR 0029), a
L<Langertha::Raider::MCP> over
L<Langertha::Raider::MCP::Config/from_context> of L</context> and
L</config>. Its clients lead the engine's C<mcp_servers>; L</raid_f> starts
them (in parallel, never failing) before the first raid; the permission
gate knows them as foreign servers. Each start that ends emits
C<mcp.server> (C<name>, C<scope>, C<transport>, C<status> C<connected> or
C<failed>, C<reason>, C<tools>, the number of tools); so does each start
(C<starting>) and stop (C<stopped>), and C<mcp.tools_changed> (C<name>,
C<scope>) a server's C<tools/list_changed>. Inside a run they are in the
session journal. Stopped by
L</shutdown_mcp>.

=head2 shutdown_mcp

    $app->shutdown_mcp;

Stops the configured MCP servers and waits until they are gone (a stdio
process: stdin closed, then C<TERM>, then C<KILL>). The command line calls
it when it is done.

=head2 reload_mcp

    $app->reload_mcp;

Reads the MCP configuration again (C</reload>, after L</reload_context>
read the config files and settings): a server configured exactly as before
keeps its running connection, the others are stopped and the new ones start
with the next raid. The front of the engine's C<mcp_servers> and the
policy's C<source_servers> change in place. Nothing to do before the
servers were first needed.

=head2 reconnect_mcp

    my @names = $app->reconnect_mcp('github');   # or 'all' / undef

Stops the named configured server (every one with C<all> or no name) and
starts it again at once, in the same place; waits for the start. Returns
the names restarted (none for an unknown name).

=head2 mcp_pids

The process ids of the running stdio servers; a cancelled run leaves them
alone (L<Langertha::Raider::CLI::Runner/cancel_run>).

=head2 mcp_notes

The lines L<Langertha::Raider::MCP/notes> gives: the project servers that
wait for an approval nobody can give in this run. The command line prints
them on stderr.

=head2 ask_mcp_approvals

    $app->ask_mcp_approvals(sub {
      my ( $server ) = @_;          # an entry of Langertha::Raider::MCP::Config/servers
      return 'approve';             # or 'all', 'reject', undef (no answer: stays pending)
    });

Puts every pending project server to the person once (ADR 0029 E<sect>7),
writes each answer where it counts next time
(L<Langertha::Raider::MCP::Config/record_approval>), and makes it hold now
(L</reload_mcp>). After C<all> nobody is asked again. Returns a list of
C<< { name, answer, written } >> (C<written>: the file's label, or
C<undef> when it holds for the session only).

=head2 mcp_report

    my $r = $app->mcp_report;

The configured MCP servers for C<config explain> and C</mcp>: C<servers>
(L<Langertha::Raider::MCP/report>), C<errors> (files that could not be
read), C<warnings> (C<MCP_TIMEOUT> / C<MCP_TOOL_TIMEOUT>), C<trust> (with
its source), C<approvals_go_to> (where an answer is written) and the
C<startup_timeout_ms> / C<tool_timeout_ms>.

=head2 mcp_prompts

    for my $p (@{ $app->mcp_prompts }) { say $p->{command}, ' ', $p->{description} }

The prompts of the connected configured MCP servers as slash commands
(ADR 0029 Addendum 1): C<command> (C<mcp__SERVER__PROMPT>, the server part
as in tool names, the prompt name as the server declares it), C<server>,
C<name>, C<description> and C<arguments> (the server's list, each C<name>,
C<required>). Starts nothing -- a server that is not connected has none.

=head2 mcp_prompt_request

    my $request = $app->mcp_prompt_request( 'mcp__github__pr_review', '456' );
    # { prompt => ... } or { error => '...' }, nothing for a name that is no MCP prompt

A C</mcp__SERVER__PROMPT ARGS> run (ADR 0029 Addendum 1): starts the
configured servers when they are not yet, finds the prompt on the server
whose tool-name part is SERVER, maps the whitespace-separated arguments on
the prompt's declared arguments in order, asks the server (C<prompts/get>)
and frames the messages as a run request, in the framing of a custom
command (ADR 0030 E<sect>3):

    <command-message>mcp__github__pr_review is running...</command-message>
    <command-name>/mcp__github__pr_review</command-name>
    <command-args>456</command-args>

    MESSAGE TEXTS

Every message becomes part of one user prompt, in order, text only: a
resource inside a message contributes its text, an image or other
content a note. A missing required argument, one too many and a failing
C<prompts/get> are an C<error>.

=head2 loadguard

The L<Langertha::Raider::Loadguard> that gates C<bash>: a heavy command
(C<prove>, C<dzil test>, C<cpanm>, C<podman run> ...) is refused with the
reason while the host is out of memory or the heavy slots are taken. Built
from the environment (C<LOADGUARD_*>) unless given.

=head2 bash_tools

The L<Langertha::Raider::BashTools> behind C<bash>, C<bash_output>,
C<kill_shell> and C<monitor>, built once with L</root>, L</allowed_commands>, the
L</loadguard> gate, L</loop> and L</tasks>. Its background shells belong to the
application: they live across the runs of a session and are stopped when the
application goes away. They are entries of L</tasks> (C<bash_N>) and notify
the run that started them when they end; C<bash_output> and C<kill_shell>
reach the subagents there too (ADR 0027 E<sect>10).

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
on -- except in Claude mode (L</claude_persona_off>), where no pack is on
merely by default; C<config explain> shows them as switched off by the
layout.

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

ArrayRef of the explicit skill directories, the first skill roots of
L</context> (ADR 0019 E<sect>4). Each spec is a hashref:

    { type => 'claude', path => 'some/skills' }      # */SKILL.md skill directories
    { type => 'dir',    path => 'my-skills', glob => '*.md' }   # flat *.md skills
    { type => 'dir',    path => 'my-skills' }        # both

Defaults to the C<skills> entries of F<.raider.yml> (see
L<Langertha::Raider::Config/normalize_skill_spec>), then C<-o skills=>,
then L</cli_skill_sources>. Passing C<skill_sources> explicitly replaces
them. With L</bare> there are none. The skills are listed in the mission
and loaded by the model with the C<skill> tool, not glued in.

=head2 cli_skill_sources

ArrayRef of C<skills:> items from the command line: C<openai> for
C<--openai> / C<--codex> (F<AGENTS.md> as an instructions item) and
C<< { type => 'dir', path => DIR } >> for each C<--skills DIR>. They are
added to the F<.raider.yml> skills, duplicates dropped. C<--claude> is
L</claude>.

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

=head2 worktree_class

The class that does the git work of C<enter_worktree> and
C<exit_worktree>: L<Langertha::Raider::Worktree>.

=head2 worktree_tools_class

The class with the two tools' texts and schemas:
L<Langertha::Raider::WorktreeTools>.

=head2 close_worktree_session

    $app->close_worktree_session('clear');         # /clear, /reset, /new
    $app->close_worktree_session('session_end');   # leaving the REPL, the end of raider -p

Closes the worktree session at a new conversation or the end of the
session (ADR 0032 E<sect>5), as C<exit_worktree> would, without asking: a
worktree C<enter_worktree> created is removed with its branch when it has
no changes, and kept otherwise, with a meta line
(L</note_meta>: C<worktree P kept on branch B (has changes)>, or the
reason git gave); one entered by C<path> is only left. The
L</working_root> is back at L</root>; C<worktree.exited> has C<reason>
C<clear> or C<session_end>. Nothing without a worktree session. Never
dies.

=head2 subagent_class

The class that runs a call of the C<agent> tool:
L<Langertha::Raider::Subagent>.

=head2 tasks

The application's L<Langertha::Raider::Tasks> (ADR 0027 E<sect>1): the
registry of its subagents (agent IDs C<agent_N>) and background work, and
the queue of their notifications, built on first use over L</loop>.

=head2 web_fetch_engine

The engine that answers the C<prompt> of C<web_fetch> (ADR 0026): the run's
own engine, or -- with C<web_fetch_model> in the config (F<.raider/config.yml>,
the engine's section, C<-o web_fetch_model=>) -- the same engine, provider
and key with that model, e.g. a smaller one. Built when first needed.

=head2 scheduling

Bool, default false. True when the surface runs scheduled prompts as turns
of their own while it is idle -- the REPL does (ADR 0031): only then are
C<cron_create>, C<cron_delete> and C<cron_list> mounted. A run with a single
prompt, a Hall raider and ACP have no idle state a prompt could be run in,
so they are not offered the tools, and Claude Code's
C<CLAUDE_CODE_DISABLE_CRON=1> turns them off in the REPL too. Set it before
the tools are first used (the engine is built).

=head2 cron_tools

The L<Langertha::Raider::CronTools> behind the cron tools, built once over
L</loop> and L</tasks>. Its jobs belong to the application: they are
entries of L</tasks> (C<cron_N>) and go when it does.

=head2 caller_event

    $app->caller_event($session, 'agent.finished', agent_id => 'agent_1', ...);

An event of a subagent of the main run for its caller: L</event> while a
run is in progress (the run that is current, ADR 0027 E<sect>3); between
runs -- a background agent that ends while the REPL waits -- appended to
C<$session> (the session the agent was started from, when it is still open)
for the types the journal records, and handed to L</on_event>.

=head2 background_running

    my $n = $app->background_running;

How many background subagents and monitors of the main run still run. A
monitor ends at its deadline (at most 10 minutes in a run with a single
prompt, ADR 0031), so a run that waits for it waits for a bounded time.
Background shells do not count: nothing waits for them (ADR 0024, a server
may run for the whole session); their notifications are delivered when they
come.

=head2 scheduled_pending

How many prompts of due cron jobs wait for the surface to run them (ADR
0031).

=head2 take_scheduled

    my @items = $app->take_scheduled;   # ( { text, id, label, scheduled }, ... )

Takes the prompts of due cron jobs, oldest first: for the surface that runs
each as a turn of its own when it is idle (the REPL).

=head2 idle_pending

How many notifications and scheduled prompts wait for an idle surface.

=head2 idle_wait_f

    $app->loop->await( $app->idle_wait_f );

A future that is done once something waits for an idle surface
(L</idle_pending>). Cancelling it is fine.

=head2 notifications_pending

How many notifications wait for the main conversation (ADR 0027 E<sect>4).

=head2 take_notifications

    my @items = $app->take_notifications;   # ( { text, notification, id, label }, ... )

Takes the notifications that wait for the main conversation, in the order
their work ended: for a surface that delivers them itself (the REPL).

=head2 wait_for_notifications

    my $n = $app->wait_for_notifications;

Runs the loop until a notification waits for the main conversation or no
background subagent of it runs any more; returns how many wait.

=head2 stop_background

    my $n = $app->stop_background;

Leaving raider (ADR 0027 E<sect>3): asks every subagent of the
application that still runs to end (L<Langertha::Raider::Tasks/stop_all>)
and runs the loop until they have, at most C<$grace> seconds (default 2),
so their journals end. Returns how many it stopped. The application is
L</leaving> from then on.

=head2 slash_command_class

L<Langertha::Raider::SlashCommand>, the renderer of C</name> and the
C<skill> tool.

=head2 slash_renderer

    my $renderer = $app->slash_renderer( session => $session );

A L<Langertha::Raider::SlashCommand> over L</root> with the application's
L</permissions>, the loadguard gate (L</loadguard>) and the session's id
for C<${CLAUDE_SESSION_ID}>; C<disable_shell> is the Claude settings'
C<disableSkillShellExecution>
(L<Langertha::Raider::Context::Settings/disable_skill_shell_execution>). The
additional directories come from the policy.

=head2 slash_run_request

    my $request = $app->slash_run_request( 'review', 'src/App.pm', session => $session );
    # { prompt => ..., allow_rules => [...], allow_source => '/review allowed-tools',
    #   model => 'sonnet', attach_reads => [...] }   or   { error => '...' }
    $app->run_prompt( $request->{prompt}, %$request, session => $session ) unless $request->{error};

A C</NAME REST> run of a user-invocable catalogue entry (ADR 0030
E<sect>3): the entry (a name, or the entry hash) rendered with the
arguments and C<@file> attachments (L</slash_renderer>), then framed as
Claude Code frames it (the C<...> is one character, U+2026):

    <command-message>NAME is running...</command-message>
    <command-name>/NAME</command-name>
    <command-args>REST</command-args>

    RENDERED TEXT

The rest is what L</run_prompt> takes for that run: the entry's
C<allowed-tools> as C<allow_rules> with their C<allow_source>, its C<model>
frontmatter (when set) and the attached files as C<attach_reads>. A render
that aborts gives C<< { error => $reason } >>; nothing is to be sent then.
C<session> may be a code reference, called only when an entry is rendered.
Returns nothing for a name that is no user-invocable entry.

=head2 skill_tool_text

    my $loaded = $app->skill_tool_text( $entry, $args );   # { text } or { error }

What the C<skill> tool loads for a model-invoked entry (ADR 0030 E<sect>2):
the body rendered with the arguments and its C<!`cmd`> (through the
permission policy, nobody asked), without C<@file> attachments. When it
renders and a run is in progress, the entry's C<allowed-tools> hold for the
rest of that run (L<Langertha::Raider::Permissions/add_run_rules>). Its
C<model> is ignored: the engine is not switched inside a run.

=head2 resolve_run_model

    my $resolved = $app->resolve_run_model('sonnet');   # { model => '...' } or { inherit => 1, reason => ... }

The C<model> of a C</name> run as a subagent's is resolved (ADR 0020
E<sect>5, L<Langertha::Raider::Context::Agents/resolve_model>): an alias or a
C<claude-*> id under the Anthropic API, L</agent_models> applied;
C<inherit>, empty or anything else keeps the engine's model.

=head2 file_read_state

The record of the files read in the run in progress
(L<Langertha::Raider::FileTools::ReadState>), which the file tools hold
C<write_file>, C<edit_file> and C<multi_edit> against: an existing file must
have been read in this run, and not changed on disk since (ADR 0023).
L</begin_run> empties it and then records the instructions files of the
prompt (C<CLAUDE.md>, C<AGENTS.md>, ...) as read. A surface that shows the
model a file's content itself (the prompt builder) records it here.

=head2 task_tools

Which task-list family the application mounts (ADR 0025), one of the two
of L<Langertha::Raider::TodoTools>, as Claude Code offers one: true (the
default) for C<task_create>, C<task_update>, C<task_list> and C<task_get>
(Claude Code's C<TaskCreate> & co.), false for C<todo_write> (C<TodoWrite>).
Defaults to C<RAIDER_ENABLE_TASKS> when set (C<0> or C<false> turns the task
tools off, like Claude Code's C<CLAUDE_CODE_ENABLE_TASKS>).

=head2 todos

    my $list = $app->todos;     # [ { content, status, activeForm, ... }, ... ]

The task list, as the model last left it (L<Langertha::Raider::TodoTools>):
a copy; empty when the model kept none. With L</task_tools> it is the list of
C<task_create> & co., kept for the conversation: runs go on with it,
L</note_history_cleared> (C</clear>) empties it. With C<todo_write> it is
state of the run: L</begin_run> empties it. Every change is the event
C<todo.updated> with the whole list as C<todos>, which the session journal
records.

=head2 build_subagent_engine

    my $engine = $app->build_subagent_engine(mcp_servers => \@clients, model => $model);

The engine of a subagent (L<Langertha::Raider::Subagent>): the class and
arguments of the main engine (L<Langertha::Raider::EngineResolver/build_engine>)
over the subagent's own MCP clients, on the same loop. C<model> replaces
the model when given; without, the subagent inherits it. The one place a
subagent's engine comes from, so a subclass (or a test) can swap it.

=head2 note_usage

    $app->note_usage(model => 'claude-haiku-4-5', input_tokens => 1200,
      output_tokens => 80, cache_read_tokens => 1000);

Adds one model call to the token ledger of the application (ADR 0026):
cumulative, per model, over every raider of it -- the main one, its
subagents and a tool's own model calls. C<cache_read_tokens> and
C<cache_write_tokens> are part of C<input_tokens> as the engine reports
them. The C<model.usage> events of every raider's
L<Langertha::Raider::Plugin::Events> and of C<web_fetch> reach it; a
surface does not need to call it.

=head2 usage_stats

    my $u = $app->usage_stats;
    # { input_tokens, output_tokens, cache_read_tokens, cache_write_tokens,
    #   calls, models => { $model => { same keys } } }

The token ledger (L</note_usage>) as a copy: the totals and the same counts
per model; zeros and no C<models> before the first model call. This is what
C</stats> shows and the C<usage> of the metrics of a run.

=head2 run_plugins

    my @plugins = $app->run_plugins(sub { my ( $type, %payload ) = @_; ... });
    my @plugins = $app->run_plugins($on_event, input => sub { ... }, on_stop => sub { ... });

The plugins every raider of the application runs with, as name + {args}
pairs for L<Langertha::Raider/plugins>, with C<$on_event> as the consumer of
L<Langertha::Raider::Plugin::Events>. The main raider's consumer is
L</event>; a subagent passes its own, so its events go to its journal only.
A surface's own plugins (the live trace) are not part of it. In the Claude
layout L<Langertha::Raider::Plugin::ClaudeHooks> reports its hooks to
C<$on_event> too, and gets C<input> and C<on_stop> as L</tool_hook> does.

=head2 session_embeddings

    my $grant = $app->session_embeddings;    # { enabled => 0, reason => ... }

Whether the raider embeds its session history (L<Langertha::Raider/no_session_embeddings>,
ADR 0028): only when a tool that reads the vectors, C<session_history> or
C<raider_session_history>, is mounted. The application mounts none, so each
message would cost an embedding request nothing uses -- noise, cost and, with a
provider without an embeddings endpoint, a 404. C<reason> says why it is off.
Whether the engine can embed is decided by the raider.

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
      # optional, for one run only (see begin_run):
      allow_rules => \@rules, allow_source => $source, model => $model, attach_reads => \@files,
      notification    => 1,           # $text is a notification (ADR 0027)
      reminders       => $blocks,     # notifications in front of $text
      wait_background => 1,           # a run that ends waits for its background agents
    );

Runs C<$text> as one run (L</run>) and records it, whichever surface
asks; the run options of L</begin_run> (a C</name> run's allowed-tools,
model and attached files, L</slash_run_request>) hold for this run only.
It is recorded: in the journal of the L<Langertha::Raider::Session> as the
session's next run (ADR 0015) -- C<run.started>, the user input as
C<message>, every C<tool.call> and C<tool.result> with the whole result
text (and after it a user C<message> a result hands the raid, such as a
loaded skill, ADR 0026), the tokens of a model call a tool makes as
C<model.usage> (C<purpose>, C<model>, C<input_tokens>, C<output_tokens>;
C<web_fetch> with a C<prompt>), the final answer as C<message>, and C<run.finished> with the end
state and the raider's metrics, also when the run failed. A journal write
that fails goes to L</on_journal_error>; the run goes on.

Every event of the run goes to C<on_event> (and L</on_event>) through
L</event>: the journal types and C<run.state> (C<running>, then the end
state), as ADR 0013 names them.

In the Claude layout the run fires the Claude Code hooks (L</hooks>, ADR
0022): C<SessionStart> before the first prompt of a session, the results
of async hooks and C<UserPromptSubmit> before every prompt -- their
context goes in front of the prompt as C<< <system-reminder> >> blocks; a
block ends the run C<failed> with the reason, and the model never sees the
prompt -- and C<Stop> after the answer: a block sends its reason back as
the next user message, at most L</stop_hook_limit> times. Every hook is a
C<hook.ran> event, a C<systemMessage>, a hook error or a stop a
C<hook.message>.

Background subagents (ADR 0027 E<sect>3, E<sect>4): the notifications
that are due when the raider is about to ask the model again go in front of
that request as a user message (journaled as C<message> with
C<notification> 1). C<notification> marks C<$text> itself as such a
message (a REPL turn that only delivers notifications; it runs no
C<UserPromptSubmit>). C<reminders> -- notifications wrapped for a turn of
the user's (L<Langertha::Raider::Tasks/reminder_text>) -- go in front of
the prompt and are journaled before it as a C<message> with
C<notification> 1. With C<wait_background> a run that would end while
background subagents of the main run still run waits for them on the loop
and goes on with their notifications as its next message, until an answer
leaves none (C<raider -p>, the end of piped REPL input); a L</cancel_run>
ends the wait as C<cancelled>.

Returns the outcome as a hash reference: C<status> (C<completed>,
C<failed>, or C<cancelled> after L</cancel_run>), C<elapsed> (seconds, to
the millisecond), C<result> (the L<Langertha::Raider::Result>, also of a
cancelled run), C<response> (its text) and C<metrics> of a completed run,
C<error> of a failed one, C<reason> of one that did not complete (see
L</end_run>; a failed run says C<run_setup> when L</begin_run> croaked,
C<hook_blocked> or C<hook_stopped> when a C<UserPromptSubmit> or
C<SessionStart> hook blocked or stopped it, C<max_iterations> or
C<engine_error> when the raid ended so, else C<error>), and C<session>
(C<id>, C<path>) when there is one. An empty C<$text> runs nothing and
returns nothing.

=head2 is_journal_type

    $app->is_journal_type('tool.call');   # 1

Whether the journal records events of that type from a run (ADR 0015):
C<run.started>, C<message>, C<tool.call>, C<tool.result>, C<todo.updated>,
the C<permission.*> events (ADR 0021), C<hook.ran> and C<hook.message> (ADR
0022), C<agent.started> and C<agent.finished> of the subagents it starts and
C<agent.warning> about them (ADR 0020), C<model.usage> of a tool's own
model call (C<web_fetch>'s prompt, ADR 0026), C<mcp.server> and
C<mcp.tools_changed> of the configured MCP servers (ADR 0029),
C<worktree.entered> (C<path>, C<branch>, C<created>) and C<worktree.exited>
(C<path>, C<branch>, C<removed>, C<reason> C<exit_worktree>, C<clear> or
C<session_end>) of the L</working_root> (ADR 0032 E<sect>6), outside a run
into the session the worktree was entered in. C<run.finished> is written by
L</end_run>.

=head2 begin_run

    $app->begin_run(session => $session, on_event => $consumer);

    # a /name run (L</slash_run_request>):
    $app->begin_run(session => $session, allow_rules => [ 'Bash(git diff:*)' ],
      allow_source => '/review allowed-tools', model => 'sonnet', attach_reads => \@files_read);

Starts a run as L</run_prompt> does, for a surface that drives L</run>
itself: the run gets the next run id of C<session>, C<run.started> and
C<run.state> C<running>. C<run.started> names C<engine> and C<model>,
with a session its id (C<session>) and the run id (C<run>), C<cwd> (the
L</working_root>), C<permission_mode>, C<tools> -- the names the model is
offered, in order; left out while a configured MCP server has not connected
yet, as before the first raid, since L</raid_f> starts them -- and
C<raider_version> (ADR 0034). L</end_run> ends it. When the
L</working_root> moved since the mission was compiled, the mission is
compiled again first (L</reload_mission>), so it names the new working
directory.

The options of one run (ADR 0030 E<sect>3), all undone by L</end_run>:

=over

=item C<allow_rules>, C<allow_source> -- allow rules for this run only
(L<Langertha::Raider::Permissions/add_run_rules>; source default C<run>).
Deny and ask rules still win. L</end_run> clears every run rule, also those
the C<skill> tool added during the run.

=item C<model> -- the model of this run, resolved by L</resolve_run_model>:
when it names one, the raider runs on an engine with that model
(L</build_subagent_engine> over the application's MCP clients) and
C<run.started> names it; L</end_run> puts the engine back. Never saved.

=item C<attach_reads> -- the C<files_read> of a render
(L<Langertha::Raider::SlashCommand/render>): counted as read for
read-before-write, after the read state was emptied for the run.

=back

Croaks when the engine for C<model> cannot be built; the run is begun by
then, so L</run_prompt> ends it C<failed>.

=head2 end_run

    my $end = $app->end_run(interrupted => signal => 'TERM');

Ends the run in progress, if there is one: C<run.finished> with
C<$status>, C<reason> and the given C<error> and C<signal> into the
journal, with the given C<metrics> or else the raider's, then C<run.state>
with C<$status>. C<reason> (ADR 0034) is set whenever C<$status> is not
C<completed>: the C<reason> given, else for C<cancelled> the one
L</cancel_run> recorded (default C<user_cancel>), else C<error> for
C<failed>, C<signal> for C<interrupted>, C<refused> for C<refused>.
It clears the run rules of the policy and puts back the engine a run
C<model> replaced (L</begin_run>), whatever the status. Returns C<status>, C<reason>, C<elapsed>, the C<error> and C<signal> given and, with a
session, C<session> (C<id>, C<path>) -- or nothing outside a run. A
surface calls it for a run it ends itself, as the command line does for a
signal.

=head2 cancel_run

    $app->cancel_run;
    $app->cancel_run( reason => 'hook_stopped' );

Cancels the run in progress (ADR 0009): its raid stops at the next safe
point (L<Langertha::Raider/cancel>) and L</run_prompt> ends the run as
C<cancelled> -- C<run.finished> with that status, and a tool call cut off
gets its C<tool.result> with status C<cancelled>. Every foreground subagent
running for it (L<Langertha::Raider::Subagent>) is cancelled too, with the
subagents it started, and its C<agent> call ends with an error result.
Background subagents keep running (ADR 0027 E<sect>3; L</stop_background>
ends them). C<reason> becomes the run's C<reason> (default C<user_cancel>;
the first cancel of a run names it). Tool subprocesses are not signalled here; that is the surface's to do. Only records the
request, so a signal handler may call it. Outside a run it does nothing
and returns false.

=head2 run_cancelled

True when the current run was cancelled (L</cancel_run>); false outside a
run. A question put to somebody (the hall's permission channel) stops
waiting when it turns true.

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

    my @names = $app->loaded_skill_names;   # ('pdf', 'superpowers:brainstorming')

The names of the skills the mission lists and the C<skill> tool loads
(L<Langertha::Raider::Context::Skills/listed>), in precedence order. For
the banner and status display.

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

=head2 reload_context

    $app->reload_context;
    $app->reload_mission;

Reads the Claude memory, the settings (with their C<env>) and the skills
again (L<Langertha::Raider::Context/reload>) and drops the skill tool, so
the next L</reload_mission> mounts it again over the new catalogue -- or
not at all when no skill is left. The C<agent> tool is dropped the same
way and comes back over the agent files as they are now. C</reload> does both. A pack decided at
the start (the default packs of Claude mode) is not decided again.

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
it customizes the default persona (never with L</bare>); C<claude base>
in Claude mode (L</claude_persona_off>); C<default> otherwise.

=head2 source_label

    my $label = $app->source_label('pack_names');   # 'pack_names', '--pack' in the CLI

How reports name a setting that was passed to the constructor: in
L</explain_config>, L</perl_tools_grant>, L</detection_state>,
L</mission_source> and the pack sources. The keys are C<engine>,
C<model>, C<api_key>, C<engine_options>, C<engine_options packs>,
C<pack_names>, C<no_pack_names>, C<perl>, C<detect>, C<no_detect>,
C<bare>, C<mission>, C<claude>, C<cli_skill_sources>, C<permission_mode>
and C<skip_permissions>. A surface names its own
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
C<--claude>, C<--openai/--skills>), a layer of the config file by its
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
C<session_embeddings> is L</session_embeddings>: whether the session history is
embedded, and why not (ADR 0028).

C<instructions> is L</mission_source> and C<bare> is L</bare>.
C<ignored_instructions_files> are the instructions files that are present
but not used (L<Langertha::Raider::Instructions/ignored_files>): a legacy
F<.raider.md> next to F<.raider/instructions.md>.

C<layout>, C<memory>, C<settings> (only in the Claude layout), C<skills>,
C<shadowed_skills>, C<skill_problems> and C<plugins> are
L<Langertha::Raider::Context/report> of L</context>: the layout mode and
what decided it, the memory files with their imports, the Claude settings
(their files, counts of the permission rules, the names -- never the
values -- of the C<env> keys, the enabled plugins, the hook events, the
keys raider does not use), every skill with its root and whether it is
listed, the skills shadowed by an earlier one of the same name, broken
skill files, and the enabled plugins. C<claude> is among C<values> when
set: by L</claude>, C<claude:> or C<-o claude=>.

C<permissions> is L<Langertha::Raider::Permissions/report> of
L</permissions>: the mode and where it came from, mode names from files
that were ignored, the valid rules per kind with their sources, the
invalid rules and the additional directories.
C<agents>, C<shadowed_agents> and C<agent_problems> come from the same
report (L<Langertha::Raider::Context::Agents/report>): every agent a run
could start (ADR 0020) with its root, its tools in raider names (C<*> for
all), the disallowed ones, the model it would get under this engine and
L</agent_models> (or why it inherits), its declared skills and those that
do not resolve (C<missing_skills>), the tool names
and frontmatter keys raider does not use; the agents shadowed by an earlier
one of the same name; and files in an agent root that are not agents.

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
