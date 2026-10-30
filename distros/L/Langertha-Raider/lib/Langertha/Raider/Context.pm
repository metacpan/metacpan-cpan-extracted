package Langertha::Raider::Context;
# ABSTRACT: Internal context of an application: layout mode, Claude memory and settings, skills, agents
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Path::Tiny;
use Langertha::Raider::Home;
use Langertha::Raider::Context::Layout;
use Langertha::Raider::Context::Memory;
use Langertha::Raider::Context::Settings;
use Langertha::Raider::Context::Plugins;
use Langertha::Raider::Context::Skills;
use Langertha::Raider::Context::Agents;
use Langertha::Raider::SkillResolver;
use Langertha::Raider::SkillResolver::Catalog;
use Langertha::Raider::SkillResolver::Skilletor;


has root => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has bare => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has force_claude => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has config_claude => (
  is => 'ro',
);

has skill_specs => (
  is      => 'ro',
  isa     => 'ArrayRef[HashRef]',
  default => sub { [] },
);

has want_agents_md => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

sub home_class     { 'Langertha::Raider::Home' }
sub layout_class   { 'Langertha::Raider::Context::Layout' }
sub memory_class   { 'Langertha::Raider::Context::Memory' }
sub settings_class { 'Langertha::Raider::Context::Settings' }
sub plugins_class  { 'Langertha::Raider::Context::Plugins' }
sub skills_class   { 'Langertha::Raider::Context::Skills' }
sub agents_class   { 'Langertha::Raider::Context::Agents' }
sub skill_resolver_class   { 'Langertha::Raider::SkillResolver' }
sub catalog_resolver_class { 'Langertha::Raider::SkillResolver::Catalog' }
sub skilletor_resolver_class { 'Langertha::Raider::SkillResolver::Skilletor' }


has home => (
  is         => 'ro',
  isa        => 'Maybe[Str]',
  lazy_build => 1,
);

sub _build_home { $_[0]->home_class->home_dir }

has claude_home => (
  is         => 'ro',
  isa        => 'Maybe[Str]',
  lazy_build => 1,
);

sub _build_claude_home {
  my ( $self ) = @_;
  return unless defined $self->home || length( $ENV{CLAUDE_CONFIG_DIR} // '' );
  my $dir = $self->home_class->claude_home($self->home);
  return defined $dir ? $dir->stringify : undef;
}


has layout => (
  is         => 'ro',
  isa        => 'Langertha::Raider::Context::Layout',
  init_arg   => undef,
  lazy_build => 1,
  handles    => [qw( mode claude_layout )],
);

sub _build_layout {
  my ( $self ) = @_;
  return $self->layout_class->new(
    root          => $self->root,
    home          => $self->home,
    claude_home   => $self->claude_home,
    config_claude => $self->config_claude,
    force_claude  => $self->force_claude ? 1 : 0,
    bare          => $self->bare ? 1 : 0,
  );
}


has memory => (
  is         => 'ro',
  isa        => 'Maybe[Langertha::Raider::Context::Memory]',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_memory {
  my ( $self ) = @_;
  return unless $self->claude_layout;
  return $self->memory_class->new(
    root        => $self->root,
    home        => $self->home,
    claude_home => $self->claude_home,
    walk_dirs   => [ $self->layout->walk_dirs ],
    _delivered  => $self->_nested_delivered,
  );
}

has settings => (
  is         => 'ro',
  isa        => 'Maybe[Langertha::Raider::Context::Settings]',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_settings {
  my ( $self ) = @_;
  return unless $self->claude_layout;
  return $self->settings_class->new(
    project_dir => $self->layout->project_dir->stringify,
    claude_home => $self->claude_home,
  );
}

has plugins => (
  is         => 'ro',
  isa        => 'Maybe[Langertha::Raider::Context::Plugins]',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_plugins {
  my ( $self ) = @_;
  my $settings = $self->settings or return;
  return $self->plugins_class->new(
    cwd         => $self->root,
    claude_home => $self->claude_home,
    enabled     => $settings->enabled_plugin_map,
  );
}


has skill_roots => (
  is         => 'ro',
  isa        => 'ArrayRef[HashRef]',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_skill_roots {
  my ( $self ) = @_;
  return [] if $self->bare;
  my $root = path($self->root)->absolute;
  my @roots;
  for my $spec (@{ $self->skill_specs }) {
    my $rel = $spec->{path};
    next unless defined $rel && !ref $rel && length $rel;
    my $dir  = path($rel)->absolute($root);
    my $type = $spec->{type} // 'dir';
    $type = 'file' if $type eq 'dir' && -f $dir;   # --skills FILE
    if ($type eq 'file') {
      push @roots, { dir => $dir->parent->stringify, file => $dir->stringify, source => $rel, layout => 'file' };
      next;
    }
    my @layouts = $type eq 'claude' ? ('skills')
      : $type eq 'dir' ? ( defined $spec->{glob} ? ('flat') : qw( skills flat ) )
      : ();
    push @roots, map { { dir => $dir->stringify, source => $rel, layout => $_ } } @layouts;
  }
  push @roots, {
    dir    => $self->home_class->project_base($root)->child('skills')->stringify,
    source => $self->home_class->dir_name.'/skills',
    layout => 'skills',
  };
  if (defined $self->home) {
    push @roots, {
      dir    => $self->home_class->home_base($self->home)->child('skills')->stringify,
      source => '~/'.$self->home_class->dir_name.'/skills',
      layout => 'skills',
    };
  }
  if ($self->claude_layout) {
    if (defined( my $ch = $self->claude_home )) {
      my $dir = path($ch)->child('skills');
      push @roots, { dir => $dir->stringify, source => $self->_home_label($dir), layout => 'skills' };
    }
    my $project = $self->layout->project_dir;
    for my $sub (qw( .claude .agents )) {
      my $dir = $project->child($sub, 'skills');
      push @roots, { dir => $dir->stringify, source => $self->_root_label($dir), layout => 'skills', base => $project->stringify };
    }
    # Nested .claude/skills met while working below root (nested_reminders_for).
    push @roots, @{ $self->_nested_skill_roots };
  }
  push @roots, $self->command_roots;
  my %seen;
  return [ grep { !$seen{ $self->_real($_->{file} // $_->{dir}).' '.$_->{layout} }++ } @roots ];
}


sub command_roots {
  my ( $self ) = @_;
  return if $self->bare;
  my $home_class = $self->home_class;
  my @roots = ( {
    dir    => $home_class->project_base(path($self->root)->absolute)->child('commands')->stringify,
    source => $home_class->dir_name.'/commands',
    layout => 'commands',
  } );
  push @roots, {
    dir    => $home_class->home_base($self->home)->child('commands')->stringify,
    source => '~/'.$home_class->dir_name.'/commands',
    layout => 'commands',
  } if defined $self->home;
  if ($self->claude_layout) {
    if (defined( my $ch = $self->claude_home )) {
      my $dir = path($ch)->child('commands');
      push @roots, { dir => $dir->stringify, source => $self->_home_label($dir), layout => 'commands' };
    }
    my $project = $self->layout->project_dir;
    my $dir = $project->child('.claude', 'commands');
    push @roots, { dir => $dir->stringify, source => $self->_root_label($dir), layout => 'commands', base => $project->stringify };
  }
  return @roots;
}


has skill_catalog => (
  is         => 'ro',
  isa        => 'Langertha::Raider::Context::Skills',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_skill_catalog {
  my ( $self ) = @_;
  my $plugins = $self->plugins;
  return $self->skills_class->new(
    roots     => $self->skill_roots,
    base      => $self->root,
    activated => $self->_activated_skills,
    plugins   => $plugins
      ? [ map { {
          name     => $_->{name},
          root     => $_->{root},
          dirs     => [ $plugins->skill_dirs($_) ],
          commands => [ $plugins->command_dirs($_) ],
        } } @{ $plugins->plugins } ]
      : [],
  );
}

sub has_listed_skills { scalar( () = $_[0]->skill_catalog->listed ) ? 1 : 0 }

sub skill_tool_wanted {
  my ( $self ) = @_;
  return 0 if $self->bare;
  return 1 if $self->claude_layout;
  return scalar( () = $self->skill_catalog->invocable ) ? 1 : 0;
}

# Kept across a reload: the names of path-activated skills, the nested
# skill roots found, and the roots already looked at.
has _activated_skills => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { {} },
);

has _nested_skill_roots => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { [] },
);

has _nested_skill_dirs_seen => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { {} },
);

has skill_resolver => (
  is         => 'ro',
  isa        => 'Langertha::Raider::SkillResolver',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_skill_resolver {
  my ( $self ) = @_;
  return $self->skill_resolver_class->new( resolvers => [ $self->skill_resolvers ] );
}

sub skill_resolvers {
  my ( $self ) = @_;
  return (
    $self->catalog_resolver_class->new( catalog => $self->skill_catalog ),
    ( $self->claude_layout && defined $self->home ? $self->skilletor_resolver_class->new(
      home        => $self->home,
      project_dir => $self->layout->project_dir->stringify,
    ) : () ),
  );
}


has agent_roots => (
  is         => 'ro',
  isa        => 'ArrayRef[HashRef]',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_agent_roots {
  my ( $self ) = @_;
  return [] if $self->bare;
  my $home_class = $self->home_class;
  my @roots = ( {
    dir    => $home_class->project_base(path($self->root)->absolute)->child('agents')->stringify,
    source => $home_class->dir_name.'/agents',
  } );
  push @roots, {
    dir    => $home_class->home_base($self->home)->child('agents')->stringify,
    source => '~/'.$home_class->dir_name.'/agents',
  } if defined $self->home;
  if ($self->claude_layout) {
    my $dir = $self->layout->project_dir->child('.claude', 'agents');
    push @roots, { dir => $dir->stringify, source => $self->_root_label($dir) };
    if (defined( my $ch = $self->claude_home )) {
      my $user = path($ch)->child('agents');
      push @roots, { dir => $user->stringify, source => $self->_home_label($user) };
    }
  }
  my %seen;
  return [ grep { !$seen{ $self->_real($_->{dir}) }++ } @roots ];
}


has agent_catalog => (
  is         => 'ro',
  isa        => 'Langertha::Raider::Context::Agents',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_agent_catalog {
  my ( $self ) = @_;
  my $plugins = $self->plugins;
  return $self->agents_class->new(
    roots   => $self->agent_roots,
    plugins => $plugins
      ? [ map { { name => $_->{name}, dirs => [ $plugins->agent_dirs($_) ] } } @{ $plugins->plugins } ]
      : [],
  );
}


has agents_md => (
  is         => 'ro',
  isa        => 'Maybe[HashRef]',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_agents_md {
  my ( $self ) = @_;
  return if $self->bare || !$self->want_agents_md;
  my $file = path($self->root)->absolute->child('AGENTS.md');
  return unless -f $file;
  my $real = $self->_real($file);
  if (my $memory = $self->memory) {
    return if grep { $_->{file} eq $real } @{ $memory->items };
  }
  my $text = eval { $file->slurp_utf8 };
  return unless defined $text && $text =~ /\S/;
  return {
    file    => $real,
    label   => 'AGENTS.md',
    scope   => 'project',
    kind    => 'AGENTS.md',
    text    => $text,
    imports => [],
  };
}


sub instruction_items {
  my ( $self ) = @_;
  my $memory = $self->memory;
  return ( ( $memory ? @{ $memory->items } : () ), $self->agents_md // () );
}


sub memory_header {
  'Codebase and user instructions are shown below. Be sure to adhere to these instructions.'
    .' IMPORTANT: These instructions OVERRIDE any default behavior and you MUST follow them'
    .' exactly as written.';
}

sub prompt_items {
  my ( $self ) = @_;
  my @items;
  if (my $memory = $self->memory) {
    my $text = $memory->prompt_text;
    push @items, $self->memory_header."\n\n".$text if defined $text;
  }
  if (my $agents = $self->agents_md) {
    ( my $text = $agents->{text} ) =~ s/\s+\z//;
    push @items, 'Contents of '.$agents->{file}." (project instructions (AGENTS.md)):\n\n".$text;
  }
  my $skills = $self->skill_catalog->prompt_text;
  push @items, $skills if defined $skills;
  return @items;
}


has applied_env => (
  is       => 'ro',
  isa      => 'ArrayRef[Str]',
  init_arg => undef,
  default  => sub { [] },
);

has _env_done => (
  is       => 'rw',
  isa      => 'Bool',
  init_arg => undef,
  default  => 0,
);

# What the environment held before apply_env set a key: { KEY => value|undef }.
has _env_before => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { {} },
);

sub apply_env {
  my ( $self ) = @_;
  unless ($self->_env_done) {
    $self->_env_done(1);
    my $values = $self->settings ? $self->settings->env_values : {};
    # A key an earlier run set that the settings no longer carry: back to what it was.
    for my $key (grep { !exists $values->{$_} } @{ $self->applied_env }) {
      my $before = delete $self->_env_before->{$key};
      defined $before ? ( $ENV{$key} = $before ) : delete $ENV{$key};
    }
    @{ $self->applied_env } = ();
    for my $key (sort keys %$values) {
      $self->_env_before->{$key} = $ENV{$key} unless exists $self->_env_before->{$key};
      $ENV{$key} = $values->{$key};
      push @{ $self->applied_env }, $key;
    }
  }
  return @{ $self->applied_env };
}


sub reload {
  my ( $self ) = @_;
  $self->$_ for qw( clear_layout clear_memory clear_settings clear_plugins
    clear_skill_roots clear_skill_catalog clear_skill_resolver clear_agent_roots
    clear_agent_catalog clear_agents_md );
  $self->_env_done(0);
  $self->apply_env;
  return $self;
}

has _nested_delivered => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { {} },
);


sub nested_memory_for {
  my ( $self, $path ) = @_;
  my $memory = $self->memory or return;
  my $text = $memory->nested_text($memory->nested_for($path));
  return $text;
}


sub nested_skills_for {
  my ( $self, $path ) = @_;
  return if $self->bare;
  return unless defined $path && length $path;
  my $root   = path($self->_real($self->root));
  my $target = path($self->_real(path($path)->absolute($root)));
  return unless $root->subsumes($target);
  my $catalog = $self->skill_catalog;
  my @new;
  if ($self->claude_layout) {
    my $dir = -d $target ? $target : $target->parent;
    my @dirs;
    while ($dir->stringify ne $root->stringify && $root->subsumes($dir)) {
      unshift @dirs, $dir;
      $dir = $dir->parent;
    }
    my @roots;
    for my $d (@dirs) {
      my $skills = $d->child('.claude', 'skills');
      next unless -d $skills;
      next if $self->_nested_skill_dirs_seen->{ $skills->stringify }++;
      my $found = {
        dir    => $skills->stringify,
        source => $self->_root_label($skills),
        layout => 'skills',
        base   => $d->stringify,
      };
      push @{ $self->_nested_skill_roots }, $found;
      push @roots, $found;
    }
    push @new, $catalog->add_roots(@roots) if @roots;
  }
  push @new, $catalog->activate_for($target->stringify);
  my %seen;
  return $catalog->announce_text(grep { $catalog->is_listed($_) && !$seen{ $_->{name} }++ } @new);
}

sub nested_reminders_for {
  my ( $self, $path ) = @_;
  return grep { defined } $self->nested_memory_for($path), $self->nested_skills_for($path);
}


sub report {
  my ( $self, %arg ) = @_;
  my $layout = $self->layout;
  my $agents = $self->agent_catalog->report(%arg);
  my $claude = $self->claude_layout ? 1 : 0;
  my $catalog = $self->skill_catalog;
  my $plugins = $self->plugins;
  return {
    layout => {
      mode                 => $layout->mode,
      reason               => $layout->reason,
      claude_layout        => $claude,
      claude_layout_reason => $layout->claude_layout_reason,
      project_dir          => $claude ? $layout->project_dir->stringify : undef,
    },
    memory => [ map { {
      label   => $_->{label},
      scope   => $_->{scope},
      kind    => $_->{kind},
      imports => [ @{ $_->{imports} } ],
    } } $self->instruction_items ],
    ( $self->settings ? ( settings => $self->_settings_report ) : () ),
    skills          => [ map { my $s = $_; my @paths = $catalog->paths_of($s); +{ name => $s->{name}, source => $s->{source}, listed => $catalog->is_listed($s) ? 1 : 0, ( @paths ? ( paths => [ @paths ] ) : () ), ( $s->{kind} eq 'command' ? ( kind => 'command' ) : () ) } } $catalog->skills ],
    shadowed_skills => [ map { { name => $_->{name}, source => $_->{source}, by => $_->{by} } } $catalog->shadowed ],
    skill_problems  => [ map { { file => $_->{file}, reason => $_->{reason} } } $catalog->problems ],
    plugins         => $plugins ? [ map { { name => $_->{name}, key => $_->{key}, scope => $_->{scope} } } @{ $plugins->plugins } ] : [],
    agents          => [ map { $self->_with_missing_skills($_) } @{ $agents->{agents} } ],
    shadowed_agents => $agents->{shadowed},
    agent_problems  => $agents->{problems},
  };
}

# An agent of the report with its declared skills that do not resolve (and
# why, where a resolver says), and where those beyond the catalogue resolved.
sub _with_missing_skills {
  my ( $self, $agent ) = @_;
  my $resolver = $self->skill_resolver;
  my ( @missing, %reasons, %via );
  for my $name (@{ $agent->{skills} }) {
    if (my $skill = $resolver->resolve($name)) {
      $via{$name} = $skill->{via} if defined $skill->{via};
      next;
    }
    push @missing, $name;
    my $why = $resolver->why_unresolved($name);
    $reasons{$name} = $why if defined $why;
  }
  return { %$agent, missing_skills => \@missing, missing_reasons => \%reasons, skill_via => \%via };
}

sub _settings_report {
  my ( $self ) = @_;
  my $s = $self->settings;
  my $p = $s->permissions;
  my $enabled = $s->enabled_plugin_map;
  my $hooks = $s->hooks;
  return {
    files       => [ map { { label => $_->{label}, exists => $_->{exists}, error => $_->{error} } } @{ $s->files } ],
    permissions => {
      ( map { $_ => scalar @{ $p->{$_} } } qw( allow ask deny additional_directories ) ),
      default_mode => $p->{default_mode} ? $p->{default_mode}{value} : undef,
    },
    env             => [ sort keys %{ $s->env } ],
    enabled_plugins => [ sort grep { $enabled->{$_} } keys %$enabled ],
    hooks           => { map { $_ => scalar @{ $hooks->{$_} } } keys %$hooks },
    ignored         => [ map { { key => $_->{key}, source => $_->{source} } } @{ $s->ignored } ],
  };
}

# A directory as reports name it: relative to root inside it, ~/... under
# the home, else absolute.
sub _root_label {
  my ( $self, $dir ) = @_;
  my $root = path($self->_real($self->root));
  my $real = path($self->_real($dir));
  return $real->relative($root)->stringify if $root->subsumes($real);
  return $self->_home_label($dir);
}

sub _home_label {
  my ( $self, $dir ) = @_;
  my $real = path($self->_real($dir));
  if (defined $self->home) {
    my $home = path($self->_real($self->home));
    return '~/'.$real->relative($home)->stringify if $home->subsumes($real);
  }
  return $real->stringify;
}

# The real path of $p as a string; for a path that does not exist, the real
# path of its nearest existing ancestor with the rest appended.
sub _real {
  my ( $self, $p ) = @_;
  my $path = path($p)->absolute;
  my @rest;
  until (-e $path || $path->is_rootdir) {
    unshift @rest, $path->basename;
    $path = $path->parent;
  }
  my $real = eval { $path->realpath } // $path;
  return ( @rest ? $real->child(@rest) : $real )->stringify;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Context - Internal context of an application: layout mode, Claude memory and settings, skills, agents

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $context = Langertha::Raider::Context->new(
      root           => $root,
      config_claude  => $options->{claude},     # undef when not set
      force_claude   => $opt{claude},           # --claude
      skill_specs    => [ { type => 'dir', path => 'my-skills' } ],
      want_agents_md => $opt{openai},           # --openai / --codex
    );
    $context->apply_env;                        # settings env into %ENV, once
    my @items = $context->prompt_items;         # memory, AGENTS.md, skill listing
    my $skills = $context->skill_catalog;       # Langertha::Raider::Context::Skills
    my $agents = $context->agent_catalog;       # Langertha::Raider::Context::Agents
    my $skill  = $context->skill_resolver->resolve('pdf');   # { name, dir, file } or undef
    my $more  = $context->nested_memory_for('lib/Foo.pm');   # or undef
    my @notes = $context->nested_reminders_for('lib/Foo.pm');  # CLAUDE.md, skills
    $context->reload;                           # /reload: read it all again
    my $report = $context->report;              # for config explain

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Everything ADR 0019 adds to what raider reads from a workspace, behind one
object per application: the layout mode
(L<Langertha::Raider::Context::Layout>), and in the Claude layout the
memory files (L<Langertha::Raider::Context::Memory>), the settings
(L<Langertha::Raider::Context::Settings>) and the enabled plugins
(L<Langertha::Raider::Context::Plugins>); the F<AGENTS.md> of C<--openai>;
and the skill catalogue (L<Langertha::Raider::Context::Skills>) with its
roots in the precedence of ADR 0019 E<sect>4:

=over

=item 1. L</skill_specs>, in their order. C<< { type => 'claude', path } >>
is a directory of skill directories (F<*/SKILL.md>);
C<< { type => 'file', path } >> one skill file (so is a C<dir> spec naming a
file);
C<< { type => 'dir', path, glob } >> a directory of flat F<*.md> skills;
C<< { type => 'dir', path } >> without C<glob> (C<--skills DIR>, a string
in C<skills:>) is both. A relative path is relative to L</root>.

=item 2. F<.raider/skills> of L</root>, then F<~/.raider/skills>.

=item 3. Only in the Claude layout: F<< <claude_home>/skills >>, then
F<.claude/skills> and F<.agents/skills> of the project directory
(L<Langertha::Raider::Context::Layout/project_dir>), then the skills of
every installed and enabled plugin as C<plugin:skill>.

=item 4. The command roots (L</command_roots>, ADR 0030 E<sect>1), and in
the Claude layout the commands of every plugin as C<plugin:name>. A skill
beats a command of its name, wherever the command stands.

=back

Skills can also arrive during a session: the F<.claude/skills> of a subtree
a tool touches, and skills with C<paths:> frontmatter once a matching file is
touched (L</nested_skills_for>, ADR 0019 Addendum 1).

A directory that appears twice is read once, at its first place.

The agent catalogue (L<Langertha::Raider::Context::Agents>) has its roots
in the precedence of ADR 0020 E<sect>1 (L</agent_roots>).

With L</bare> nothing is read at all: mode C<bare>, no memory, no settings,
no skills, no agent files (only the built-in agents C<general-purpose>,
C<Explore> and C<Plan>), no
F<AGENTS.md>.

=head2 root

The project directory. Required.

=head2 bare

C<--bare> (ADR 0014): no layout, nothing read.

=head2 force_claude

C<--claude>: the Claude layout is read in every mode but C<bare>.

=head2 config_claude

The effective C<claude:> of the configuration (true, false or C<undef>
when not set); the legacy C<skills: [claude]> counts as true. Read by
truth, so YAML and JSON booleans work. Decides the Claude layout in a
raider project (L<Langertha::Raider::Context::Layout/claude_layout>).

=head2 skill_specs

The explicit skill directories, highest precedence first, as
L<Langertha::Raider::Config/skill_specs> normalizes them. Defaults to
none.

=head2 want_agents_md

True for C<--openai> / C<--codex> or C<skills: [openai]> (also C<codex>,
C<agents>): F<AGENTS.md> of L</root> is an instructions item (unless the
Claude memory already loaded that very file).

=head2 home

The user's home directory, by default L<Langertha::Raider::Home/home_dir>.

=head2 claude_home

The Claude Code directory, by default
L<Langertha::Raider::Home/claude_home> of L</home>. Every part gets this
one, so they agree.

=head2 layout

The L<Langertha::Raider::Context::Layout> of L</root>.

=head2 mode

L<Langertha::Raider::Context::Layout/mode>: C<bare>, C<raider>, C<claude>
or C<native>.

=head2 claude_layout

L<Langertha::Raider::Context::Layout/claude_layout>: whether memory,
settings, plugins and the Claude skill roots are read.

=head2 memory

The L<Langertha::Raider::Context::Memory> in the Claude layout, else
C<undef>.

=head2 settings

The L<Langertha::Raider::Context::Settings> of the project directory in
the Claude layout, else C<undef>.

=head2 plugins

The L<Langertha::Raider::Context::Plugins> (installed and enabled by the
settings) in the Claude layout, else C<undef>.

=head2 skill_roots

The skill roots in precedence order (see L</DESCRIPTION>), each
C<< { dir, source, layout } >> as L<Langertha::Raider::Context::Skills/roots>
takes them, closed by the L</command_roots>. Roots that do not exist are
listed too; the catalogue skips them.

=head2 command_roots

    my @roots = $context->command_roots;

The command roots (ADR 0030 E<sect>1), layout C<commands>, in precedence
order: F<.raider/commands> of L</root>, then F<~/.raider/commands>; only
in the Claude layout F<< <claude_home>/commands >>, then
F<.claude/commands> of the project directory (personal before project, as
for the Claude skill roots). They close L</skill_roots>: a skill beats a
command of its name anyway, so only their order among themselves matters.
None with L</bare>.

=head2 skill_catalog

The L<Langertha::Raider::Context::Skills> over L</skill_roots> and, in the
Claude layout, the skill directories and command paths of L</plugins>
(L<Langertha::Raider::Context::Plugins/command_dirs>).

=head2 has_listed_skills

True when the catalogue lists at least one skill to the model.

=head2 skill_tool_wanted

True when the C<skill> tool is mounted: in the Claude layout always (a
nested F<.claude/skills> or a skill with C<paths:> can bring skills in
later in the session, as in Claude Code), elsewhere when the catalogue
holds a skill the model can invoke, now or once a file activates it.

=head2 skill_resolver

The L<Langertha::Raider::SkillResolver> that briefs agents (ADR 0020
E<sect>6): the chain of L</skill_resolvers>.

=head2 skill_resolvers

The resolvers of L</skill_resolver>, first asked first: the skill
catalogue (L<Langertha::Raider::SkillResolver::Catalog> over
L</skill_catalog>, skills that are not model-invocable included), then,
only in the Claude layout, the skills the F<skilletor.json> files declare,
read from their sources without installing
(L<Langertha::Raider::SkillResolver::Skilletor>; a source is fetched only
when it has no cache yet). A native or bare context has the catalogue
alone: F<skilletor.json> is Claude Code configuration.

=head2 agent_roots

The agent roots in precedence order (ADR 0020 E<sect>1), each
C<< { dir, source } >> as L<Langertha::Raider::Context::Agents/roots> takes
them: F<.raider/agents> of L</root>, then F<~/.raider/agents>; only in the
Claude layout F<.claude/agents> of the project directory, then
F<< <claude_home>/agents >>. Roots that do not exist are listed too; the
catalogue skips them. None with L</bare>.

=head2 agent_catalog

The L<Langertha::Raider::Context::Agents> over L</agent_roots> and, in the
Claude layout, the agent paths of L</plugins>
(L<Langertha::Raider::Context::Plugins/agent_dirs>), named C<plugin:agent>.

=head2 agents_md

The F<AGENTS.md> instructions item of L</want_agents_md>, or C<undef>: the
file is absent or empty, L</bare>, or the Claude memory already holds it.
A hash with C<file>, C<label>, C<scope> (C<project>), C<kind>
(C<AGENTS.md>), C<text> and C<imports> (none), the shape of
L<Langertha::Raider::Context::Memory/items>.

=head2 instruction_items

    for my $item ($context->instruction_items) { say $item->{label} }

The memory items of the Claude layout, then L</agents_md> -- every
instructions file this context puts into the prompt.

=head2 prompt_items

    my @texts = $context->prompt_items;

The context items of the system prompt, in order, each a string: the Claude
memory (under the header Claude Code puts over it, see
L</memory_header>), the F<AGENTS.md> item, the skill listing
(L<Langertha::Raider::Context::Skills/prompt_text>). Items without content
are left out.

=head2 memory_header

The line above the Claude memory files, as Claude Code words it.

=head2 apply_env

    my @keys = $context->apply_env;

Sets the C<env> of the Claude settings (ADR 0019 E<sect>3) in C<%ENV> of
this process, so tools and their subprocesses see it, as in Claude Code; a
value there replaces the one in the environment. Runs once per object --
later calls only return the keys. Nothing outside the Claude layout.
Returns the names of the keys set (L</applied_env>).

=head2 applied_env

The names of the environment variables L</apply_env> set, sorted.

=head2 reload

    $context->reload;

Reads everything again that was read from disk: the layout mode, the
memory files, the settings (and their C<env>, applied again -- a key the
settings no longer carry gets back the value it had before), the enabled
plugins, the skill catalogue and the agent catalogue, as C</reload> in the
REPL does. What was decided from the constructor arguments (C<--claude>, C<claude:>, C<--bare>,
the explicit skill directories) stays. The nested F<CLAUDE.md> files
already handed out in this session are not handed out again. Returns the
object.

=head2 nested_memory_for

    my $text = $context->nested_memory_for('sub/dir/file.txt');

The F<CLAUDE.md> files below L</root> on the way to C<$path> that were not
handed out before (L<Langertha::Raider::Context::Memory/nested_for>),
formatted for a tool result; C<undef> when there is none, outside the
Claude layout and for a path outside L</root>.

=head2 nested_skills_for

    my $text = $context->nested_skills_for('sub/dir/file.txt');

The skills that became available because a tool touched C<$path>, as a
note for a tool result (L<Langertha::Raider::Context::Skills/announce_text>),
or C<undef> for none: the F<.claude/skills> of the directories below
L</root> on the way to C<$path> (Claude layout only, each looked at once;
their skills come after all others and lose a name that is taken), and the
skills whose C<paths:> glob matches C<$path>
(L<Langertha::Raider::Context::Skills/activate_for>). A skill is announced
once per session, a reload included. Nothing for a path outside
L</root>, and nothing with L</bare>.

=head2 nested_reminders_for

    my @texts = $context->nested_reminders_for($path);

What a tool result gets for touching C<$path>: L</nested_memory_for>, then
L</nested_skills_for> -- each its own text, none for what is empty.

=head2 report

    my $report = $context->report(engine_class => $class, engine_name => 'openai', agent_models => {});

What C<config explain> shows of the context, plain data (JSON-safe):

    {
      layout => { mode, reason, claude_layout => 0|1, claude_layout_reason,
                  project_dir => '/abs' | undef },
      memory => [ { label, scope, kind, imports => [ '/abs', ... ] }, ... ],
      settings => {                     # only in the Claude layout
        files       => [ { label, exists => 0|1, error => undef|'...' }, ... ],
        permissions => { allow => N, ask => N, deny => N,
                         additional_directories => N, default_mode => undef|'...' },
        env         => [ 'NAME', ... ],                  # names only, never values
        enabled_plugins => [ 'name@market', ... ],       # enabled ones
        hooks       => { PreToolUse => N, ... },         # matcher groups per event
        ignored     => [ { key, source }, ... ],
      },
      skills          => [ { name, source, listed => 0|1,
                             paths => [ ... ],        # only with paths:
                             kind => 'command' }, ... ],   # only for commands
      shadowed_skills => [ { name, source, by }, ... ],
      skill_problems  => [ { file, reason }, ... ],
      plugins         => [ { name, key, scope }, ... ],
      agents          => [ { name, source, file, tools, disallowed, model,
                             skills, missing_skills, missing_reasons, skill_via,
                             unknown_tools, ignored_keys }, ... ],
      shadowed_agents => [ { name, source, file, by }, ... ],
      agent_problems  => [ { file, reason }, ... ],
    }

C<memory> includes the F<AGENTS.md> item. C<agents>, C<shadowed_agents>
and C<agent_problems> are L<Langertha::Raider::Context::Agents/report>;
the arguments go there, for the model each agent would get. Each agent's
C<missing_skills> lists the declared skills L</skill_resolver> does not
resolve: the agent tool refuses to start that agent (ADR 0020 E<sect>6).
C<missing_reasons> gives, per missing skill, the reason a resolver knows
(L<Langertha::Raider::SkillResolver/why_unresolved>, e.g. a skilletor
template); C<skill_via>, per declared skill resolved beyond the catalogue,
where (C<skilletor:E<lt>sourceE<gt>>).

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Application/context>

=item * L<Langertha::Raider::SkillTools>

=item * L<Langertha::Raider::Plugin::NestedMemory>

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
