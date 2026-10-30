package Langertha::Raider::MCP::Config;
# ABSTRACT: Internal model of the configured MCP servers: sources, precedence, expansion, approvals
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use JSON::MaybeXS qw( is_bool );
use Path::Tiny;
use Scalar::Util qw( looks_like_number );
use Langertha::Raider::Home;


sub home_class { 'Langertha::Raider::Home' }


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


has claude_layout => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has bare => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has config => (
  is  => 'ro',
  isa => 'Maybe[Langertha::Raider::Config]',
);

has settings => (
  is  => 'ro',
  isa => 'Maybe[Langertha::Raider::Context::Settings]',
);

has plugins => (
  is  => 'ro',
  isa => 'Maybe[Langertha::Raider::Context::Plugins]',
);


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
  my $dir = $self->home_class->claude_home($self->home);
  return defined $dir ? $dir->stringify : undef;
}

has claude_config_file => (
  is         => 'ro',
  isa        => 'Maybe[Str]',
  lazy_build => 1,
);

sub _build_claude_config_file {
  my ( $self ) = @_;
  my $dir = $ENV{CLAUDE_CONFIG_DIR};
  return path($dir)->absolute->child('.claude.json')->stringify if defined $dir && length $dir;
  return unless defined $self->home;
  return path($self->home)->absolute->child('.claude.json')->stringify;
}


has env => (
  is         => 'ro',
  isa        => 'HashRef',
  lazy_build => 1,
);

sub _build_env { return { %ENV } }


has session_approvals => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);


has bypass_approval => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


sub from_context {
  my ( $class, $context, %more ) = @_;
  my $claude = $context->claude_layout ? 1 : 0;
  return $class->new(
    root          => $context->root,
    project_dir   => $claude ? $context->layout->project_dir->stringify : $context->root,
    claude_layout => $claude,
    bare          => $context->bare ? 1 : 0,
    home          => $context->home,
    claude_home   => $context->claude_home,
    settings      => $context->settings,
    plugins       => $context->plugins,
    %more,
  );
}

#### Names


sub normalize_name {
  my ( $self, $name ) = @_;
  ( my $part = $name ) =~ s/[^A-Za-z0-9_-]/_/g;
  return $part;
}

sub tool_name {
  my ( $self, $server, $tool ) = @_;
  return $server->{tool_prefix}.$self->normalize_name($tool);
}


sub is_credential_variable {
  my ( $self, $name ) = @_;
  return $name =~ /\A(?:ANTHROPIC_API_KEY|ANTHROPIC_AUTH_TOKEN|AWS_BEARER_TOKEN_BEDROCK|LANGERTHA_\w+_API_KEY)\z/ ? 1 : 0;
}

#### Claude Code's global config

# { file, label, data, error } of Claude's global config; data {} when it is
# missing or broken.
has _claude_config => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build__claude_config {
  my ( $self ) = @_;
  my $file = $self->claude_config_file;
  return { file => undef, label => '~/.claude.json', data => {}, error => undef } unless defined $file;
  my $label = $self->_home_label($file);
  my ( $data, $error ) = $self->_read_json(path($file));
  return { file => $file, label => $label, data => $data // {}, error => $error };
}

# ~/... for a file under the home directory, else its absolute path.
sub _home_label {
  my ( $self, $file ) = @_;
  $file = path($file)->absolute;
  my $home = $self->home;
  if (defined $home) {
    my $base = path($home)->absolute;
    return '~/'.$file->relative($base) if $base->subsumes($file);
  }
  return $file->stringify;
}

# A JSON object from a file: ( data ) or ( undef, error ); a missing file is
# ( undef ) without an error.
sub _read_json {
  my ( $self, $file ) = @_;
  return unless -e $file;
  my $raw = eval { $file->slurp_raw };
  return ( undef, 'unreadable' ) unless defined $raw;
  my $data = eval { JSON::MaybeXS->new( utf8 => 1 )->decode($raw) };
  return ( undef, 'invalid JSON' ) if $@;
  return ( undef, 'not a JSON object' ) unless ref $data eq 'HASH';
  return ( $data );
}

# The project dir as written (absolute) and by its real path, deduplicated.
sub _project_dirs {
  my ( $self ) = @_;
  my $abs = path($self->project_dir)->absolute;
  my @dirs = ( $abs->stringify );
  push @dirs, $abs->realpath->stringify if -e $abs;
  my %seen;
  return grep { !$seen{$_}++ } @dirs;
}

sub _project_real { ( $_[0]->_project_dirs )[-1] }


sub mcp_json_files {
  my ( $self ) = @_;
  my @out;
  my $dir = path($self->project_dir)->absolute;
  my $home = defined $self->home ? path($self->home)->absolute->stringify : undef;
  my $first = 1;
  while (1) {
    my $file = $dir->child('.mcp.json');
    if (-e $file) {
      my $label = $first ? '.mcp.json'
                : defined $home && "$dir" eq $home ? '~/.mcp.json'
                : $file->stringify;
      push @out, { file => $file, label => $label };
    }
    last if $dir->is_rootdir;
    $dir = $dir->parent;
    $first = 0;
  }
  return @out;
}

# ( key, entry ) of the project in Claude's global config, or nothing.
sub _claude_project {
  my ( $self ) = @_;
  my $projects = $self->_claude_config->{data}{projects};
  return unless ref $projects eq 'HASH';
  for my $dir ($self->_project_dirs) {
    return ( $dir, $projects->{$dir} ) if ref $projects->{$dir} eq 'HASH';
  }
  return;
}

#### Workspace trust


has trust => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_trust {
  my ( $self ) = @_;
  my %no = ( trusted => 0, dir => undef, source => undef );
  return \%no unless $self->claude_layout;
  my $cc = $self->_claude_config;
  my $projects = $cc->{data}{projects};
  return \%no unless ref $projects eq 'HASH';
  for my $start ($self->_project_dirs) {
    my $dir = path($start);
    while (1) {
      my $entry = $projects->{"$dir"};
      return { trusted => 1, dir => "$dir", source => $cc->{label}.' projects["'.$dir.'"]' }
        if ref $entry eq 'HASH' && is_bool($entry->{hasTrustDialogAccepted}) && $entry->{hasTrustDialogAccepted};
      last if $dir->is_rootdir;
      $dir = $dir->parent;
    }
  }
  return \%no;
}

# The project dir is the person's configuration home: the home directory,
# or the directory whose .claude is $CLAUDE_CONFIG_DIR.
sub _is_config_home {
  my ( $self ) = @_;
  my $real = $self->_project_real;
  my @homes;
  push @homes, $self->home if defined $self->home;
  my $ccd = $ENV{CLAUDE_CONFIG_DIR};
  push @homes, path($ccd)->absolute->parent->stringify if defined $ccd && length $ccd;
  for my $h (@homes) {
    my $p = path($h)->absolute;
    $p = $p->realpath if -e $p;
    return 1 if "$p" eq $real;
  }
  return 0;
}

# Whether approvals from a settings file of this scope count.
sub _settings_count {
  my ( $self, $scope ) = @_;
  return 1 if $scope eq 'user';
  return 1 if $self->trust->{trusted};
  return $scope eq 'local' && $self->_is_config_home ? 1 : 0;
}

#### Approvals


has approvals => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_approvals {
  my ( $self ) = @_;
  my %out = ( enable_all => undef, enabled => {}, disabled => {}, ignored => [] );
  return \%out if $self->bare;
  # The person's answers of this session come first.
  my $session = $self->session_approvals;
  for my $name (sort keys %$session) {
    my $why = { source => 'this session', by => 'the person' };
    if    ($name eq '*')                          { $out{enable_all} = $why if $session->{$name} eq 'approved' }
    elsif ($session->{$name} eq 'rejected')       { $out{disabled}{$name} = $why }
    elsif ($session->{$name} eq 'approved')       { $out{enabled}{$name} = $why }
  }
  my $untrusted = 'the folder is not trusted';
  if ($self->claude_layout && ( my $settings = $self->settings )) {
    my $raw = $settings->mcpjson_approvals;
    for my $d (@{ $raw->{disabled} }) {
      $out{disabled}{ $d->{name} } //= { source => $d->{source}, by => 'disabledMcpjsonServers' };
    }
    for my $e (@{ $raw->{enabled} }) {
      if ($self->_settings_count($e->{scope})) {
        $out{enabled}{ $e->{name} } //= { source => $e->{source}, by => 'enabledMcpjsonServers' };
      }
      else {
        push @{ $out{ignored} }, { name => $e->{name}, by => 'enabledMcpjsonServers', source => $e->{source}, reason => $untrusted };
      }
    }
    my $all;
    for my $flag (@{ $raw->{enable_all} }) {
      if ($self->_settings_count($flag->{scope})) {
        $all = $flag;
      }
      else {
        push @{ $out{ignored} }, { name => undef, by => 'enableAllProjectMcpServers', source => $flag->{source}, reason => $untrusted };
      }
    }
    $out{enable_all} = { source => $all->{source}, by => 'enableAllProjectMcpServers' } if $all && $all->{value};
    if ($self->bypass_approval && !$out{enable_all} && $settings->skip_dangerous_mode_prompt) {
      my ( $user ) = grep { $_->{scope} eq 'user' } @{ $settings->files };
      $out{enable_all} = { source => $user->{label},
        by => 'skipDangerousModePermissionPrompt in bypassPermissions mode' };
    }
  }
  if (my $config = $self->config) {
    my $real = $self->_project_real;
    for my $entry (grep { $_->{dir} eq $real } @{ $config->mcp_approvals }) {
      my $by = 'mcp_approvals["'.$entry->{path}.'"]';
      $out{disabled}{$_} //= { source => $entry->{source}, by => $by.'.disabled' } for @{ $entry->{disabled} };
      $out{enabled}{$_}  //= { source => $entry->{source}, by => $by.'.enabled' }  for @{ $entry->{enabled} };
      $out{enable_all} //= { source => $entry->{source}, by => $by.'.enable_all' } if $entry->{enable_all};
    }
  }
  return \%out;
}

# The approval record of one server: required, state, source, by.
sub _approval {
  my ( $self, $name, $scope ) = @_;
  return { required => 0, state => 'not required', source => undef, by => undef }
    unless $scope eq 'project' || $scope eq 'raider-project';
  my $a = $self->approvals;
  my ( $state, $why ) = $a->{disabled}{$name} ? ( rejected => $a->{disabled}{$name} )
                      : $a->{enabled}{$name}  ? ( approved => $a->{enabled}{$name} )
                      : $a->{enable_all}      ? ( approved => $a->{enable_all} )
                      :                         ( pending  => {} );
  return { required => 1, state => $state, source => $why->{source}, by => $why->{by} };
}


has approval_target => (
  is         => 'ro',
  isa        => 'Maybe[HashRef]',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_approval_target {
  my ( $self ) = @_;
  if ($self->claude_layout && $self->_settings_count('local')) {
    return {
      kind  => 'claude-settings',
      file  => path($self->project_dir)->absolute->child('.claude', 'settings.local.json')->stringify,
      label => '.claude/settings.local.json',
    };
  }
  my $config = $self->config or return;
  my $file = $config->home_file or return;
  return {
    kind  => 'raider-home',
    file  => $file->stringify,
    label => '~/'.$config->home_class->dir_name.'/config.yml',
    path  => $self->_project_real,
  };
}


sub pending { grep { $_->{status} eq 'pending' } @{ $_[0]->servers } }

my %ANSWER = ( approve => 'approved', all => 'approved', reject => 'rejected' );

sub record_approval {
  my ( $self, $name, $answer ) = @_;
  croak(__PACKAGE__.'->record_approval: answer is approve, all or reject') unless $ANSWER{ $answer // '' };
  $self->session_approvals->{ $answer eq 'all' ? '*' : $name } = $ANSWER{$answer};
  my $target = $self->approval_target or return;
  if ($target->{kind} eq 'claude-settings') {
    my $file = path($target->{file});
    my ( $data, $error ) = $self->_read_json($file);
    croak('Cannot record the approval in '.$target->{label}.': '.$error) if $error;
    $data //= {};
    my $push = sub {
      my ( $key ) = @_;
      my $list = ref $data->{$key} eq 'ARRAY' ? $data->{$key} : [];
      $data->{$key} = [ @$list, ( grep { $_ eq $name } @$list ) ? () : $name ];
    };
    if    ($answer eq 'approve') { $push->('enabledMcpjsonServers') }
    elsif ($answer eq 'reject')  { $push->('disabledMcpjsonServers') }
    else                         { $data->{enableAllProjectMcpServers} = JSON::MaybeXS->true }
    $file->parent->mkpath;
    $file->spew_raw(JSON::MaybeXS->new( utf8 => 1, canonical => 1, pretty => 1 )->encode($data));
    return $target->{label};
  }
  my $dir = $target->{path};
  $self->config->update_home(sub {
    my ( $data ) = @_;
    my $all = ref $data->{mcp_approvals} eq 'HASH' ? $data->{mcp_approvals} : ( $data->{mcp_approvals} = {} );
    my $entry = ref $all->{$dir} eq 'HASH' ? $all->{$dir} : ( $all->{$dir} = {} );
    if ($answer eq q(all)) { $entry->{enable_all} = q(true); return 1 }   # YAML::PP->new dumps no boolean objects
    my $key = $answer eq 'approve' ? 'enabled' : 'disabled';
    my $list = ref $entry->{$key} eq 'ARRAY' ? $entry->{$key} : defined $entry->{$key} ? [ $entry->{$key} ] : [];
    $entry->{$key} = [ @$list, ( grep { $_ eq $name } @$list ) ? () : $name ];
    return 1;
  });
  return $target->{label};
}

#### Timeouts


has _timeouts => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build__timeouts {
  my ( $self ) = @_;
  my %out = ( startup => 30000, tool => undef, output => 25000, warnings => [] );
  for my $pair ([ startup => 'MCP_TIMEOUT' ], [ tool => 'MCP_TOOL_TIMEOUT' ], [ output => 'MAX_MCP_OUTPUT_TOKENS' ]) {
    my ( $key, $var ) = @$pair;
    my $value = $self->env->{$var};
    next unless defined $value && length $value;
    if ($value =~ /\A\s*([0-9]+)\s*\z/ && $1 > 0) {
      $out{$key} = 0 + $1;
    }
    else {
      push @{ $out{warnings} }, $var.'='.$value.' is not a positive number of '
        .( $key eq 'output' ? 'tokens' : 'milliseconds' ).'; ignored';
    }
  }
  return \%out;
}

sub startup_timeout_ms { $_[0]->_timeouts->{startup} }
sub tool_timeout_ms    { $_[0]->_timeouts->{tool} }
sub max_output_tokens  { $_[0]->_timeouts->{output} }
sub env_warnings       { [ @{ $_[0]->_timeouts->{warnings} } ] }

#### Servers


has _resolved => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub servers { $_[0]->_resolved->{servers} }
sub errors  { $_[0]->_resolved->{errors} }


sub server {
  my ( $self, $name ) = @_;
  my ( $s ) = grep { $_->{name} eq $name } @{ $self->servers };
  return $s;
}

sub startable { grep { $_->{status} eq 'configured' } @{ $_[0]->servers } }

sub _build__resolved {
  my ( $self ) = @_;
  return { servers => [], errors => [] } if $self->bare;
  my ( @candidates, @errors );

  if (my $config = $self->config) {
    push @candidates, map { { %$_ } } @{ $config->mcp_servers };
  }

  my %disabled;
  if ($self->claude_layout) {
    my $cc = $self->_claude_config;
    push @errors, { source => $cc->{label}, error => $cc->{error} } if $cc->{error};
    my ( $key, $project ) = $self->_claude_project;
    if ($project) {
      my $source = $cc->{label}.' projects["'.$key.'"]';
      push @candidates, $self->_candidates($project->{mcpServers}, 'local', $source, \@errors);
      if (ref $project->{disabledMcpServers} eq 'ARRAY') {
        $disabled{$_} //= $source.'.disabledMcpServers'
          for grep { defined && !ref } @{ $project->{disabledMcpServers} };
      }
    }
    for my $file ($self->mcp_json_files) {
      my ( $data, $error ) = $self->_read_json($file->{file});
      push @errors, { source => $file->{label}, error => $error } if $error;
      push @candidates, $self->_candidates($data->{mcpServers}, 'project', $file->{label}, \@errors) if $data;
    }
    push @candidates, $self->_candidates($cc->{data}{mcpServers}, 'user', $cc->{label}, \@errors);
    if (my $plugins = $self->plugins) {
      for my $p (@{ $plugins->plugins }) {
        my ( $servers, $errs ) = $plugins->mcp_servers($p);
        push @errors, map { { source => 'plugin:'.$p->{name}, error => $_ } } @$errs;
        my $info = {
          name     => $p->{name},
          key      => $p->{key},
          root     => $p->{root},
          data_dir => $plugins->data_dir($p),
        };
        push @candidates, map {
          { name => 'plugin:'.$p->{name}.':'.$_->{name}, server => $_->{name}, entry => $_->{entry},
            scope => 'plugin', source => $_->{source}, plugin => $info }
        } @$servers;
      }
    }
  }

  # The first entry of a name wins whole.
  my ( %winner, @order );
  for my $c (@candidates) {
    if (my $w = $winner{ $c->{name} }) {
      push @{ $w->{shadowed} }, { scope => $c->{scope}, source => $c->{source} };
      next;
    }
    $c->{shadowed} = [];
    $winner{ $c->{name} } = $c;
    push @order, $c;
  }

  my ( @servers, %by_key );
  for my $c (@order) {
    my $s = $self->_server($c, \%disabled);
    if (defined $s->{key} && length $s->{key}) {
      if (my $first = $by_key{ $s->{key} }) {
        $s->{status} = 'invalid';
        $s->{reason} = 'its tool names (mcp__'.$s->{key}.'__*) collide with server '.$first;
      }
      else {
        $by_key{ $s->{key} } = $s->{name};
      }
    }
    push @servers, $s;
  }
  return { servers => \@servers, errors => \@errors };
}

# The candidates of one mcpServers map, sorted by name.
sub _candidates {
  my ( $self, $map, $scope, $source, $errors ) = @_;
  return unless defined $map;
  unless (ref $map eq 'HASH') {
    push @$errors, { source => $source, error => 'mcpServers is not an object' };
    return;
  }
  return map { { name => $_, entry => $map->{$_}, scope => $scope, source => $source } } sort keys %$map;
}

my %TYPE = map { $_ => 1 } qw( stdio http streamable-http sse ws sdk );
my %FIELD = (
  stdio => { map { $_ => 1 } qw( type timeout command args env ) },
  http  => { map { $_ => 1 } qw( type timeout url headers headersHelper oauth ) },
);

# One server from its winning candidate.
sub _server {
  my ( $self, $c, $disabled ) = @_;
  my $root = path($self->root)->absolute->stringify;
  my %s = (
    name        => $c->{name},
    key         => undef,
    tool_prefix => undef,
    scope       => $c->{scope},
    source      => $c->{source},
    transport   => undef,
    command     => undef,
    args        => [],
    env         => {},
    url         => undef,
    headers     => {},
    cwd         => $root,
    project_dir => path($self->project_dir)->absolute->stringify,
    timeout_ms  => $self->tool_timeout_ms,
    status      => 'configured',
    reason      => undef,
    warnings    => [],
    approval    => $self->_approval($c->{name}, $c->{scope}),
    shadowed    => $c->{shadowed},
    plugin      => $c->{plugin},
    entry       => $c->{entry},
  );
  my $set = sub { @s{qw( status reason )} = @_; return \%s };

  # The person's decision first: it holds whatever the entry says.
  return $set->(rejected => 'rejected by '.$s{approval}{by}.' in '.$s{approval}{source})
    if $s{approval}{state} eq 'rejected';
  return $set->(disabled => 'disabled for this project by '.$disabled->{ $c->{name} })
    if $disabled->{ $c->{name} } && $c->{scope} =~ /\A(?:local|user|plugin)\z/;

  my $key = $c->{plugin}
    ? 'plugin_'.$self->normalize_name($c->{plugin}{name}).'_'.$self->normalize_name($c->{server})
    : $self->normalize_name($c->{name});
  return $set->(invalid => 'empty server name') unless length $c->{name};
  @s{qw( key tool_prefix )} = ( $key, 'mcp__'.$key.'__' );
  return $set->(invalid => 'the server name gives the tool name part "'.$key
    .'", which holds "__" or starts or ends with "_": its tool names could not be told apart')
    if $key =~ /__/ || $key =~ /\A_|_\z/;

  my $e = $c->{entry};
  return $set->(invalid => 'the entry is not an object') unless ref $e eq 'HASH';
  my $type = $e->{type};
  if (!defined $type) {
    return $set->(invalid => 'an entry with "url" needs a "type" (http): without one it is a stdio server')
      if exists $e->{url};
    $type = 'stdio';
  }
  return $set->(invalid => 'unknown type '.( ref $type ? 'value' : '"'.$type.'"' ).' (stdio, http, sse, ws)')
    if ref $type || !$TYPE{$type};
  $type = 'http' if $type eq 'streamable-http';
  $s{transport} = $type;

  return $set->(unsupported => 'type sdk: a server of the Agent SDK') if $type eq 'sdk';
  return $set->(unsupported => 'the '.$type.' transport is not supported; use http (streamable HTTP)')
    if $type eq 'sse' || $type eq 'ws';

  my $fields = $FIELD{$type};
  push @{ $s{warnings} }, 'unknown field "'.$_.'" ignored' for grep { !$fields->{$_} } sort keys %$e;

  if (exists $e->{timeout}) {
    my $t = $e->{timeout};
    return $set->(invalid => 'timeout must be a number of milliseconds')
      if ref $t || !defined $t || !looks_like_number($t);
    if ($t < 1000) { push @{ $s{warnings} }, 'timeout '.$t.' below 1000 ms is ignored' }
    else           { $s{timeout_ms} = int $t }
  }

  my %vars = $c->{plugin} ? (
    CLAUDE_PLUGIN_ROOT => $c->{plugin}{root},
    ( defined $c->{plugin}{data_dir} ? ( CLAUDE_PLUGIN_DATA => $c->{plugin}{data_dir} ) : () ),
    CLAUDE_PROJECT_DIR => $s{project_dir},
  ) : ();
  my %warned;
  my $expand = sub {
    my ( $string, $remote ) = @_;
    my @w;
    my $out = $self->expand($string, vars => \%vars, remote => $remote, warnings => \@w);
    push @{ $s{warnings} }, grep { !$warned{$_}++ } @w;
    return $out;
  };

  if ($type eq 'stdio') {
    my $command = $e->{command};
    return $set->(invalid => 'a stdio server needs a "command"')
      unless defined $command && !ref $command && length $command;
    my $args = $e->{args} // [];
    return $set->(invalid => '"args" must be a list of strings')
      unless ref $args eq 'ARRAY' && !grep { !$self->_is_scalar($_) } @$args;
    my $env = $e->{env} // {};
    return $set->(invalid => '"env" must be a map of strings')
      unless ref $env eq 'HASH' && !grep { !$self->_is_scalar($_) } values %$env;
    $s{command} = $expand->($command, 0);
    $s{args}    = [ map { $expand->(''.$_, 0) } @$args ];
    $s{env}     = { map { $_ => $expand->(''.$env->{$_}, 0) } sort keys %$env };
  }
  else {
    my $url = $e->{url} // '';
    return $set->(invalid => '"url" must be a string') if ref $url;
    my $headers = $e->{headers} // {};
    return $set->(invalid => '"headers" must be a map of strings')
      unless ref $headers eq 'HASH' && !grep { !$self->_is_scalar($_) } values %$headers;
    $s{url}     = $expand->($url, 1);
    $s{headers} = { map { $_ => $expand->(''.$headers->{$_}, 1) } sort keys %$headers };
    return $set->(unsupported => '"headersHelper" is not supported') if exists $e->{headersHelper};
    return $set->(unsupported => '"oauth" is not supported: raider has no OAuth flow') if exists $e->{oauth};
    return $set->(not_configured => 'no URL configured for this server') unless length $s{url};
  }

  return $set->(pending => 'pending approval') if $s{approval}{state} eq 'pending';
  return \%s;
}

# A string or a number (not a ref, not undef, not a JSON boolean).
sub _is_scalar { defined $_[1] && !ref $_[1] }


sub expand {
  my ( $self, $text, %opt ) = @_;
  $opt{vars}     //= {};
  $opt{warnings} //= [];
  $text =~ s/(\$\{([^}:]+)(?::-([^}]*))?\})/$self->_expand_var($1, $2, $3, \%opt)/ge;
  return $text;
}

sub _expand_var {
  my ( $self, $whole, $name, $default, $opt ) = @_;
  if ($opt->{remote} && $self->is_credential_variable($name)) {
    push @{ $opt->{warnings} }, '${'.$name.'} is a credential and is not passed to a remote server';
    return '';
  }
  my $env = $self->env;
  return exists $opt->{vars}{$name} ? $opt->{vars}{$name}
       : defined $env->{$name}      ? $env->{$name}
       : defined $default           ? $default
       : do { push @{ $opt->{warnings} }, '${'.$name.'} is not set'; $whole };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::MCP::Config - Internal model of the configured MCP servers: sources, precedence, expansion, approvals

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $mcp = Langertha::Raider::MCP::Config->from_context( $context, config => $config );

    for my $s (@{ $mcp->servers }) {
      printf "%s (%s, %s): %s\n", $s->{name}, $s->{scope}, $s->{source}, $s->{status};
    }
    my @start = $mcp->startable;            # status 'configured'
    my $ms    = $mcp->startup_timeout_ms;   # MCP_TIMEOUT, 30000
    my $tool  = $mcp->tool_name($start[0], 'create-issue');   # mcp__github__create-issue

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The MCP servers a person configured, as one value (ADR 0029): where they
come from, which entry of a name wins, what C<${VAR}> expands to, the names
their tools get, the timeouts, and whether a project's server may start.
It reads files and the environment and starts nothing; connecting is
L<Langertha::Raider::MCP::Server>'s business.

Sources, highest precedence first (ADR 0029 E<sect>2):

=over

=item 1. C<raider-project> -- C<mcp:> of the project config
(L<Langertha::Raider::Config/mcp_servers>)

=item 2. C<raider-home> -- C<mcp:> of F<~/.raider/config.yml>

=item 3. C<local> -- C<projects["PROJECT DIR"].mcpServers> of Claude's
global config (L</claude_config_file>); Claude layout only

=item 4. C<project> -- C<mcpServers> of F<.mcp.json> in L</project_dir> and
every directory above it, the nearest file first (L</mcp_json_files>);
Claude layout only

=item 5. C<user> -- the top-level C<mcpServers> of Claude's global config;
Claude layout only

=item 6. C<plugin> -- every installed and enabled plugin
(L<Langertha::Raider::Context::Plugins/mcp_servers>), named
C<plugin:PLUGIN:SERVER>; Claude layout only

=back

The first entry of a name wins whole; the others are listed as
C<shadowed>. With L</bare> there are no servers at all. A file that cannot
be read or parsed is reported in L</errors>, never fatal; a raider config
whose C<mcp:> has the wrong shape croaks (from
L<Langertha::Raider::Config>).

=head2 root

The directory raider runs in: the working directory of stdio servers.
Required.

=head2 project_dir

The project directory: where F<.mcp.json> is read, the key of the C<local>
scope and of the approvals, C<${CLAUDE_PROJECT_DIR}> of plugin servers. In
the Claude layout L<Langertha::Raider::Context::Layout/project_dir>,
otherwise L</root> (the default).

=head2 claude_layout

True when Claude Code's sources are read (ADR 0019 E<sect>1). Default
false.

=head2 bare

True for C<--bare>: no server from any source. Default false.

=head2 config

The L<Langertha::Raider::Config> whose C<mcp:> and C<mcp_approvals:> are
read; C<undef> (the default) reads no raider file.

=head2 settings

The L<Langertha::Raider::Context::Settings> of the Claude layout, for the
approvals of project servers; C<undef> outside it.

=head2 plugins

The L<Langertha::Raider::Context::Plugins> of the Claude layout; C<undef>
outside it.

=head2 home

The user's home directory, by default L<Langertha::Raider::Home/home_dir>.

=head2 claude_home

Claude Code's directory, by default L<Langertha::Raider::Home/claude_home>
of L</home>.

=head2 claude_config_file

Claude Code's global config: F<.claude.json> in C<$CLAUDE_CONFIG_DIR> when
that is set and not empty, else F<~/.claude.json>. C<undef> without either.

=head2 env

The variables C<${VAR}> expands from and C<MCP_TIMEOUT> /
C<MCP_TOOL_TIMEOUT> are read from: by default a copy of C<%ENV> taken when
first needed (after the Claude settings' C<env> is applied).

=head2 session_approvals

The person's answers of this session (ADR 0029 E<sect>7), which count
before every file: C<< { NAME => 'approved' | 'rejected', '*' =>
'approved' } >> (C<*>: every project server). Default empty. The
application keeps one hash for the session and hands it to every model it
builds, so an answer holds even where it could not be written down.

=head2 bypass_approval

True when the session was started in C<bypassPermissions> (by
C<--permission-mode> or C<--dangerously-skip-permissions>). Together with
C<skipDangerousModePermissionPrompt> in the user settings
(L<Langertha::Raider::Context::Settings/skip_dangerous_mode_prompt>) every
project server then counts as approved, as in Claude Code; a C<disabled>
entry still rejects (ADR 0029 Addendum 1). Default false.

=head2 from_context

    my $mcp = Langertha::Raider::MCP::Config->from_context( $context, config => $config );

A model for a L<Langertha::Raider::Context>: its root, home, Claude home,
layout (the project directory in the Claude layout), settings and plugins;
L</bare> for mode C<bare>. C<%more> goes to C<new> (L</config>, L</env>).

=head2 normalize_name

    my $part = $mcp->normalize_name('my.server');   # my_server

Every character outside C<A-Z a-z 0-9 _ -> becomes C<_> (Claude Code's
rule), for a server and a tool name alike.

=head2 tool_name

    my $name = $mcp->tool_name($server, 'create.issue');   # mcp__github__create_issue

The name a tool of C<$server> (an entry of L</servers>) reaches the model,
the permission rules and the hooks with: C<mcp__KEY__TOOL>.

=head2 is_credential_variable

    $mcp->is_credential_variable('ANTHROPIC_API_KEY');   # 1

True for the variables that are never expanded into the C<url> or
C<headers> of a remote server: Claude Code's C<ANTHROPIC_API_KEY>,
C<ANTHROPIC_AUTH_TOKEN>, C<AWS_BEARER_TOKEN_BEDROCK>, and raider's engine
keys C<LANGERTHA_*_API_KEY>.

=head2 mcp_json_files

    for my $f ($mcp->mcp_json_files) { say $f->{label}, ' ', $f->{file} }

The F<.mcp.json> files that exist, nearest first: the one in
L</project_dir>, then those of every directory above it up to the root
(ADR 0029 Addendum 1). Each C<< { file, label } >>; the label is
C<.mcp.json> for the project directory, C<~/.mcp.json> for the home
directory, else the absolute path. A name in a nearer file wins over the
same name farther up (scope C<project> for all of them).

=head2 trust

    my $t = $mcp->trust;   # { trusted => 1, dir => '/home/me/dev', source => '~/.claude.json projects["/home/me/dev"]' }

Whether the project directory is trusted (ADR 0029 E<sect>7). Raider has
no trust decision of its own yet (ADR 0004), so Claude Code's record
counts: C<hasTrustDialogAccepted: true> in the C<projects> entry of
L</project_dir> or of a directory above it in Claude's global config.
C<dir> and C<source> name the entry; both C<undef> when untrusted. Only
read in the Claude layout (outside it nothing is trusted -- and nothing
asks).

=head2 approvals

    my $a = $mcp->approvals;

The decisions about project servers (ADR 0029 E<sect>7), from the Claude
settings (Claude layout; filtered by the workspace trust) and the
C<mcp_approvals:> entry of L</project_dir> in the home config:

    {
      enable_all => { source => '.claude/settings.local.json', by => 'enableAllProjectMcpServers' } | undef,
      enabled    => { github => { source => ..., by => 'enabledMcpjsonServers' }, ... },
      disabled   => { db     => { source => ..., by => 'disabledMcpjsonServers' }, ... },
      ignored    => [ { name => 'x', by => 'enabledMcpjsonServers', source => '.claude/settings.json',
                        reason => 'the folder is not trusted' }, ... ],
    }

A C<disabled> entry counts from every file, trusted or not. An
C<enabled> entry and C<enableAllProjectMcpServers> count from
F<~/.claude/settings.json> always, from F<.claude/settings.json> in a
trusted folder, from F<.claude/settings.local.json> in a trusted folder or
the configuration home; the others are listed in C<ignored>.
C<enableAllProjectMcpServers> is the last counted file's value; the home
config's C<enable_all> approves all as well. The first source of a name
is kept; L</session_approvals> come before every file (source C<this
session>, by C<the person>).

=head2 approval_target

    my $t = $mcp->approval_target;
    # { kind => 'claude-settings', file => '/p/.claude/settings.local.json', label => '.claude/settings.local.json' }
    # { kind => 'raider-home', file => '/home/me/.raider/config.yml', label => '~/.raider/config.yml', path => '/p' }

Where an interactive approval is written so that it counts next time
(ADR 0029 E<sect>7): F<.claude/settings.local.json> of L</project_dir> in
the Claude layout when that file's approvals count (a trusted folder, or
the configuration home); otherwise the C<mcp_approvals:> of the home config
under the real path of L</project_dir>. C<undef> when neither is possible
(no L</config>, or no home).

=head2 pending

The entries of L</servers> waiting for an approval (status C<pending>).

=head2 record_approval

    my $where = $mcp->record_approval( 'github', 'approve' );   # or 'all', 'reject'

Writes the person's answer about a pending project server where it counts
next time (L</approval_target>), as Claude Code writes it:

=over

=item * F<.claude/settings.local.json>: C<approve> adds the name to
C<enabledMcpjsonServers>, C<all> sets C<enableAllProjectMcpServers> to
true, C<reject> adds the name to C<disabledMcpjsonServers>. Other keys are
kept (the file is written back with sorted keys).

=item * the home config: the same under C<mcp_approvals> of the project
dir's real path (C<enabled>, C<enable_all>, C<disabled>), through
L<Langertha::Raider::Config/update_home>.

=back

Also records it in L</session_approvals>. Returns the label of the file
written, or C<undef> when there is nowhere to write (the answer then holds
for the session only). Croaks on an unknown answer, or when the settings
file exists but is not a JSON object.

=head2 startup_timeout_ms

C<MCP_TIMEOUT> of L</env>: how long one server may take to start
(connect, initialize, list its tools), in milliseconds. Default 30000.

=head2 tool_timeout_ms

C<MCP_TOOL_TIMEOUT> of L</env>: the per-call limit in milliseconds for
servers without a C<timeout> of their own. C<undef> (no limit) when unset.

=head2 max_output_tokens

C<MAX_MCP_OUTPUT_TOKENS> of L</env>: how many tokens of a tool result
raider passes on before it cuts the text (ADR 0029 Addendum 1). Default
25000, Claude Code's.

=head2 env_warnings

The problems of those three variables (a value that is not a positive whole
number is ignored), as strings.

=head2 servers

    for my $s (@{ $mcp->servers }) { ... }

Every configured server, the winning entry of each name, in precedence
order (plugins in plugin order), each a hash:

    {
      name        => 'github',                  # plugin servers: 'plugin:PLUGIN:SERVER'
      key         => 'github',                  # the server part of the tool names
      tool_prefix => 'mcp__github__',
      scope       => 'raider-project' | 'raider-home' | 'local' | 'project' | 'user' | 'plugin',
      source      => '.mcp.json',               # the file (and entry) it came from
      transport   => 'stdio' | 'http' | 'sse' | 'ws' | 'sdk' | undef,
      command     => 'npx', args => [ ... ], env => { ... },   # stdio, expanded
      url         => 'https://...', headers => { ... },        # http, expanded
      cwd         => '/abs/root',               # stdio servers run here
      project_dir => '/abs/project',            # their CLAUDE_PROJECT_DIR
      timeout_ms  => 60000 | undef,             # per call: timeout, else MCP_TOOL_TIMEOUT
      status      => 'configured' | 'pending' | 'rejected' | 'disabled'
                   | 'unsupported' | 'not_configured' | 'invalid',
      reason      => '...' | undef,
      warnings    => [ '${DB_URL} is not set', ... ],
      approval    => { required => 0|1, state => 'not required' | 'approved' | 'pending' | 'rejected',
                       source => ..., by => ... },
      shadowed    => [ { scope => 'user', source => '~/.claude.json' }, ... ],
      plugin      => { name, key, root, data_dir } | undef,
      entry       => { ... },                   # as written
    }

Only C<configured> servers are started (L</startable>). The status is
decided in this order: C<rejected> / C<disabled> (the person's decision),
C<invalid>, C<unsupported>, C<not_configured>, C<pending>.

=head2 errors

Problems of whole files, each C<< { source, error } >>: Claude's global
config or F<.mcp.json> that does not parse, a broken plugin file. Never
fatal.

=head2 server

    my $s = $mcp->server('github');

The entry of L</servers> with that name, or C<undef>.

=head2 startable

The entries of L</servers> with status C<configured>.

=head2 expand

    my @warnings;
    my $text = $mcp->expand('${API:-https://x}/mcp', vars => \%plugin_vars,
      remote => 1, warnings => \@warnings);

C<${VAR}> and C<${VAR:-default}> in C<$text> (ADR 0029 E<sect>4): C<vars>
first, then L</env>; a set variable (empty included) gives its value, an
unset one its default; with neither the text stays as written and
C<${VAR} is not set> is pushed to C<warnings>. With C<remote> (a C<url> or
C<headers> value) a credential variable (L</is_credential_variable>)
expands to the empty string, its default ignored, with a warning.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Config/mcp_servers>, L<Langertha::Raider::Config/mcp_approvals>

=item * L<Langertha::Raider::Context::Settings/mcpjson_approvals>

=item * L<Langertha::Raider::Context::Plugins/mcp_servers>

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
