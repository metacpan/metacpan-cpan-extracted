package Langertha::Raider::Permissions;
# ABSTRACT: Internal permission policy of a raider session: mode, rules with sources, session rules
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Cwd qw( realpath );
use Digest::SHA qw( sha256_hex );
use JSON::MaybeXS;
use List::Util qw( first );
use Path::Tiny;
use Scalar::Util qw( refaddr );
use URI;
use Langertha::Raider::Home;
use Langertha::Raider::Permissions::ReadOnlyBash;
use Langertha::Raider::Permissions::Rule;
use Langertha::Raider::ToolEffects;
use Langertha::Raider::ToolNames;
use Langertha::Raider::Worktree;


my @MODES = qw( default acceptEdits auto plan bypassPermissions );
my %MODE  = map { $_ => 1 } @MODES;

# Tools that face the person or only steer the run: allowed without a rule,
# in plan mode too.
my %CONTROL = map { $_ => 1 } qw( ask_user raider_ask_user todo_write skill exit_plan_mode );

# The file tools that write, those that read, and every tool with a path.
my %WRITER    = map { $_ => 1 } qw( write_file edit_file multi_edit );
my %READER    = map { $_ => 1 } qw( read_file list_files glob grep );
my %PATH_TOOL = ( %WRITER, %READER );

# The tools that move the session into a worktree and out (ADR 0032 §4).
my %WORKTREE_TOOL = map { $_ => 1 } qw( enter_worktree exit_worktree );

my %EFFECT_TEXT = (
  write   => 'changes files',
  code    => 'runs code',
  network => 'uses the network',
  message => 'sends messages',
);

has root => ( is => 'ro', isa => 'Str', required => 1, writer => '_set_root' );


has home => ( is => 'ro', isa => 'Str', lazy_build => 1 );

sub _build_home { Langertha::Raider::Home->home_dir }


has mode => ( is => 'ro', isa => 'Str', writer => '_set_mode', default => 'default' );


has mode_source => ( is => 'ro', isa => 'Str', writer => '_set_mode_source', default => 'default' );


has rules => ( is => 'ro', isa => 'HashRef', default => sub { {} } );


has additional_directories => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );


has source_servers => ( is => 'ro', isa => 'HashRef', default => sub { {} } );


has session_rules => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );


has run_rules => ( is => 'ro', isa => 'ArrayRef', default => sub { [] }, writer => '_set_run_rules' );


has ask_outside_roots => ( is => 'ro', isa => 'Bool', default => 0 );


has worktree_isolation => (
  is        => 'ro',
  isa       => 'Maybe[HashRef]',
  predicate => 'has_worktree_isolation',
  writer    => '_set_worktree_isolation',
  clearer   => '_clear_worktree_isolation',
);


has ignored_modes => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );


has _file_rules => ( is => 'ro', isa => 'ArrayRef', lazy_build => 1, init_arg => undef );

sub BUILD {
  my ( $self ) = @_;
  croak __PACKAGE__.' unknown permission mode '.$self->mode unless $self->is_mode( $self->mode );
  return;
}

sub _build__file_rules {
  my ( $self ) = @_;
  my @rules;
  for my $kind (qw( deny ask allow )) {
    for my $entry ( @{ $self->rules->{$kind} // [] } ) {
      my ( $text, $source ) = ref $entry eq 'HASH' ? @{$entry}{qw( rule source )} : ( $entry, 'unknown' );
      next unless defined $text && !ref $text;
      push @rules, Langertha::Raider::Permissions::Rule->new(
        text => $text, source => $source // 'unknown', kind => $kind,
      );
    }
  }
  return \@rules;
}

sub from_sources {
  my ( $class, %arg ) = @_;
  my ( %rules, @dirs, @ignored, $mode );
  if ( my $cli = $arg{cli_mode} ) {
    croak __PACKAGE__.'->from_sources: unknown permission mode '.( $cli->{value} // 'undef' )
      unless $class->is_mode( $cli->{value} );
    $mode = $cli;
  }
  for my $source ( grep { defined } @{ $arg{sources} // [] } ) {
    push @{ $rules{$_} }, @{ $source->{$_} // [] } for qw( allow ask deny );
    push @dirs, @{ $source->{additional_directories} // [] };
    my $m = $source->{default_mode} or next;
    if ( !$class->is_mode( $m->{value} ) ) {
      push @ignored, { %$m, reason => 'not a permission mode (one of '.join( ', ', @MODES ).')' };
    }
    elsif ( !$mode ) {
      $mode = $m;
    }
  }
  return $class->new(
    root                   => $arg{root},
    ( defined $arg{home} ? ( home => $arg{home} ) : () ),
    ( $mode ? ( mode => $mode->{value}, mode_source => $mode->{source} ) : () ),
    rules                  => \%rules,
    additional_directories => \@dirs,
    ignored_modes          => \@ignored,
    ( $arg{source_servers} ? ( source_servers => $arg{source_servers} ) : () ),
    ( $arg{session_rules}  ? ( session_rules  => $arg{session_rules} )  : () ),
    ( $arg{run_rules}      ? ( run_rules      => $arg{run_rules} )      : () ),
    ( $arg{ask_outside_roots} ? ( ask_outside_roots => 1 ) : () ),
    ( $arg{worktree_isolation} ? ( worktree_isolation => $arg{worktree_isolation} ) : () ),
  );
}


sub report {
  my ( $self ) = @_;
  return {
    mode          => $self->mode,
    mode_source   => $self->mode_source,
    ( $self->mode eq 'auto' ? ( mode_note => $self->mode_note ) : () ),
    ignored_modes => [ map { { %$_ } } @{ $self->ignored_modes } ],
    rules         => { map {
      my $kind = $_;
      $kind => [ map { { rule => $_->text, source => $_->source } } grep { $_->kind eq $kind } $self->rule_list ];
    } qw( allow ask deny ) },
    invalid_rules => [ map { $_->as_hash } $self->invalid_rules ],
    additional_directories => [ $self->_directory_entries ],
  };
}


sub mode_note {
  my ( $self ) = @_;
  return unless $self->mode eq 'auto';
  return $self->mode_source =~ /settings/
    ? 'claude auto -> raider acceptEdits + read-only bash allowlist'
    : 'auto -> acceptEdits + read-only bash allowlist';
}


sub modes { @MODES }


sub is_mode { my ( $self, $name ) = @_; defined $name && $MODE{$name} ? 1 : 0 }


sub rule_list {
  my ( $self ) = @_;
  return ( ( grep { $_->is_valid } @{ $self->_file_rules } ), @{ $self->session_rules }, @{ $self->run_rules } );
}


sub invalid_rules { grep { !$_->is_valid } @{ $_[0]->_file_rules } }


sub add_session_rule {
  my ( $self, $text ) = @_;
  my $rule = Langertha::Raider::Permissions::Rule->new( text => $text, source => 'session', kind => 'allow' );
  croak __PACKAGE__.'->add_session_rule: '.$rule->error.': '.$text unless $rule->is_valid;
  my $known = first { $_->text eq $rule->text } @{ $self->session_rules };
  return $known if $known;
  push @{ $self->session_rules }, $rule;
  return $rule;
}


sub add_run_rules {
  my ( $self, $texts, $source ) = @_;
  my @added;
  for my $text ( grep { defined && !ref } @{ $texts // [] } ) {
    my $rule = Langertha::Raider::Permissions::Rule->new(
      text => $text, source => $source // 'run', kind => 'allow',
    );
    next unless $rule->is_valid;
    next if first { $_->text eq $rule->text && $_->source eq $rule->source } @{ $self->run_rules };
    push @{ $self->run_rules }, $rule;
    push @added, $rule;
  }
  return @added;
}


sub clear_run_rules {
  my ( $self, @rules ) = @_;
  my $list = $self->run_rules;
  if (@rules) {
    my %drop = map { refaddr($_) => 1 } @rules;
    @$list = grep { !$drop{ refaddr $_ } } @$list;
  }
  else {
    @$list = ();
  }
  return;
}


sub set_mode {
  my ( $self, $mode, $source ) = @_;
  croak __PACKAGE__.'->set_mode: unknown permission mode '.( $mode // 'undef' ) unless $self->is_mode($mode);
  my $from = $self->mode;
  $self->_set_mode($mode);
  $self->_set_mode_source( $source // 'session' );
  return $from;
}


sub additional_directory_paths { map { $_->{path} } $_[0]->_directory_entries }

# The additional directories as { path (absolute), source }.
sub _directory_entries {
  my ( $self ) = @_;
  my $base = Langertha::Raider::Permissions::Rule->_lexical( path( $self->root )->absolute->stringify );
  my @out;
  for my $entry ( @{ $self->additional_directories } ) {
    my ( $p, $source ) = ref $entry eq 'HASH' ? @{$entry}{qw( path source )} : ( $entry, undef );
    next unless defined $p && length $p;
    $p = $self->home.'/'.$1 if $p =~ m{\A~/(.*)\z}s;
    $p = $self->home if $p eq '~';
    $p = $base.'/'.$p unless path($p)->is_absolute;
    push @out, { path => Langertha::Raider::Permissions::Rule->_lexical($p), source => $source // 'unknown' };
  }
  return @out;
}


sub allowed_roots {
  my ( $self ) = @_;
  my $root = Langertha::Raider::Permissions::Rule->_lexical( path( $self->root )->absolute->stringify );
  return ( $root, $self->additional_directory_paths );
}


sub policy_revision {
  my ( $self ) = @_;
  my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
  return sha256_hex( $json->encode({
    mode    => $self->mode,
    rules   => [ map { [ $_->kind, $_->text, $_->source ] } @{ $self->_file_rules } ],
    session => [ map { $_->text } @{ $self->session_rules } ],
    ( @{ $self->run_rules } ? ( run => [ map { [ $_->text, $_->source ] } @{ $self->run_rules } ] ) : () ),
    dirs    => [ $self->additional_directory_paths ],
    ( $self->ask_outside_roots ? ( outside => 1 ) : () ),
  }) );
}


sub for_subrun {
  my ( $self, %o ) = @_;
  my $isolation = exists $o{worktree_isolation} ? $o{worktree_isolation} : $self->worktree_isolation;
  return ( ref $self )->new(
    root                   => $o{root} // $self->root,
    ( $isolation ? ( worktree_isolation => $isolation ) : () ),
    home                   => $self->home,
    mode                   => $self->mode,
    mode_source            => $self->mode_source,
    rules                  => $self->rules,
    additional_directories => $self->additional_directories,
    source_servers         => $self->source_servers,
    session_rules          => $self->session_rules,
    run_rules              => $self->run_rules,
    ask_outside_roots      => $self->ask_outside_roots,
  );
}


sub own_run_rules {
  my ( $self ) = @_;
  $self->_set_run_rules( [ @{ $self->run_rules } ] );
  return;
}


sub move_to {
  my ( $self, %o ) = @_;
  croak __PACKAGE__.'->move_to needs a root' unless defined $o{root} && length $o{root};
  $self->_set_root( $o{root} );
  $o{worktree_isolation} ? $self->_set_worktree_isolation( $o{worktree_isolation} ) : $self->_clear_worktree_isolation;
  return;
}

#### Deciding

sub _ctx_base {
  my ( $self ) = @_;
  my $both = sub {
    my $abs  = Langertha::Raider::Permissions::Rule->_lexical( path( $_[0] )->absolute->stringify );
    my $real = realpath($abs);
    return defined $real && $real ne $abs ? [ $abs, $real ] : [ $abs ];
  };
  return { roots => $both->( $self->root ), homes => $both->( $self->home ) };
}


sub is_builtin_call {
  my ( $self, $call ) = @_;
  my ( $builtin ) = $self->_call_origin($call);
  return $builtin ? 1 : 0;
}

sub _call_origin {
  my ( $self, $call ) = @_;
  my $source = $call->{source};
  return ( 0, undef ) unless defined $source;
  return ( 0, $1 ) if $source =~ /\Acatalog:(.+)\z/s;
  return ( 0, $self->source_servers->{$source} ) if exists $self->source_servers->{$source};
  return ( 1, undef );
}

# What a call does, for the mode: control, read, network, change or unknown;
# and the effect words for a reason.
sub _call_class {
  my ( $self, $name, $builtin ) = @_;
  return ( 'unknown', [] ) unless $builtin;
  return ( 'control', [] ) if $CONTROL{$name};
  my $effects = Langertha::Raider::ToolEffects->effects_for($name) // return ( 'unknown', [] );
  my @change = grep { $_ eq 'write' || $_ eq 'code' || $_ eq 'message' } @$effects;
  return ( 'change', \@change ) if @change;
  return ( 'network', [ 'network' ] ) if grep { $_ eq 'network' } @$effects;
  return ( 'read', [] );
}

sub decide {
  my ( $self, $call, %opt ) = @_;
  croak __PACKAGE__.'->decide needs a call hash' unless ref $call eq 'HASH';
  my $name = $call->{name} // '';
  my ( $builtin, $server ) = $self->_call_origin($call);
  my $ctx   = { %{ $self->_ctx_base }, builtin => $builtin, server => $server };
  my @rules = $self->rule_list;
  my $mode  = $self->mode;

  if ( my $rule = first { $_->kind eq 'deny' && $_->matches( $call, $ctx ) } @rules ) {
    return $self->_by_rule( deny => $rule,
      "denied by rule '".$rule->text."' from ".$rule->source );
  }

  return $self->_by_mode( allow => 'bypassPermissions mode' ) if $mode eq 'bypassPermissions';

  my ( $class, $effects ) = $self->_call_class( $name, $builtin );

  return $self->_by_mode( deny => 'plan mode: '.$name.' '.join( ' and ', map { $EFFECT_TEXT{$_} } @$effects )
    .', which plan mode does not allow; present your plan with exit_plan_mode first' )
    if $mode eq 'plan' && $class eq 'change';

  if ( my $rule = first { $_->kind eq 'ask' && $_->matches( $call, $ctx ) } @rules ) {
    return $self->_by_rule( ask => $rule,
      "rule '".$rule->text."' from ".$rule->source.' asks before this call' );
  }

  if ( my @allow = $self->_allowing_rules( $call, $ctx, $builtin, \@rules ) ) {
    my %seen;
    return {
      verdict => 'allow',
      by      => 'rule',
      rule    => join( ', ', map { $_->text } @allow ),
      source  => join( ', ', grep { !$seen{$_}++ } map { $_->source } @allow ),
      reason  => 'allowed by rule '.join( ', ', map { "'".$_->text."'" } @allow ),
      mode    => $mode,
    };
  }

  # Plan mode is entered with the person's consent, as in Claude Code (ADR 0025).
  return $self->_by_mode( ask => $mode.' mode asks before this call: enter_plan_mode switches the session to '
    .'plan mode (read and plan only, no changes until a plan is approved)' )
    if $builtin && $name eq 'enter_plan_mode' && $mode ne 'plan';
  # A path outside the root and the additional directories, in the Claude layout (ADR 0023).
  if ( $self->ask_outside_roots && $builtin && !$opt{skip_roots} ) {
    if ( my ( $outside ) = $self->outside_paths($call) ) {
      return $self->_by_mode( ask => $mode.' mode asks before this call: '.$name.' requested permissions to '
        .( $class eq 'change' ? 'write to ' : 'read from ' ).$outside
        .", which is outside the project root and the additional directories, but you haven't granted it yet" );
    }
  }
  return $self->_by_mode( allow => $mode.' mode' ) if $class eq 'read' || $class eq 'control';
  return $self->_by_mode( allow => 'auto mode, a read-only bash command' )
    if $mode eq 'auto' && $builtin && ($name eq 'bash' || $name eq 'monitor') && $self->_read_only_bash($call);
  return $self->_by_mode( allow => $mode.' mode, inside the allowed directories' )
    if ( $mode eq 'acceptEdits' || $mode eq 'auto' ) &&$builtin && $self->_edit_in_allowed_roots( $call, $ctx );
  # A worktree of the session is an edit too (ADR 0032 §4).
  return $self->_by_mode( allow => $mode.' mode, a worktree of the session' )
    if ( $mode eq 'acceptEdits' || $mode eq 'auto' ) && $builtin && $WORKTREE_TOOL{$name};

  my $what = $class eq 'unknown'
    ? $name.' is not a tool of raider'.( defined $server ? " (MCP server '".$server."')" : '' )
    : $name.' '.join( ' and ', map { $EFFECT_TEXT{$_} } @$effects );
  return $self->_by_mode( ask => $mode.' mode asks before this call: '.$what );
}


sub rule_matches {
  my ( $self, $text, $call ) = @_;
  my $rule = Langertha::Raider::Permissions::Rule->new( text => $text, source => 'hook if', kind => 'ask' );
  return undef unless $rule->is_valid;
  my ( $builtin, $server ) = $self->_call_origin($call);
  return $rule->matches( $call, { %{ $self->_ctx_base }, builtin => $builtin, server => $server } ) ? 1 : 0;
}

sub _by_rule {
  my ( $self, $verdict, $rule, $reason ) = @_;
  return {
    verdict => $verdict,
    by      => 'rule',
    rule    => $rule->text,
    source  => $rule->source,
    reason  => $reason,
    mode    => $self->mode,
  };
}

sub _by_mode {
  my ( $self, $verdict, $reason ) = @_;
  return {
    verdict => $verdict,
    by      => 'mode',
    source  => $self->mode_source,
    reason  => $reason,
    mode    => $self->mode,
  };
}

# The allow rules that together allow the call: one that matches it, or for
# raider's bash, one per part of a command of several parts.
sub _allowing_rules {
  my ( $self, $call, $ctx, $builtin, $rules ) = @_;
  my @allow = grep { $_->kind eq 'allow' } @$rules;
  if ( my $rule = first { $_->matches( $call, $ctx ) } @allow ) {
    return ( $rule );
  }
  return unless $builtin && grep { ($call->{name} // '') eq $_ } qw( bash monitor );
  my $command = ref $call->{arguments} eq 'HASH' ? $call->{arguments}{command} : undef;
  return unless defined $command && !ref $command;
  my $shell = Langertha::Raider::Permissions::Rule->shell_parts($command);
  return if $shell->{opaque} || !@{ $shell->{parts} };
  my @bash = grep { $_->family eq 'bash' } @allow;
  my ( @used, %seen );
  for my $part ( @{ $shell->{parts} } ) {
    my $rule = first { $_->covers_command_part($part) } @bash or return;
    push @used, $rule unless $seen{ refaddr $rule }++;
  }
  return @used;
}

sub _read_only_bash {
  my ( $self, $call ) = @_;
  my $command = ref $call->{arguments} eq 'HASH' ? $call->{arguments}{command} : undef;
  return Langertha::Raider::Permissions::ReadOnlyBash->covers($command);
}

sub _edit_in_allowed_roots {
  my ( $self, $call, $ctx ) = @_;
  my $name = $call->{name} // '';
  return 0 unless $WRITER{$name};
  my $path = ref $call->{arguments} eq 'HASH' ? $call->{arguments}{path} : undef;
  return 0 unless defined $path && !ref $path && length $path;
  return $self->outside_paths($call) ? 0 : 1;
}

sub outside_paths {
  my ( $self, $call ) = @_;
  my $name = $call->{name} // '';
  return unless $PATH_TOOL{$name};
  my $path = ref $call->{arguments} eq 'HASH' ? $call->{arguments}{path} : undef;
  $path = '.' if ( !defined $path || ( !ref $path && !length $path ) ) && ( $name eq 'glob' || $name eq 'grep' );
  return unless defined $path && !ref $path && length $path;
  my @roots = map {
    my $real = realpath($_);
    ( $_, ( defined $real ? $real : () ) );
  } $self->allowed_roots;
  return grep {
    my $p = $_;
    !first { $p eq $_ || index( $p, ( $_ eq '/' ? '/' : $_.'/' ) ) == 0 } @roots;
  } Langertha::Raider::Permissions::Rule->call_paths( $path, $self->_ctx_base );
}


#### Edits into the main checkout


sub worktree_class { 'Langertha::Raider::Worktree' }

sub main_checkout_refusal {
  my ( $self, $call ) = @_;
  my $iso = $self->worktree_isolation or return;
  return unless $WRITER{ $call->{name} // '' };
  my $path = ref $call->{arguments} eq 'HASH' ? $call->{arguments}{path} : undef;
  return unless defined $path && !ref $path && length $path;
  my ( $abs, $real ) = Langertha::Raider::Permissions::Rule->call_paths( $path, $self->_ctx_base );
  $real //= $abs;
  my ( $top, $tree ) = map { $self->_real_dir($_) } @$iso{qw( top worktree )};
  my $inside = sub { my ( $dir ) = @_; $real eq $dir || index( $real, $dir.'/' ) == 0 };
  return unless $inside->($top);
  return if $inside->($tree);
  # Any other worktree of the repository is not the main checkout either.
  my $list = $self->worktree_class->new->list($top);
  return if first { !$_->{main} && $inside->( $self->_real_dir( $_->{path} ) ) } @{ $list->{worktrees} // [] };
  my $rel = substr( $real, length $top ) =~ s{\A/}{}r;
  return $abs.' is in the main checkout '.$top.'; this session works in the worktree '.$tree.'. Edit '
    .$tree.( length $rel ? '/'.$rel : '' ).' instead.';
}


sub _real_dir {
  my ( $self, $dir ) = @_;
  my $abs = Langertha::Raider::Permissions::Rule->_lexical( path($dir)->absolute->stringify );
  return realpath($abs) // $abs;
}

#### Reading below a search root

sub read_rules_active {
  my ( $self ) = @_;
  return ( grep { $_->kind ne 'allow' && grep { $_ eq 'read_file' } @{ $_->tools } } $self->rule_list ) ? 1 : 0;
}


sub hides_read {
  my ( $self, $path ) = @_;
  # A search the gate let reach a directory outside the roots shows what
  # it finds there: only the rules decide here (ADR 0023).
  return $self->decide( { name => 'read_file', source => 'raider', arguments => { path => $path } }, skip_roots => 1 )
    ->{verdict} ne 'allow' ? 1 : 0;
}


#### Session rule suggestion

sub suggest_rule {
  my ( $self, $call ) = @_;
  my $name = $call->{name} // '';
  my $args = ref $call->{arguments} eq 'HASH' ? $call->{arguments} : {};
  my ( $builtin, $server ) = $self->_call_origin($call);
  unless ($builtin) {
    return unless defined $server;
    # A configured server's tool already carries the prefix (ADR 0029).
    return index($name, 'mcp__'.$server.'__') == 0 ? $name : 'mcp__'.$server.'__'.$name;
  }
  if ( $name eq 'bash' || $name eq 'monitor' ) {
    my $command = $args->{command};
    return unless defined $command && !ref $command;
    ( my $trimmed = $command ) =~ s/\A\s+|\s+\z//g;
    return if !length $trimmed
      || Langertha::Raider::Permissions::Rule->shell_parts($trimmed)->{opaque};
    return 'Bash('.$trimmed.')';
  }
  if ( $READER{$name} && $self->outside_paths($call) ) {
    my ( $abs ) = Langertha::Raider::Permissions::Rule->call_paths( $args->{path} // '.', $self->_ctx_base );
    my $dir = $name eq 'read_file' ? path($abs)->parent->stringify : $abs;
    return 'Read(/'.$dir.( $dir eq '/' ? '' : '/' ).'**)';
  }
  if ( $WRITER{$name} ) {
    my $path = $args->{path};
    return 'Edit' unless defined $path && !ref $path && length $path;
    my $ctx  = $self->_ctx_base;
    my ( $abs ) = Langertha::Raider::Permissions::Rule->call_paths( $path, $ctx );
    my $dir  = path($abs)->parent->stringify;
    my $root = $ctx->{roots}[0];
    return 'Edit(/**)' if $dir eq $root;
    return 'Edit('.substr( $dir, length($root) + 1 ).'/**)' if index( $dir, $root.'/' ) == 0;
    return 'Edit(/'.$dir.'/**)';
  }
  if ( $name eq 'web_fetch' ) {
    my $url  = $args->{url};
    my $uri  = defined $url && !ref $url ? URI->new($url) : undef;
    my $host = $uri && $uri->can('host') ? lc( $uri->host // '' ) : '';
    return length $host ? 'WebFetch(domain:'.$host.')' : 'WebFetch';
  }
  return Langertha::Raider::ToolNames->claude_name($name) // $name;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Permissions - Internal permission policy of a raider session: mode, rules with sources, session rules

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $policy = Langertha::Raider::Permissions->new(
      root  => $root,
      mode  => 'default',
      rules => {
        allow => [ { rule => 'Bash(npm run test:*)', source => '.claude/settings.json' } ],
        deny  => [ { rule => 'Read(./.env)',         source => '.raider/config.yml' } ],
      },
      additional_directories => [ { path => '../docs', source => '.claude/settings.json' } ],
    );

    my $verdict = $policy->decide( { name => 'bash', source => 'engine:2',
      arguments => { command => 'npm run test' } } );
    # { verdict => 'allow', by => 'rule', rule => 'Bash(npm run test:*)', source => ..., reason => ... }

    $policy->add_session_rule('Bash(make)');
    $policy->set_mode('acceptEdits');
    my $child = $policy->for_subrun;     # same mode and rules, shared session rules

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The permission policy of one raider session (ADR 0021, building on the gate
and the approval of ADR 0005): a mode, the allow / ask / deny rules in Claude
Code syntax (L<Langertha::Raider::Permissions::Rule>) with the source of
each, the rules the person allowed for this session, and the additional
directories. L</decide> answers the canonical call the tool gate of
L<Langertha::Raider> sees with C<allow>, C<ask> or C<deny>. The policy only
decides -- asking the person, recording events and building approvals is the
application's part.

Order of a decision: a matching deny rule (from any source) refuses; in
C<bypassPermissions> everything else is allowed; in C<plan> a tool that
changes something (C<write>, C<code> or C<message> effects) is refused; a
matching ask rule asks; a matching allow rule (or session rule) allows;
without a rule the mode decides:

=over

=item C<default> -- tools that only read, or have no effect outside the run,
and the person-facing control tools (C<ask_user>, C<raider_ask_user>,
C<todo_write>, C<skill>, C<exit_plan_mode>) are allowed; everything that
writes, runs code, talks to the network or sends messages asks, and so does
every tool raider does not know (a foreign MCP tool). C<enter_plan_mode>
asks too, in every mode but C<plan> and C<bypassPermissions>: the person
agrees to plan mode, as in Claude Code (ADR 0025).

=item C<acceptEdits> -- as C<default>, and C<write_file> / C<edit_file> /
C<multi_edit> are allowed inside the root or an additional directory, and
so are C<enter_worktree> and C<exit_worktree> (ADR 0032 E<sect>4).

=item C<auto> -- as C<acceptEdits>, and bash commands that only read are
allowed without asking: a fixed list
(L<Langertha::Raider::Permissions::ReadOnlyBash>) where every part of the
command must be on it and none may hold a substitution or a redirection into
a file. The raider equivalent of Claude Code's C<defaultMode: "auto">;
everything else asks, deny and ask rules hold, the person's allow rules add
to it.

=item C<plan> -- as C<default> for reading and network tools; changing tools
are refused, even when an allow rule names them.

=item C<bypassPermissions> -- everything is allowed except what a deny rule
refuses.

=back

Effects come from L<Langertha::Raider::ToolEffects>, and only for raider's
own tools: a tool from a C<catalog:NAME> source, or from a source named in
L</source_servers>, is foreign, whatever its name.

=head2 root

The project root. Required. Relative rule paths and relative additional
directories are read against it, and so are relative path arguments, as the
file tools do. The application's policy follows its working root
(L</move_to>).

=head2 home

The home for C<~/> in rules and directories. Defaults to
L<Langertha::Raider::Home/home_dir>.

=head2 mode

The permission mode: C<default>, C<acceptEdits>, C<auto>, C<plan> or
C<bypassPermissions>. Croaks on construction with any other name; changed
with L</set_mode>.

=head2 mode_source

Where the mode came from (C<--permission-mode>, a settings file, ...), for
reports.

=head2 rules

The configured rules as C<< { allow => [ { rule, source } ], ask => [...], deny => [...] } >>
-- the shape of L<Langertha::Raider::Context::Settings/permissions>. Every
list keeps its order; sources are mixed freely.

=head2 additional_directories

C<< [ { path, source } ] >>: directories outside the root the file tools may
use. C<~/x> is under the home, a relative path under the root.

=head2 source_servers

C<< { 'engine:N' => 'server' } >>: tool sources that are foreign MCP servers,
with the name C<mcp__server> rules use. A C<catalog:NAME> source is always
the foreign server C<NAME>; every other source (C<engine:N>, C<inline>,
C<raider>) is raider's own unless named here.

=head2 session_rules

The rules allowed for this session (L</add_session_rule>), as
L<Langertha::Raider::Permissions::Rule> objects. The array is shared with
every policy L</for_subrun> derives, so a rule allowed in a sub-run holds in
the session and the other way round. Lives in memory only.

=head2 run_rules

The allow rules of the run in progress (L</add_run_rules>): the
C<allowed-tools> of a C</name> run or of an entry the model loaded with the
C<skill> tool (ADR 0030 E<sect>3), as L<Langertha::Raider::Permissions::Rule>
objects with their source (C</NAME allowed-tools>). Shared with every policy
L</for_subrun> derives, like L</session_rules>, and emptied in place by
L</clear_run_rules> when the run ends -- unless a policy took its own copy
(L</own_run_rules>).

=head2 ask_outside_roots

False by default: the file and search tools are confined to the root and
the L</additional_directories> and refuse every other path themselves (the
raider layout). True in the Claude layout (ADR 0023), where those tools are
not confined: a call of C<read_file>, C<list_files>, C<write_file>,
C<edit_file>, C<multi_edit>, C<glob> or C<grep> whose path -- as written or
as real path -- leaves the allowed roots is then not allowed by the mode in
C<default>, C<acceptEdits>, C<auto> and C<plan>: it asks, unless an allow
rule (C<Read(//tmp/**)>, C<Edit(~/notes/**)>) covers it. Deny rules and
C<plan> refuse first; C<bypassPermissions> allows it, as Claude Code does.

=head2 worktree_isolation

C<< { top => '/repo', worktree => '/repo/.claude/worktrees/agent-1' } >>
when the run works in a worktree (ADR 0032 E<sect>3): the main checkout's
top and the worktree's. Then L</main_checkout_refusal> refuses edits into
the main checkout. Unset by default.

=head2 ignored_modes

C<< [ { value, source, reason } ] >>: mode names from files that are not
modes, skipped by L</from_sources>. For reports.

=head2 from_sources

    my $policy = Langertha::Raider::Permissions->from_sources(
      root     => $root,
      cli_mode => { value => 'plan', source => '--permission-mode' },   # optional
      sources  => [ $config->permissions, $settings->permissions ],
    );

The policy of a session from its sources, each in the shape of
L<Langertha::Raider::Context::Settings/permissions>. The rules and
additional directories of all sources are concatenated. The mode is the
first of C<cli_mode> and the sources' C<default_mode> in the order given
that is a mode; a C<default_mode> that is none is skipped and kept in
L</ignored_modes>. Without any, C<default>. C<session_rules>, C<run_rules>, C<source_servers>,
C<ask_outside_roots> and C<worktree_isolation> are passed on as they are (a policy read again keeps the
session's rules). Croaks on an invalid C<cli_mode> -- the command line
refuses it before.

=head2 report

The policy for C<config explain> and C</permissions>: C<mode>,
C<mode_source>, C<mode_note> (only in C<auto> mode: how it maps), C<ignored_modes>, C<rules> (per kind the valid rules with
their source, session rules included), C<invalid_rules> (with C<kind> and
C<error>) and C<additional_directories> (absolute, with their source).

=head2 mode_note

How the C<auto> mode maps, for C<config explain> and C</permissions>: for a
mode from the Claude settings C<claude auto -> raider acceptEdits +
read-only bash allowlist>. Nothing in any other mode.

=head2 modes

The mode names, in display order. Callable on the class.

=head2 is_mode

    Langertha::Raider::Permissions->is_mode('acceptEdits');   # 1

True for a valid mode name (exactly as Claude Code writes it).

=head2 rule_list

Every valid rule: the configured ones (deny, ask, allow), then the
session rules, then the run rules.

=head2 invalid_rules

The configured rules that could not be parsed or name an unknown tool; they
are ignored.

=head2 add_session_rule

    my $rule = $policy->add_session_rule('Bash(make test)');

Allows what the rule names for the rest of the session (source C<session>).
Croaks on an invalid rule. Returns the rule; adding the same text again
changes nothing.

=head2 add_run_rules

    my @added = $policy->add_run_rules( [ 'Bash(git status:*)', 'Read' ], '/review allowed-tools' );

Allows what the rules name for the run in progress only (L</run_rules>),
with C<$source> as their source (default C<run>). Deny and ask rules, and
plan mode, still win. A text that is no valid rule is skipped, as an
invalid rule never widens anything; one already there with the same source
is not added twice. Returns the rules that were added.

=head2 clear_run_rules

    $policy->clear_run_rules;            # all of them: the run ended
    $policy->clear_run_rules(@added);    # only these

Takes run rules out again, in place, so every policy sharing them
(L</for_subrun>) loses them too.

=head2 set_mode

    my $from = $policy->set_mode( 'default', 'exit_plan_mode' );

Switches the mode; C<$source> (default C<session>) becomes
L</mode_source>. Returns the previous mode. Croaks on an unknown mode.

=head2 additional_directory_paths

The additional directories as absolute paths (C<..> taken out).

=head2 allowed_roots

The root followed by the additional directories, absolute: where the file
tools may work.

=head2 policy_revision

The SHA-256 (hex) over the mode, every rule with its source, the session
rules, the run rules and the additional directories. An approval
(L<Langertha::Raider::Approval>) is bound to it: switching the mode or
allowing a session rule invalidates approvals given before.

=head2 for_subrun

    my $policy_of_subagent = $policy->for_subrun;

The policy a sub-run (a sub-agent, a delegated task) uses: a new object with
the mode this policy has now, the same configured rules, additional
directories and source servers, and the B<same> session rules and run
rules arrays. A mode
change of either afterwards stays with that one (a sub-agent leaving plan
mode does not take the session with it); a session rule allowed in either
holds in both. A sub-run never gets more than its parent had: there is no
argument to widen it.

    my $isolated = $policy->for_subrun(
      root               => '/repo/.claude/worktrees/agent-1',
      worktree_isolation => { top => '/repo', worktree => '/repo/.claude/worktrees/agent-1' },
    );

A subagent in a worktree of its own (ADR 0032 E<sect>2) moves the policy:
C<root> replaces the root (the rules and additional directories mean the
same files in the copy), C<worktree_isolation> sets
L</worktree_isolation>. Without them the sub-run keeps the parent's -- a
subagent of an isolated one works in the same worktree.

=head2 own_run_rules

    $policy_of_subagent->own_run_rules;

Takes this policy's own copy of the L</run_rules> it shares, as they are
now: rules a later run adds do not reach it, and the end of the run that
had them does not take them away. A background subagent does this when it
starts (ADR 0027): it outlives the run it was started in.

=head2 move_to

    $policy->move_to(
      root               => '/repo/.claude/worktrees/session-1',
      worktree_isolation => { top => '/repo', worktree => '/repo/.claude/worktrees/session-1' },
    );
    $policy->move_to( root => '/repo' );   # back: no isolation

Moves this policy to another root in place -- the application's policy
follows its working root (ADR 0032 E<sect>3): L</root> becomes C<root>,
L</worktree_isolation> becomes C<worktree_isolation> or is cleared without
it. Mode, rules, session and run rules stay; so do the approvals bound to
L</policy_revision>, which the root is no part of. Policies a
L</for_subrun> made before keep their root.

=head2 is_builtin_call

    my $ours = $policy->is_builtin_call( { name => 'enter_worktree', source => 'engine:3' } );

True when the call's tool is raider's own: its source is no C<catalog:NAME>
and none of the L</source_servers>.

=head2 decide

    my $verdict = $policy->decide( { name => $tool, source => $source, arguments => \%args } );

The verdict on the canonical call: a hash with C<verdict> (C<allow>, C<ask>,
C<deny>), C<by> (C<rule> or C<mode>), C<reason> (a sentence for the person
or the model), C<mode>, and for a rule C<rule> (its text) and C<source>; for
the mode C<source> is L</mode_source>. A command of several parts that
several allow rules cover together names all of them. The shape is the one
the tool gate of L<Langertha::Raider> takes.

With L</ask_outside_roots> a call of a file or search tool whose path leaves
the root and the additional directories asks (after deny, plan, ask and
allow rules, before the mode allows a read or an edit); C<< skip_roots => 1 >>
as a further argument leaves that check out (L</hides_read> does).

=head2 rule_matches

    my $yes = $policy->rule_matches( 'Bash(git *)', $call );

Whether one rule in Claude Code syntax applies to the canonical call --
the C<if> field of a Claude Code hook (ADR 0022). It matches the way a
deny or ask rule does (any part of a bash command, the written or the real
path), and is not added to the policy. C<undef> for a rule that cannot be
parsed: the caller decides what that means (a hook then runs, as in Claude
Code when it cannot tell).

=head2 outside_paths

    my @outside = $policy->outside_paths($call);

For a call of a file or search tool (C<read_file>, C<list_files>,
C<write_file>, C<edit_file>, C<multi_edit>, C<glob>, C<grep>): the
absolute forms of its C<path> -- as written, and as real path with
symbolic links followed -- that lie outside the root and the additional
directories. Empty when the path stays inside (or the call is of another
tool). A symbolic link inside the root that points out of it is outside.

=head2 worktree_class

The class that lists a repository's worktrees for
L</main_checkout_refusal>: L<Langertha::Raider::Worktree>.

=head2 main_checkout_refusal

    my $text = $policy->main_checkout_refusal($call);   # or nothing

With L</worktree_isolation>: for a C<write_file>, C<edit_file> or
C<multi_edit> whose C<path> (relative to the L</root>, real path followed)
is inside the main checkout's top but outside every worktree of the
repository (C<git worktree list>), the refusal of ADR 0032 E<sect>3:

    PATH is in the main checkout TOP; this session works in the worktree W. Edit W/REL instead.

Nothing for every other call. The application's gate asks it before any
rule or mode (L<Langertha::Raider::Application/tool_gate>).

=head2 read_rules_active

True when a deny or ask rule applies to reading files (C<Read(...)>,
C<read_file>): only then can L</hides_read> hide anything.

=head2 hides_read

    next if $policy->hides_read('/abs/path/secrets/key');

True when reading the file at the absolute C<$path> would not simply be
allowed: a deny rule refuses it or an ask rule asks. C<glob> and C<grep>
leave such files out of their results (L<Langertha::Raider::SearchTools/hider>)
instead of refusing the whole search.

=head2 suggest_rule

    my $text = $policy->suggest_rule($call);   # 'Bash(make test)'

The rule the person would allow with "yes, for this session": C<bash> ->
C<Bash(EXACT COMMAND)>; C<write_file> / C<edit_file> / C<multi_edit> ->
C<Edit(DIR/**)> for the directory of the file (C<Edit(/**)> in the root,
C<Edit(//ABS/**)> outside it); a reading file or search tool whose path
leaves the root and the additional directories (L</outside_paths>) ->
C<Read(//DIR/**)> for the directory of the file, or the directory searched; C<web_fetch> -> C<WebFetch(domain:HOST)>; a foreign tool ->
C<mcp__SERVER__TOOL> (a tool of a configured server, already named so,
keeps its name); any other tool -> its name. Returns nothing when no
rule can name the call safely: a command with substitutions, redirections
into files or heredocs, or a foreign tool whose server has no
name.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Permissions::Rule>

=item * L<Langertha::Raider::Approval>

=item * L<Langertha::Raider::ToolEffects>

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
