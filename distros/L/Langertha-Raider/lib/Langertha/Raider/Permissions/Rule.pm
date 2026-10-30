package Langertha::Raider::Permissions::Rule;
# ABSTRACT: Internal permission rule in Claude Code syntax, parsed and matched against tool calls
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Cwd qw( realpath );
use Path::Tiny;
use URI;
use Langertha::Raider::ToolEffects;
use Langertha::Raider::ToolNames;


has text => ( is => 'ro', isa => 'Str', required => 1 );


has source => ( is => 'ro', isa => 'Str', required => 1 );


has kind => ( is => 'ro', isa => 'Str', required => 1 );


has _parsed => ( is => 'ro', isa => 'HashRef', lazy_build => 1, init_arg => undef );

has _regex_cache => ( is => 'ro', isa => 'HashRef', default => sub { {} }, init_arg => undef );

sub BUILD {
  my ( $self ) = @_;
  croak __PACKAGE__.' kind must be allow, ask or deny, not '.$self->kind
    unless $self->kind =~ /\A(?:allow|ask|deny)\z/;
  $self->_parsed;
  return;
}

my @READERS = qw( read_file list_files glob grep );
my @WRITERS = qw( write_file edit_file multi_edit );

# The family of a rule name decides what a specifier means and which tools
# the rule applies to.
my %FAMILY = (
  Read       => [ path   => @READERS ],
  read_file  => [ path   => @READERS ],
  Edit       => [ path   => @WRITERS ],
  Write      => [ path   => @WRITERS ],
  MultiEdit  => [ path   => @WRITERS ],
  write_file => [ path   => @WRITERS ],
  edit_file  => [ path   => @WRITERS ],
  multi_edit => [ path   => @WRITERS ],
  LS         => [ path   => 'list_files' ],
  list_files => [ path   => 'list_files' ],
  Glob       => [ path   => 'glob' ],
  glob       => [ path   => 'glob' ],
  Grep       => [ path   => 'grep' ],
  grep       => [ path   => 'grep' ],
  Bash       => [ bash   => 'bash', 'monitor' ],
  bash       => [ bash   => 'bash', 'monitor' ],
  Monitor    => [ bash   => 'monitor' ],
  monitor    => [ bash   => 'monitor' ],
  WebFetch   => [ domain => 'web_fetch' ],
  web_fetch  => [ domain => 'web_fetch' ],
  Agent      => [ named  => 'agent' ],
  Task       => [ named  => 'agent' ],
  agent      => [ named  => 'agent' ],
  Skill      => [ named  => 'skill' ],
  skill      => [ named  => 'skill' ],
);

# The argument a named rule (Agent(name), Skill(name)) is held against.
my %NAME_ARG = ( agent => 'subagent_type', skill => 'skill' );
# The value a named argument has when the call leaves it out: an agent call
# without subagent_type starts general-purpose (ADR 0020 §3).
my %NAME_DEFAULT = ( agent => 'general-purpose' );

sub _build__parsed {
  my ( $self ) = @_;
  my $text = $self->text;
  $text =~ s/\A\s+|\s+\z//g;
  return { error => 'empty rule' } unless length $text;

  if ( $text =~ /\Amcp__/ ) {
    return { error => 'an MCP rule takes no specifier' } if $text =~ /\(/;
    my ( $server, $tool ) = $text =~ /\Amcp__(.+?)(?:__(.+))?\z/s;
    return { error => 'no MCP server name' } unless defined $server && length $server;
    return {
      family     => 'mcp',
      tool       => $text,
      tools      => [],
      mcp_server => $server,
      mcp_tool   => ( defined $tool && $tool ne '*' ? $tool : undef ),
    };
  }

  my ( $name, $spec ) = $text =~ /\A([A-Za-z_][A-Za-z0-9_]*)(?:\((.*)\))?\z/s
    or return { error => 'not a rule: expected Tool or Tool(specifier)' };

  my ( $family, @tools );
  if ( my $f = $FAMILY{$name} ) {
    ( $family, @tools ) = @$f;
  }
  else {
    my $raider = Langertha::Raider::ToolNames->raider_name($name)
      // ( $self->_known_raider_tool($name) ? $name : undef );
    return { error => "unknown tool '".$name."'" } unless defined $raider;
    ( $family, @tools ) = ( 'tool', $raider );
  }

  return { family => $family, tool => $name, tools => \@tools } unless defined $spec;

  $spec =~ s/\A\s+|\s+\z//g;
  return { error => 'empty specifier' } unless length $spec;
  return { error => $name.' takes no specifier' } if $family eq 'tool';
  if ( $family eq 'domain' ) {
    my ( $domain ) = $spec =~ /\Adomain:\s*(\S+)\z/
      or return { error => 'WebFetch takes domain:HOST' };
    return { family => $family, tool => $name, tools => \@tools, specifier => $spec, domain => lc $domain };
  }
  return { family => $family, tool => $name, tools => \@tools, specifier => $spec };
}

sub _known_raider_tool {
  my ( $self, $name ) = @_;
  return defined( Langertha::Raider::ToolNames->claude_name($name) )
    || defined( Langertha::Raider::ToolEffects->effects_for($name) );
}

sub is_valid { !defined $_[0]->_parsed->{error} }


sub error { $_[0]->_parsed->{error} }


sub family { $_[0]->_parsed->{family} }


sub tools { [ @{ $_[0]->_parsed->{tools} // [] } ] }


sub specifier { $_[0]->_parsed->{specifier} }


sub mcp_server { $_[0]->_parsed->{mcp_server} }
sub mcp_tool   { $_[0]->_parsed->{mcp_tool} }


sub as_hash {
  my ( $self ) = @_;
  return {
    rule   => $self->text,
    source => $self->source,
    kind   => $self->kind,
    ( $self->is_valid ? () : ( error => $self->error ) ),
  };
}


#### Matching

sub matches {
  my ( $self, $call, $ctx ) = @_;
  return 0 unless $self->is_valid;
  my $p    = $self->_parsed;
  my $name = $call->{name} // '';
  my $args = ref $call->{arguments} eq 'HASH' ? $call->{arguments} : {};

  if ( $p->{family} eq 'mcp' ) {
    return 0 if $ctx->{builtin};
    return 0 unless defined $ctx->{server} && $ctx->{server} eq $p->{mcp_server};
    # A configured server's tools carry the mcp__SERVER__ prefix (ADR 0029);
    # the rule names the tool part of that name.
    my $prefix = 'mcp__'.$p->{mcp_server}.'__';
    my $tool = index($name, $prefix) == 0 ? substr($name, length $prefix) : $name;
    return !defined $p->{mcp_tool} || $p->{mcp_tool} eq $tool ? 1 : 0;
  }

  return 0 unless grep { $_ eq $name } @{ $p->{tools} };
  # A raider name on a foreign tool: only to refuse or to ask.
  return 0 if !$ctx->{builtin} && $self->kind eq 'allow';
  return 1 unless defined $p->{specifier};

  return $self->_matches_bash($args->{command}) if $p->{family} eq 'bash';
  return $self->_matches_domain($args->{url})   if $p->{family} eq 'domain';
  if ( $p->{family} eq 'named' ) {
    my $value = $args->{ $NAME_ARG{$name} };
    $value = $NAME_DEFAULT{$name} unless defined $value && length $value;
    return defined $value && !ref $value && $value eq $p->{specifier} ? 1 : 0;
  }
  return $self->_matches_path($name, $args, $ctx);
}


#### Bash

sub _matches_bash {
  my ( $self, $command ) = @_;
  return 0 unless defined $command && !ref $command;
  my $shell = $self->shell_parts($command);
  if ( $self->kind eq 'allow' ) {
    return 0 if $shell->{opaque};
    # An exact rule may name a whole command of several parts.
    ( my $whole = $command ) =~ s/\A\s+|\s+\z//g;
    return 1 if $self->specifier !~ /\*/ && $whole eq $self->specifier;
    return 0 unless @{ $shell->{parts} } == 1;
    return $self->covers_command_part( $shell->{parts}[0] );
  }
  ( my $whole = $command ) =~ s/\A\s+|\s+\z//g;
  return 1 if $whole =~ $self->_bash_regex;
  for my $part ( @{ $shell->{parts} } ) {
    for my $variant ( $self->_part_variants($part) ) {
      return 1 if $variant =~ $self->_bash_regex;
    }
  }
  return 0;
}

sub covers_command_part {
  my ( $self, $part ) = @_;
  return 0 unless $self->is_valid && $self->family eq 'bash';
  return 1 unless defined $self->specifier;
  return $part =~ $self->_bash_regex ? 1 : 0;
}


sub _bash_regex {
  my ( $self ) = @_;
  return $self->_regex_cache->{bash} //= do {
    my $spec = $self->specifier;
    my $glob = sub { join '.*', map { quotemeta } split /\*/, $_[0], -1 };
    $spec =~ /\A(.*?):\*\z/s
      ? qr/\A@{[ $glob->($1) ]}(?:\s.*)?\z/s
      : $spec =~ /\*/
        ? qr/\A@{[ $glob->($spec) ]}\z/s
        : qr/\A\Q$spec\E\z/s;
  };
}

# The forms of a part a deny or ask rule is held against: as written, and
# with leading shell keywords, plain wrappers and VAR=value assignments
# taken off one by one.
my $LEAD = qr/\A(?:if|then|do|else|elif|while|until|time|exec|command|builtin|nohup|sudo|env|!|\{|[A-Za-z_][A-Za-z0-9_]*=(?:'[^']*'|"[^"]*"|\S*))\s+/;

sub _part_variants {
  my ( $self, $part ) = @_;
  my @variants = ( $part );
  my $s = $part;
  push @variants, $s while $s =~ s/$LEAD//;
  return @variants;
}

sub shell_parts {
  my ( $self, $command ) = @_;
  my %out = ( parts => [], opaque => 0 );
  $self->_split_shell( $command // '', \%out, 0 );
  return \%out;
}


sub _split_shell {
  my ( $self, $s, $out, $depth ) = @_;
  if ( $depth > 8 ) { $out->{opaque} = 1; return }
  my $cur = '';
  my $flush = sub {
    ( my $p = $cur ) =~ s/\A\s+|\s+\z//g;
    push @{ $out->{parts} }, $p if length $p;
    $cur = '';
  };
  my $len = length $s;
  my $q   = '';
  my $i   = 0;
  while ( $i < $len ) {
    my $c   = substr $s, $i, 1;
    my $two = substr $s, $i, 2;
    if ( $q eq "'" ) {
      $cur .= $c;
      $q = '' if $c eq "'";
      $i++;
      next;
    }
    if ( $c eq '\\' ) {
      $cur .= substr $s, $i, 2;
      $i += 2;
      next;
    }
    # Substitutions run their own commands, inside double quotes too.
    if ( $two eq '$(' || ( $q eq '' && ( $two eq '<(' || $two eq '>(' ) ) ) {
      my $end = $self->_closing_paren( $s, $i + 1 );
      $out->{opaque} = 1;
      $self->_split_shell( substr( $s, $i + 2, $end - $i - 2 ), $out, $depth + 1 );
      $cur .= ' ';
      $i = $end + 1;
      next;
    }
    if ( $c eq '`' ) {
      my $end = index $s, '`', $i + 1;
      $end = $len if $end < 0;
      $out->{opaque} = 1;
      $self->_split_shell( substr( $s, $i + 1, $end - $i - 1 ), $out, $depth + 1 );
      $cur .= ' ';
      $i = $end + 1;
      next;
    }
    if ( $q eq '"' ) {
      $cur .= $c;
      $q = '' if $c eq '"';
      $i++;
      next;
    }
    if ( $c eq "'" || $c eq '"' ) {
      $q = $c;
      $cur .= $c;
      $i++;
      next;
    }
    if ( $two eq '<<' ) {
      $out->{opaque} = 1;
      $cur .= $two;
      $i += 2;
      next;
    }
    if ( $two eq '&>' || $c eq '>' ) {
      my $j = $i + ( $two eq '&>' ? 2 : 1 );
      $j++ if $j < $len && substr( $s, $j, 1 ) =~ /[>|]/;
      if ( $c eq '>' && substr( $s, $j, 1 ) eq '&' && substr( $s, $j + 1 ) =~ /\A(\d+|-)/ ) {
        $j += 1 + length $1;       # >&2, 2>&1: a descriptor, not a file
      }
      else {
        $j++ if $c eq '>' && substr( $s, $j, 1 ) eq '&';
        $j++ while $j < $len && substr( $s, $j, 1 ) =~ /[ \t]/;
        my ( $target ) = substr( $s, $j ) =~ /\A([^\s;&|()<>]*)/;
        $out->{opaque} = 1 unless $target eq '/dev/null';
        $j += length $target;
      }
      $cur .= substr $s, $i, $j - $i;
      $i = $j;
      next;
    }
    if ( $two eq '&&' || $two eq '||' || $two eq '|&' ) {
      $flush->();
      $i += 2;
      next;
    }
    if ( $c =~ /[;\n|&()]/ ) {
      $flush->();
      $i++;
      next;
    }
    $cur .= $c;
    $i++;
  }
  $out->{opaque} = 1 if $q ne '';
  $flush->();
  return;
}

# The index of the parenthesis that closes the one at $open (quote-aware),
# or the length of $s when there is none.
sub _closing_paren {
  my ( $self, $s, $open ) = @_;
  my ( $depth, $q ) = ( 0, '' );
  for my $i ( $open .. length($s) - 1 ) {
    my $c = substr $s, $i, 1;
    if ( $q ) { $q = '' if $c eq $q; next }
    if ( $c eq "'" || $c eq '"' ) { $q = $c; next }
    $depth++ if $c eq '(';
    if ( $c eq ')' ) { return $i unless --$depth }
  }
  return length $s;
}

#### WebFetch

sub _matches_domain {
  my ( $self, $url ) = @_;
  return 0 unless defined $url && !ref $url;
  my $uri  = URI->new($url);
  my $host = $uri->can('host') ? lc( $uri->host // '' ) : '';
  return 0 unless length $host;
  my $domain = $self->_parsed->{domain};
  if ( $domain =~ /\A\*\.(.+)\z/ ) {
    my $base = $1;
    return length($host) > length($base) && substr( $host, -length($base) - 1 ) eq '.'.$base ? 1 : 0;
  }
  return $host eq $domain ? 1 : 0;
}

#### Paths

sub _matches_path {
  my ( $self, $name, $args, $ctx ) = @_;
  my $path = $args->{path};
  $path = '.' if !defined $path && ( $name eq 'glob' || $name eq 'grep' );
  return 0 unless defined $path && !ref $path && length $path;
  my @candidates = $self->call_paths( $path, $ctx );
  my @regex      = $self->_path_regexes($ctx);
  my $hit = sub {
    my ( $p ) = @_;
    for my $re (@regex) {
      return 1 if grep { $_ =~ $re->{regex} } $self->_with_ancestors($p);
    }
    return 0;
  };
  my $hits = grep { $hit->($_) } @candidates;
  return $self->kind eq 'allow' ? ( $hits == @candidates ? 1 : 0 ) : ( $hits ? 1 : 0 );
}

sub call_paths {
  my ( $self, $path, $ctx ) = @_;
  my $root = $ctx->{roots}[0];
  my $abs  = $self->_lexical( path($path)->is_absolute ? $path : $root.'/'.$path );
  my $real = $self->_real($abs);
  return $real eq $abs ? ( $abs ) : ( $abs, $real );
}


sub _lexical {
  my ( $self, $abs ) = @_;
  my @out;
  for my $seg ( split m{/}, $abs ) {
    next if $seg eq '' || $seg eq '.';
    if ( $seg eq '..' ) { pop @out; next }
    push @out, $seg;
  }
  return '/'.join '/', @out;
}

sub _real {
  my ( $self, $abs ) = @_;
  my ( $cur, @rest ) = ( $abs );
  while ( !-e $cur && $cur ne '/' ) {
    unshift @rest, path($cur)->basename;
    $cur = path($cur)->parent->stringify;
  }
  my $real = realpath($cur) // return $abs;
  return $self->_lexical( join '/', $real, @rest );
}

sub _with_ancestors {
  my ( $self, $p ) = @_;
  my @all = ( $p );
  push @all, $p while $p =~ s{/[^/]+\z}{} && length $p;
  return @all;
}

# The compiled forms of the pattern: one per base it can be read against
# (the root or home as written and as real path).
sub _path_regexes {
  my ( $self, $ctx ) = @_;
  my $spec = $self->specifier;
  my ( $kind, $rel );
  if    ( $spec =~ m{\A//(.*)\z}s )   { ( $kind, $rel ) = ( 'abs',  $1 ) }
  elsif ( $spec =~ m{\A~/(.*)\z}s )   { ( $kind, $rel ) = ( 'home', $1 ) }
  elsif ( $spec eq '~' )              { ( $kind, $rel ) = ( 'home', '' ) }
  elsif ( $spec =~ m{\A\./(.*)\z}s )  { ( $kind, $rel ) = ( 'root', $1 ) }
  elsif ( $spec =~ m{\A/(.*)\z}s )    { ( $kind, $rel ) = ( 'root', $1 ) }
  else {
    ( my $trimmed = $spec ) =~ s{/+\z}{};
    ( $kind, $rel ) = $trimmed =~ m{/} ? ( 'root', $spec ) : ( 'root', '**/'.$trimmed );
  }
  $rel =~ s{/+\z}{};
  my @bases = $kind eq 'abs' ? ( '' ) : @{ $kind eq 'home' ? $ctx->{homes} : $ctx->{roots} };
  my %seen;
  return map {
    my $base = $_;
    my $key  = $kind.'|'.$base;
    $self->_regex_cache->{$key} //= { regex => $self->_glob_regex( $base, $rel ) };
  } grep { !$seen{$_}++ } @bases;
}

sub _glob_regex {
  my ( $self, $base, $rel ) = @_;
  my $re = '';
  my $s  = $rel;
  while ( length $s ) {
    if    ( $s =~ s{\A\*\*/}{} )      { $re .= '(?:.*/)?' }
    elsif ( $s =~ s{\A\*\*\z}{} )     { $re .= '.*' }
    elsif ( $s =~ s{\A\*\*}{} )       { $re .= '.*' }
    elsif ( $s =~ s{\A\*}{} )         { $re .= '[^/]*' }
    elsif ( $s =~ s{\A\?}{} )         { $re .= '[^/]' }
    elsif ( $s =~ s{\A([^*?]+)}{} )   { $re .= quotemeta $1 }
  }
  # "dir/**" also names dir itself; an empty pattern names the base.
  $re =~ s{\\/\.\*\z}{(?:/.*)?};
  my $b = $base eq '/' ? '' : $base;
  return length $rel ? qr{\A\Q$b\E/$re\z}s : qr{\A\Q$b\E\z}s;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Permissions::Rule - Internal permission rule in Claude Code syntax, parsed and matched against tool calls

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $rule = Langertha::Raider::Permissions::Rule->new(
      text   => 'Bash(npm run test:*)',
      source => '.claude/settings.json',
      kind   => 'allow',
    );
    warn $rule->error unless $rule->is_valid;
    my $yes = $rule->matches( { name => 'bash', source => 'engine:2',
      arguments => { command => 'npm run test' } }, $ctx );

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

One permission rule as Claude Code writes it in C<permissions.allow>,
C<ask> or C<deny> (ADR 0021), with the source it came from. The rule is
parsed once on construction; a rule that cannot be parsed, or that names a
tool raider does not know, is kept with an L</error> and never matches --
an invalid rule never widens anything, and C<config explain> shows it.

The forms:

=over

=item C<Tool> -- every call of the tool. Claude Code names go through
L<Langertha::Raider::ToolNames>; raider names (C<write_file>) are accepted
as well. C<Read> stands for every reading file tool (C<read_file>,
C<list_files>, C<glob>, C<grep>), C<Edit> / C<Write> / C<MultiEdit> for
every writing one (C<write_file>, C<edit_file>, C<multi_edit>).

=item C<Bash(command)> exact, C<Bash(prefix:*)> prefix at a word boundary,
C<Bash(git * --dry-run)> glob (C<*> is any text). The command is split into
its parts at C<&&>, C<||>, C<;>, C<|>, C<&>, newlines and parentheses,
outside quotes, with C<$(...)>, backticks and C<< <(...) >> / C<< >(...) >>
searched as commands of their own. A deny or ask rule matches when any part
matches (also with leading keywords, wrappers such as C<sudo> and
C<VAR=value> assignments taken off). An allow rule covers only a command of
one part that matches as written (or, for an exact rule, the whole command
as written), without substitutions, heredocs or redirections into files; L<Langertha::Raider::Permissions> covers a command
of several parts when every part is covered by some allow rule. A C<Bash>
rule applies to the C<monitor> tool as well (its command runs the same way,
ADR 0031); C<Monitor> and C<Monitor(command)> name the monitor alone.

 C<Read(path)>, C<Edit(path)> -- gitignore-style globs (C<*>, C<**>,
C<?>). C<//abs> is absolute, C<~/x> under the home, C</x>, C<./x> and
C<x/y> under the project root, and a pattern without a slash matches at any
depth under the root. A pattern that matches a directory matches everything
below it. The path of the call is resolved like the file tools resolve it
(relative to the root, C<..> taken out, symbolic links followed) and both
the written and the real form are tested: a deny or ask rule matches when
either does, an allow rule only when both do. For C<glob> and C<grep> the
path is the search root: a rule that names it (or a directory above it)
matches the call; the files below it that a rule names are left out of the
results by the search tools themselves (L<Langertha::Raider::SearchTools/hider>).

=item C<Agent(name)> / C<Task(name)> -- an C<agent> call whose
C<subagent_type> is C<name> (a call without one starts C<general-purpose>,
so it counts as that, ADR 0020); C<Skill(name)> -- a C<skill> call for the
skill C<name>. Exact names.

=item C<WebFetch(domain:example.com)> -- the host of C<url>;
C<domain:*.example.com> matches subdomains.

=item C<mcp__server>, C<mcp__server__*>, C<mcp__server__tool> -- tools of
an MCP server that is not raider's own (the server name comes with the
call context). The tool part is compared with the call's name, or, for a
configured server whose tools are called C<mcp__server__tool> (ADR 0029),
with the part after that prefix.

=back

A rule that names a raider tool by name (not C<mcp__>) applies to a tool of
that name from a foreign MCP server too -- but only as deny or ask: an
allow rule for C<Bash> allows raider's C<bash>, never another server's.

=head2 text

The rule as written. Required.

=head2 source

Where the rule came from (a settings file, C<.raider/config.yml>,
C<session>, ...). Required.

=head2 kind

C<allow>, C<ask> or C<deny>. Required; croaks on anything else.

=head2 is_valid

True when the rule could be parsed and names a known tool.

=head2 error

Why the rule is invalid, or undef.

=head2 family

C<tool>, C<bash>, C<path>, C<domain>, C<named> or C<mcp>; undef for an invalid rule.

=head2 tools

The raider tools the rule applies to (a new array ref; empty for an MCP rule
or an invalid one).

=head2 specifier

The text inside the parentheses, or undef for a bare tool rule.

=head2 mcp_server

=head2 mcp_tool

For an MCP rule: the server name, and the tool name (undef: every tool of
the server).

=head2 as_hash

C<< { rule, source, kind, error? } >> for reports.

=head2 matches

    my $yes = $rule->matches( $call, $ctx );

True when the rule applies to the canonical call
C<< { name, source, arguments } >> (see C<_tool_gate> in
L<Langertha::Raider>). C<$ctx> is the context of the call, built by
L<Langertha::Raider::Permissions>: C<roots> and C<homes> (the project root
and the home, each as written and as real path), C<builtin> (true for a
tool of raider's own) and C<server> (the MCP server of a foreign tool).
An invalid rule never matches.

=head2 covers_command_part

    my $yes = $rule->covers_command_part('npm run test');

For a C<Bash> rule: true when the rule matches one part of a command as
written (see L</shell_parts>). A bare C<Bash> rule covers every part.

=head2 shell_parts

    my $shell = $rule->shell_parts('npm test && git push');
    # { parts => [ 'npm test', 'git push' ], opaque => 0 }

The parts of a shell command, split as described above, and C<opaque>:
true when the command holds a command or process substitution, a heredoc,
a redirection into a file (not C</dev/null>, not C<< >&2 >>) or unbalanced
quotes -- a command no allow rule with a specifier covers. Callable on the
class.

=head2 call_paths

    my @paths = $rule->call_paths( 'lib/../secrets/key', $ctx );

The absolute forms of a path argument a rule is held against: resolved
against the project root with C<.> and C<..> taken out, and its real path
(symbolic links of its nearest existing ancestor followed) when that
differs. Callable on the class.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Permissions>

=item * L<Langertha::Raider::ToolNames>

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
