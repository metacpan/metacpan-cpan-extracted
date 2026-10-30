package Langertha::Raider::Context::Settings;
# ABSTRACT: Internal reader of the Claude Code settings files (user, project, local)
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use JSON::MaybeXS qw( is_bool );
use Path::Tiny;
use Langertha::Raider::Home;


has project_dir => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has claude_home => (
  is         => 'ro',
  isa        => 'Maybe[Str]',
  lazy_build => 1,
);

sub home_class { 'Langertha::Raider::Home' }

sub _build_claude_home {
  my ( $self ) = @_;
  my $dir = $self->home_class->claude_home;
  return defined $dir ? $dir->stringify : undef;
}

# The settings keys raider uses; everything else is listed by ignored().
my %USED = map { $_ => 1 } qw( permissions hooks disableAllHooks disableSkillShellExecution env enabledPlugins
  enableAllProjectMcpServers enabledMcpjsonServers disabledMcpjsonServers skipDangerousModePermissionPrompt
  worktree );

# The three files with their data, in read order. Each entry is
# { file, label, scope, exists, error, data }; data is the decoded object,
# or undef when the file is missing or broken.
has _loaded => (
  is         => 'ro',
  isa        => 'ArrayRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build__loaded {
  my ( $self ) = @_;
  my @candidates;
  if (defined( my $home = $self->claude_home )) {
    my $file = path($home)->absolute->child('settings.json');
    push @candidates, [ $file, $self->_user_label($file), 'user' ];
  }
  my $dot = path($self->project_dir)->absolute->child('.claude');
  push @candidates,
    [ $dot->child('settings.json'),       '.claude/settings.json',       'project' ],
    [ $dot->child('settings.local.json'), '.claude/settings.local.json', 'local' ];
  return [ map { $self->_load(@$_) } @candidates ];
}

# ~/... when the file lives under the home directory, else its absolute path.
sub _user_label {
  my ( $self, $file ) = @_;
  my $home = $self->home_class->home_dir;
  if (defined $home) {
    my $base = path($home)->absolute;
    return '~/'.$file->relative($base) if $base->subsumes($file);
  }
  return $file->stringify;
}

sub _load {
  my ( $self, $file, $label, $scope ) = @_;
  my %entry = (
    file   => $file->stringify,
    label  => $label,
    scope  => $scope,
    exists => -e $file ? 1 : 0,
    error  => undef,
    data   => undef,
  );
  return \%entry unless $entry{exists};
  my $raw = eval { $file->slurp_raw };
  unless (defined $raw) {
    $entry{error} = 'unreadable: '.$self->_one_line($@ || 'not a file');
    return \%entry;
  }
  my $data = eval { JSON::MaybeXS->new( utf8 => 1 )->decode($raw) };
  if (my $err = $@) {
    $entry{error} = 'invalid JSON: '.$self->_one_line($err);
  }
  elsif (ref $data ne 'HASH') {
    $entry{error} = 'not a JSON object';
  }
  else {
    $entry{data} = $data;
  }
  return \%entry;
}

# First line of an error, without Perl's " at FILE line N." trailer.
sub _one_line {
  my ( $self, $error ) = @_;
  my ( $line ) = split /\n/, "$error";
  $line //= '';
  $line =~ s/ at (?:(?! at ).)+ line \d+\.?\z//;
  return $line;
}

# [ data, label ] of every file that loaded, in read order.
sub _sources {
  my ( $self ) = @_;
  return map { [ $_->{data}, $_->{label} ] } grep { $_->{data} } @{ $self->_loaded };
}

sub _is_string { defined $_[1] && !ref $_[1] }


has files => (
  is         => 'ro',
  isa        => 'ArrayRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_files {
  my ( $self ) = @_;
  return [ map {
    my %f = %$_;
    delete $f{data};
    \%f;
  } @{ $self->_loaded } ];
}


has permissions => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_permissions {
  my ( $self ) = @_;
  my %out = (
    allow                  => [],
    ask                    => [],
    deny                   => [],
    default_mode           => undef,
    additional_directories => [],
  );
  for my $src ($self->_sources) {
    my ( $data, $label ) = @$src;
    my $perms = $data->{permissions};
    next unless ref $perms eq 'HASH';
    for my $kind (qw( allow ask deny )) {
      my $list = $perms->{$kind};
      next unless ref $list eq 'ARRAY';
      push @{ $out{$kind} }, map { { rule => $_, source => $label } }
        grep { $self->_is_string($_) && length } @$list;
    }
    if (ref $perms->{additionalDirectories} eq 'ARRAY') {
      push @{ $out{additional_directories} }, map { { path => $_, source => $label } }
        grep { $self->_is_string($_) && length } @{ $perms->{additionalDirectories} };
    }
    my $mode = $perms->{defaultMode};
    $out{default_mode} = { value => $mode, source => $label }
      if $self->_is_string($mode) && length $mode;
  }
  return \%out;
}


has hooks => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_hooks {
  my ( $self ) = @_;
  my %out;
  for my $src ($self->_sources) {
    my ( $data, $label ) = @$src;
    my $hooks = $data->{hooks};
    next unless ref $hooks eq 'HASH';
    for my $event (sort keys %$hooks) {
      my $groups = $hooks->{$event};
      next unless ref $groups eq 'ARRAY';
      for my $g (grep { ref $_ eq 'HASH' } @$groups) {
        push @{ $out{$event} }, {
          matcher => $self->_is_string($g->{matcher}) ? $g->{matcher} : undef,
          hooks   => ref $g->{hooks} eq 'ARRAY' ? $g->{hooks} : [],
          source  => $label,
        };
      }
    }
  }
  return \%out;
}


has disable_all_hooks => (
  is         => 'ro',
  isa        => 'Bool',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_disable_all_hooks {
  my ( $self ) = @_;
  my $off = 0;
  for my $src ($self->_sources) {
    my $value = $src->[0]{disableAllHooks};
    $off = $value ? 1 : 0 if is_bool($value);
  }
  return $off;
}


sub skip_dangerous_mode_prompt {
  my ( $self ) = @_;
  my ( $user ) = grep { $_->{scope} eq 'user' && $_->{data} } @{ $self->_loaded };
  return 0 unless $user;
  my $value = $user->{data}{skipDangerousModePermissionPrompt};
  return is_bool($value) && $value ? 1 : 0;
}


has disable_skill_shell_execution => (
  is         => 'ro',
  isa        => 'Bool',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_disable_skill_shell_execution {
  my ( $self ) = @_;
  my $off = 0;
  for my $src ($self->_sources) {
    my $value = $src->[0]{disableSkillShellExecution};
    $off = $value ? 1 : 0 if is_bool($value);
  }
  return $off;
}


has env => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_env {
  my ( $self ) = @_;
  my %out;
  for my $src ($self->_sources) {
    my ( $data, $label ) = @$src;
    my $env = $data->{env};
    next unless ref $env eq 'HASH';
    for my $key (keys %$env) {
      my $value = $env->{$key};
      next unless $self->_is_string($value);
      $out{$key} = { value => ''.$value, source => $label };
    }
  }
  return \%out;
}

sub env_values {
  my ( $self ) = @_;
  my $env = $self->env;
  return { map { $_ => $env->{$_}{value} } keys %$env };
}


has enabled_plugins => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_enabled_plugins {
  my ( $self ) = @_;
  my %out;
  for my $src ($self->_sources) {
    my ( $data, $label ) = @$src;
    my $ep = $data->{enabledPlugins};
    next unless ref $ep eq 'HASH';
    for my $key (keys %$ep) {
      next unless is_bool($ep->{$key});
      $out{$key} = { value => $ep->{$key} ? 1 : 0, source => $label };
    }
  }
  return \%out;
}

sub enabled_plugin_map {
  my ( $self ) = @_;
  my $ep = $self->enabled_plugins;
  return { map { $_ => $ep->{$_}{value} } keys %$ep };
}


has mcpjson_approvals => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_mcpjson_approvals {
  my ( $self ) = @_;
  my %out = ( enable_all => [], enabled => [], disabled => [] );
  for my $file (grep { $_->{data} } @{ $self->_loaded }) {
    my ( $data, $label, $scope ) = @{$file}{qw( data label scope )};
    my $all = $data->{enableAllProjectMcpServers};
    push @{ $out{enable_all} }, { value => $all ? 1 : 0, source => $label, scope => $scope }
      if is_bool($all);
    for my $kind (qw( enabled disabled )) {
      my $list = $data->{$kind.'McpjsonServers'};
      next unless ref $list eq 'ARRAY';
      push @{ $out{$kind} }, map { { name => $_, source => $label, scope => $scope } }
        grep { $self->_is_string($_) && length } @$list;
    }
  }
  return \%out;
}


has worktree_base_ref => (
  is         => 'ro',
  isa        => 'Maybe[HashRef]',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_worktree_base_ref {
  my ( $self ) = @_;
  my $out;
  for my $src ($self->_sources) {
    my ( $data, $label ) = @$src;
    my $wt = $data->{worktree};
    next unless ref $wt eq 'HASH' && $self->_is_string( $wt->{baseRef} );
    $out = { value => ''.$wt->{baseRef}, source => $label };
  }
  return $out;
}


has ignored => (
  is         => 'ro',
  isa        => 'ArrayRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_ignored {
  my ( $self ) = @_;
  my @out;
  for my $src ($self->_sources) {
    my ( $data, $label ) = @$src;
    push @out, map { { key => $_, source => $label, reason => 'not used by raider' } }
      grep { !$USED{$_} } sort keys %$data;
  }
  return \@out;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Context::Settings - Internal reader of the Claude Code settings files (user, project, local)

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $settings = Langertha::Raider::Context::Settings->new(
      project_dir => $root,
    );
    my $perms   = $settings->permissions;        # allow/ask/deny with sources
    my %env     = %{ $settings->env_values };    # KEY => value
    my $enabled = $settings->enabled_plugin_map; # 'name@market' => 0|1
    warn $_->{label}.': '.$_->{error}."\n" for grep { $_->{error} } @{ $settings->files };

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The Claude Code settings of a project as one value (ADR 0019 §3). Three
files are read, later ones winning:

=over

=item 1. F<settings.json> in L</claude_home> -- scope C<user>, label
C<~/.claude/settings.json> (or the absolute path when L</claude_home> is not
under the home directory)

=item 2. F<.claude/settings.json> in L</project_dir> -- scope C<project>

=item 3. F<.claude/settings.local.json> in L</project_dir> -- scope C<local>

=back

A missing file is no error. A file that cannot be read, is not valid JSON or
is not a JSON object is recorded in L</files> and contributes nothing; it is
never fatal. Every entry keeps the label of the file it came from as
C<source>.

Raider uses C<permissions>, C<hooks>, C<disableAllHooks>, C<disableSkillShellExecution>, C<env>,
C<enabledPlugins> and the approvals of project MCP servers
(C<enableAllProjectMcpServers>, C<enabledMcpjsonServers>,
C<disabledMcpjsonServers>; ADR 0029) and C<worktree.baseRef> (ADR 0032). Every
other top-level key is listed by L</ignored>. Here they are only read;
evaluating permissions (stream P), running hooks (stream H) and applying the
environment are the caller's business.

=head2 project_dir

The project directory whose F<.claude/> holds the project and local
settings. Required.

=head2 claude_home

The user's Claude Code directory. Defaults to
L<Langertha::Raider::Home/claude_home>: C<$ENV{CLAUDE_CONFIG_DIR}> when
that is set and not empty, else F<.claude> in the home directory.
C<undef> when there is no home at all: then no user file is read.

=head2 files

    for my $f (@{ $settings->files }) {
      printf "%s %s%s\n", $f->{label}, $f->{exists} ? 'found' : 'absent',
        $f->{error} ? ' ('.$f->{error}.')' : '';
    }

The three settings files in read order, each a new hash ref:

    {
      file   => '/abs/path/.claude/settings.json',
      label  => '.claude/settings.json',
      scope  => 'user' | 'project' | 'local',
      exists => 0 | 1,
      error  => undef | 'invalid JSON: ...' | 'not a JSON object' | 'unreadable: ...',
    }

Without a L</claude_home> the user file is not in the list.

=head2 permissions

    my $p = $settings->permissions;
    for my $rule (@{ $p->{deny} }) { ... $rule->{rule}, $rule->{source} ... }

The C<permissions> of all files, the input of the permission engine:

    {
      allow => [ { rule => 'Bash(npm run test:*)', source => '.claude/settings.json' }, ... ],
      ask   => [ { rule => ..., source => ... }, ... ],
      deny  => [ { rule => ..., source => ... }, ... ],
      default_mode           => { value => 'acceptEdits', source => ... } | undef,
      additional_directories => [ { path => '../docs', source => ... }, ... ],
    }

C<allow>, C<ask>, C<deny> and C<additional_directories> are the lists of
every file concatenated in read order (user first), each entry as written --
nothing is deduplicated, resolved or validated. Entries that are not plain
strings (or are empty) are skipped. C<default_mode> is the C<defaultMode>
of the last file that sets one as a string.

=head2 hooks

    my $groups = $settings->hooks->{PreToolUse} // [];
    for my $g (@$groups) { ... $g->{matcher}, $g->{hooks}, $g->{source} ... }

The C<hooks> of all files, only stored (stream H runs them):

    {
      PreToolUse => [
        {
          matcher => 'Bash',          # undef when the group has none
          hooks   => [ { type => 'command', command => '...' }, ... ],   # as in the file
          source  => '.claude/settings.json',
        },
        ...
      ],
      ...
    }

Per event name the matcher groups of every file, concatenated in read
order. A group that is not an object is skipped; a C<matcher> that is not a
string is C<undef>; C<hooks> is the file's list untouched (an empty list
when it is missing or not a list).

=head2 disable_all_hooks

    return if $settings->disable_all_hooks;

C<1> when the C<disableAllHooks> of the last file that sets it as a JSON
boolean is true, else C<0>. As in Claude Code, a later file wins, so a
project's C<false> overrides the user's C<true>.

=head2 skip_dangerous_mode_prompt

    $settings->skip_dangerous_mode_prompt;

C<1> when the user file (F<~/.claude/settings.json>, no other) sets
C<skipDangerousModePermissionPrompt> to a JSON true, else C<0>. Claude Code
honours it only from user and managed settings; with it a session started
in C<bypassPermissions> loads project MCP servers without asking
(ADR 0029 Addendum 1).

=head2 disable_skill_shell_execution

    disable_shell => $settings->disable_skill_shell_execution,

C<1> when the C<disableSkillShellExecution> of the last file that sets it
as a JSON boolean is true, else C<0>, a later file winning: the C<!`cmd`>
of skills and commands is then not run (ADR 0030 E<sect>2,
L<Langertha::Raider::SlashCommand/disable_shell>).

=head2 env

    my $e = $settings->env;   # { KEY => { value => '1', source => '.claude/settings.json' } }

The C<env> of all files merged per key, a later file winning. Only string
and number values count (numbers as strings); anything else, booleans
included, is skipped.

=head2 env_values

    local @ENV{ keys %$values } = values %$values;

L</env> without the sources: C<< { KEY => value } >>.

=head2 enabled_plugins

    my $ep = $settings->enabled_plugins;
    # { 'superpowers@claude-plugins-official' => { value => 1, source => '~/.claude/settings.json' } }

The C<enabledPlugins> of all files merged per key, a later file winning.
Only JSON booleans count; C<value> is C<1> or C<0>.

=head2 enabled_plugin_map

L</enabled_plugins> without the sources: C<< { 'name@market' => 0|1 } >>,
the C<enabled> input of L<Langertha::Raider::Context::Plugins>.

=head2 mcpjson_approvals

    my $a = $settings->mcpjson_approvals;
    for my $d (@{ $a->{disabled} }) { ... $d->{name}, $d->{source}, $d->{scope} ... }

The approvals of project MCP servers (F<.mcp.json>, ADR 0029 E<sect>7) of
every file, in read order, each entry with the label and the scope
(C<user>, C<project>, C<local>) of its file. Which of them count depends on
the workspace trust; L<Langertha::Raider::MCP::Config> decides that.

    {
      enable_all => [ { value => 1, source => '.claude/settings.local.json', scope => 'local' }, ... ],
      enabled    => [ { name => 'github', source => ..., scope => ... }, ... ],
      disabled   => [ { name => 'db',     source => ..., scope => ... }, ... ],
    }

C<enable_all> holds one entry per file whose C<enableAllProjectMcpServers>
is a JSON boolean (C<value> C<1> or C<0>); C<enabled> and C<disabled> are
the C<enabledMcpjsonServers> and C<disabledMcpjsonServers> lists
concatenated. Entries that are not non-empty strings are skipped.

=head2 worktree_base_ref

    my $base = $settings->worktree_base_ref;   # { value => 'head', source => '.claude/settings.json' } or undef

C<worktree.baseRef> (ADR 0032 E<sect>2), a later file winning: where a new
worktree branches from (C<fresh> or C<head>, as written -- the caller
decides what another value means). Undef when no file sets a string.

=head2 ignored

    for my $i (@{ $settings->ignored }) {
      say $i->{key}.' ('.$i->{source}.'): '.$i->{reason};
    }

Every top-level key raider does not use (C<model>, C<statusLine>,
C<extraKnownMarketplaces>, ...), per file in read order and sorted by key
inside a file, each as C<< { key, source, reason => 'not used by raider' } >>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Context::Plugins>

=item * L<Langertha::Raider::Context::Skills>

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
