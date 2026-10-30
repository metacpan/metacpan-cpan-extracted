package Langertha::Raider::SlashCommand;
# ABSTRACT: Internal renderer of a skill or command body for /name and the skill tool
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Cwd qw( realpath );
use Encode ();
use JSON::MaybeXS ();
use List::Util qw( first );
use Path::Tiny;
use POSIX ();
use Text::ParseWords ();
use Time::HiRes ();
use Langertha::Raider::FileTools qw( build_file_tools_server );
use Langertha::Raider::FileTools::ReadState;
use Langertha::Raider::PathConfine;
use Langertha::Raider::Permissions;
use Langertha::Raider::Permissions::Rule;


has root => ( is => 'ro', isa => 'Str', required => 1 );


has permissions => (
  is        => 'ro',
  isa       => 'Langertha::Raider::Permissions',
  predicate => 'has_permissions',
);


has validator => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_validator',
);


has extra_roots => (
  is        => 'ro',
  isa       => 'ArrayRef|CodeRef',
  predicate => 'has_extra_roots',
);


has session_id => ( is => 'ro', isa => 'Maybe[Str]' );


has disable_shell => ( is => 'ro', isa => 'Bool', default => 0 );


has timeout => ( is => 'ro', isa => 'Num', default => 120 );


has kill_grace => ( is => 'ro', isa => 'Num', default => 2 );


has runner => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_runner',
);


sub disabled_text { '[shell command execution disabled by policy]' }


# The first words whose exit 1 means "nothing found" or "differs", not failure.
sub exit_one_commands { qw( grep egrep fgrep rg diff cmp test [ ) }


#### Arguments


sub split_arguments {
  my ( $self, $string ) = @_;
  return unless defined $string && $string =~ /\S/;
  my @words = Text::ParseWords::shellwords($string);
  return @words if @words;
  return split ' ', $string;
}


sub argument_names {
  my ( $self, $entry ) = @_;
  my $v = ref $entry->{frontmatter} eq 'HASH' ? $entry->{frontmatter}{arguments} : undef;
  return unless defined $v;
  my @names = ref $v eq 'ARRAY' ? @$v : ref $v ? () : split ' ', $v;
  return map { defined $_ && !ref $_ && /\A[A-Za-z_][A-Za-z0-9_]*\z/ ? $_ : undef } @names;
}


sub expand_arguments {
  my ( $self, $entry, $body, $string ) = @_;
  $body //= '';
  my $have  = defined $string && length $string;
  my @args  = $have ? $self->split_arguments($string) : ();
  my @names = $self->argument_names($entry);
  my %pos;
  for my $i ( 0 .. $#names ) {
    $pos{ $names[$i] } = $i if defined $names[$i] && !exists $pos{ $names[$i] };
  }
  my $named = %pos
    ? join( '|', map { quotemeta } sort { length $b <=> length $a || $a cmp $b } keys %pos )
    : '(?!)';
  my %var = (
    CLAUDE_SKILL_DIR   => $entry->{dir},
    CLAUDE_PROJECT_DIR => $self->root,
    CLAUDE_SESSION_ID  => $self->session_id // '',
    CLAUDE_PLUGIN_ROOT => $entry->{plugin_root},
  );
  my $used = 0;
  my $expand = sub {
    my ( $m ) = @_;
    return '$' if defined $m->{esc};
    if ( defined $m->{var} ) {
      my $value = $var{ $m->{var} };
      return defined $value ? $value : $m->{all};
    }
    $used = 1;
    return $have ? "$string" : '' if defined $m->{whole};
    if ( defined $m->{index} ) {
      my $i = $m->{index};
      return $i < @args ? $args[$i] : $m->{all};
    }
    my $i = $pos{ $m->{name} };
    return $i < @args ? $args[$i] : '';
  };
  $body =~ s{
    (?<all>
        (?<esc>\\\$)
      | \$\{(?<var>CLAUDE_(?:SKILL_DIR|PROJECT_DIR|SESSION_ID|PLUGIN_ROOT))\}
      | \$ARGUMENTS\[(?<index>\d+)\]
      | (?<whole>\$ARGUMENTS)(?![A-Za-z0-9_\[])
      | \$(?<index>\d+)
      | \$(?<name>$named)(?![A-Za-z0-9_])
    )
  }{ $expand->({ %+ }) }gex;
  return ( $body, $used );
}

#### allowed-tools


sub allowed_tool_rules {
  my ( $self, $from ) = @_;
  my $value = ref $from eq 'HASH'
    ? ( ref $from->{frontmatter} eq 'HASH'
      ? $from->{frontmatter}{'allowed-tools'} // $from->{frontmatter}{allowed_tools}
      : undef )
    : $from;
  return unless defined $value;
  my @items = ref $value eq 'ARRAY' ? @$value : ref $value ? () : ( $value );
  my ( @rules, %seen );
  for my $item ( grep { defined && !ref } @items ) {
    for my $text ( $self->_split_rule_list($item) ) {
      next if $seen{$text}++;
      my $rule = Langertha::Raider::Permissions::Rule->new( text => $text, source => 'allowed-tools', kind => 'allow' );
      push @rules, $text if $rule->is_valid;
    }
  }
  return @rules;
}

sub grant_source { '/'.( $_[1]{name} // '' ).' allowed-tools' }


# A list of rules split at commas and whitespace outside parentheses.
sub _split_rule_list {
  my ( $self, $string ) = @_;
  my @out;
  my ( $cur, $depth ) = ( '', 0 );
  for my $c ( split //, $string ) {
    if    ( $c eq '(' ) { $depth++ }
    elsif ( $c eq ')' ) { $depth-- if $depth }
    elsif ( $depth == 0 && $c =~ /[\s,]/ ) {
      push @out, $cur if length $cur;
      $cur = '';
      next;
    }
    $cur .= $c;
  }
  push @out, $cur if length $cur;
  return @out;
}

#### Permission check


sub check_command {
  my ( $self, $command ) = @_;
  return { verdict => 'deny', by => 'renderer', reason => 'there is no permission policy to check it against' }
    unless $self->has_permissions;
  return $self->permissions->decide({ name => 'bash', source => 'raider', arguments => { command => $command } });
}

#### Running


sub run_command {
  my ( $self, $command ) = @_;
  return $self->runner->( $command, $self->root, $self->timeout ) if $self->has_runner;
  my $file = Path::Tiny->tempfile( TEMPLATE => 'raider-command-XXXXXXXX' );
  open my $out, '>', "$file" or return { error => 'cannot write '.$file.': '.$! };
  my $pid = fork;
  return { error => 'fork: '.$! } unless defined $pid;
  unless ($pid) {
    eval { setpgrp( 0, 0 ) };
    $SIG{$_} = 'DEFAULT' for grep { exists $SIG{$_} } qw( INT TERM HUP QUIT PIPE CHLD ALRM );
    open STDIN,  '<',  '/dev/null';
    open STDOUT, '>&', $out;
    open STDERR, '>&', $out;
    unless ( chdir $self->root ) {
      print STDERR 'raider: cannot change to '.$self->root.': '.$!."\n";
      POSIX::_exit(1);
    }
    { no warnings 'exec'; exec 'bash', '-c', Encode::encode( 'UTF-8', $command ); }
    print STDERR 'raider: cannot run bash: '.$!."\n";
    POSIX::_exit(127);
  }
  close $out;
  my $deadline = Time::HiRes::time() + $self->timeout;
  my $pause = 0.001;
  my $status;
  while (1) {
    my $got = waitpid( $pid, POSIX::WNOHANG() );
    if ( $got == $pid ) { $status = $?; last }
    if ( $got < 0 ) { last }
    if ( Time::HiRes::time() >= $deadline ) {
      $self->_stop_group($pid);
      return { error => 'timed out after '.$self->timeout.' seconds' };
    }
    Time::HiRes::sleep($pause);
    $pause = $pause * 2 > 0.05 ? 0.05 : $pause * 2;
  }
  return { error => 'the command was reaped elsewhere; its exit code is unknown' } unless defined $status;
  my $output = Encode::decode( 'UTF-8', $file->slurp_raw );
  $output =~ s/[\r\n]+\z//;
  return {
    exit_code => ( $status & 127 ) ? 128 + ( $status & 127 ) : $status >> 8,
    output    => $output,
  };
}

# SIGTERM to the process group, SIGKILL after kill_grace; reaps the child.
sub _stop_group {
  my ( $self, $pid ) = @_;
  kill( TERM => -$pid ) || kill( TERM => $pid );
  my $deadline = Time::HiRes::time() + $self->kill_grace;
  while ( Time::HiRes::time() < $deadline ) {
    return if waitpid( $pid, POSIX::WNOHANG() ) != 0;
    Time::HiRes::sleep(0.02);
  }
  kill( KILL => -$pid ) || kill( KILL => $pid );
  waitpid( $pid, 0 );
  return;
}

#### Rendering


sub render {
  my ( $self, %arg ) = @_;
  my $entry = $arg{entry};
  croak __PACKAGE__.'->render needs an entry' unless ref $entry eq 'HASH';
  my $string = $arg{arguments};
  my $have   = defined $string && length $string;
  my %result = (
    arguments  => [ $have ? $self->split_arguments($string) : () ],
    commands   => [],
    files_read => [],
  );

  my ( $text, $used ) = $self->expand_arguments( $entry, $arg{body}, $string );
  if ( $have && !$used ) {
    $text =~ s/\s+\z//;
    $text .= "\n\nARGUMENTS: ".$string;
  }

  my @pieces = $self->_pieces($text);
  if ( my $error = $self->_run_pieces( $entry, \@pieces, $result{commands} ) ) {
    return { %result, error => $error };
  }

  my @attach = $arg{attach_files} ? $self->_attachments( \@pieces, $result{files_read} ) : ();
  $text = join '', map { $_->{type} eq 'text' ? $_->{text} : $_->{output} } @pieces;
  $text = 'Base directory for this skill: '.$entry->{dir}."\n\n".$text
    unless ( $entry->{kind} // 'skill' ) eq 'command';
  $text =~ s/\s+\z// if @attach;
  $text .= "\n\n".join( "\n", @attach ) if @attach;
  return { %result, text => $text };
}

# The text cut into pieces: { type => 'text', text } and
# { type => 'command', command, pattern }, in order.
sub _pieces {
  my ( $self, $text ) = @_;
  my @pieces;
  my $inline = sub {
    my ( $chunk ) = @_;
    my $at = 0;
    while ( $chunk =~ /(?<!\S)(!`([^`\n]+)`)/g ) {
      my ( $start, $end ) = ( $-[1], $+[1] );
      push @pieces, { type => 'text', text => substr( $chunk, $at, $start - $at ) } if $start > $at;
      push @pieces, { type => 'command', command => $2, pattern => $1 };
      $at = $end;
    }
    push @pieces, { type => 'text', text => substr( $chunk, $at ) } if $at < length $chunk;
  };
  my $at = 0;
  while ( $text =~ /^(```!\h*\n(.*?)^```\h*)$/gms ) {
    my ( $start, $end, $command, $pattern ) = ( $-[1], $+[1], $2, $1 );
    $inline->( substr( $text, $at, $start - $at ) ) if $start > $at;
    $command =~ s/\n\z//;
    push @pieces, { type => 'command', command => $command, pattern => $pattern };
    $at = $end;
  }
  $inline->( substr( $text, $at ) ) if $at < length $text;
  return @pieces;
}

# Checks every command, then runs them; fills their output. Returns the
# reason of an abort, or nothing.
sub _run_pieces {
  my ( $self, $entry, $pieces, $trace ) = @_;
  my @commands = grep { $_->{type} eq 'command' } @$pieces or return;
  if ( $self->disable_shell ) {
    for my $c (@commands) {
      $c->{output} = $self->disabled_text;
      push @$trace, { command => $c->{command}, verdict => 'disabled' };
    }
    return;
  }
  my $name = $entry->{name} // '';
  # The entry's allowed-tools hold while its commands are checked; what was
  # not there before is taken out again (the caller grants them for a run).
  my @granted = $self->has_permissions
    ? $self->permissions->add_run_rules( [ $self->allowed_tool_rules($entry) ], $self->grant_source($entry) )
    : ();
  my @checked;
  for my $c (@commands) {
    my $verdict = $self->check_command( $c->{command} );
    push @checked, { command => $c->{command}, verdict => $verdict->{verdict}, reason => $verdict->{reason} };
    next if $verdict->{verdict} eq 'allow';
    $self->permissions->clear_run_rules(@granted) if @granted;
    push @$trace, @checked;
    return 'Shell command permission check failed for pattern "'.$c->{pattern}.'" in /'.$name.': '
      .( $verdict->{reason} // $verdict->{verdict} );
  }
  $self->permissions->clear_run_rules(@granted) if @granted;
  for my $i ( 0 .. $#commands ) {
    my ( $c, $t ) = ( $commands[$i], $checked[$i] );
    delete $t->{reason};
    push @$trace, $t;
    if ( $self->has_validator ) {
      my $ok = $self->validator->( $c->{command}, $self->root );
      unless ( defined $ok && !ref $ok && $ok eq '1' ) {
        @$t{qw( verdict reason )} = ( 'refused', $ok );
        return 'Shell command refused for pattern "'.$c->{pattern}.'" in /'.$name.': Command '
          .( defined $ok && length $ok ? $ok : 'denied' );
      }
    }
    my $ran = $self->run_command( $c->{command} );
    if ( defined $ran->{error} ) {
      $t->{reason} = $ran->{error};
      return 'Shell command failed for pattern "'.$c->{pattern}.'" in /'.$name.': '.$ran->{error};
    }
    my $code   = $ran->{exit_code} // 0;
    my $output = $ran->{output} // '';
    $t->{exit_code} = $code;
    if ( $code != 0 && !( $code == 1 && $self->_exit_one_ok( $c->{command} ) ) ) {
      return 'Shell command failed for pattern "'.$c->{pattern}.'" in /'.$name.': exit code '.$code
        .( length $output ? "\n".$output : '' );
    }
    $c->{output} = $output;
  }
  return;
}

sub _exit_one_ok {
  my ( $self, $command ) = @_;
  my ( $first ) = $command =~ /\A\s*(\S+)/ or return 0;
  $first =~ s{.*/}{};
  return ( first { $_ eq $first } $self->exit_one_commands ) ? 1 : 0;
}

#### File references

# The attachment texts for the @path references in the text pieces; fills
# $read with what was read.
sub _attachments {
  my ( $self, $pieces, $read ) = @_;
  my $real_root = realpath( $self->root ) // return;
  my $extra = $self->has_extra_roots ? $self->extra_roots
    : $self->has_permissions ? [ $self->permissions->additional_directory_paths ] : [];
  my $confine = Langertha::Raider::PathConfine->new( root => $real_root, extra_roots => $extra );
  my ( @out, %seen );
  my $tools;
  for my $piece ( grep { $_->{type} eq 'text' } @$pieces ) {
    while ( $piece->{text} =~ /(?<!\S)@(?:"([^"\n]+)"|(\S+))/g ) {
      my $real = $self->_reference( defined $1 ? $1 : $2, $real_root, $confine ) // next;
      next if $seen{$real}++;
      $tools //= $self->_file_tools( $real_root, $extra );
      my $dir  = -d $real ? 1 : 0;
      my $tool = $dir ? 'list_files' : 'read_file';
      my $res  = $tools->{$tool}->code->( $tools->{$tool}, { path => $real } );
      next unless ref $res eq 'HASH' && !$res->{isError};
      my @content = ref $res->{content} eq 'ARRAY' ? @{ $res->{content} } : ();
      next if !@content || grep { ( $_->{type} // '' ) ne 'text' } @content;
      my $body = join "\n", map { $_->{text} // '' } @content;
      push @out, join "\n",
        '<system-reminder>',
        'Called the '.$tool.' tool with the following input: '
          .JSON::MaybeXS->new( canonical => 1 )->encode({ path => $real }),
        '</system-reminder>',
        '<system-reminder>',
        'Result of calling the '.$tool.' tool:',
        $body,
        '</system-reminder>';
      push @$read, $dir ? { path => $real, kind => 'directory' }
        : $body =~ /\[Truncated: PARTIAL view/ ? { path => $real, kind => 'file', partial => 1 }
        : { path => $real, kind => 'file', bytes => scalar path($real)->slurp_raw };
    }
  }
  return @out;
}

# The real path a reference names when it exists inside the allowed roots
# and no read rule hides it, or undef. Sentence punctuation at the end is
# tried off too.
sub _reference {
  my ( $self, $ref, $real_root, $confine ) = @_;
  for my $try ( $ref, ( $ref =~ /\A(.+?)[.,;:!?)]+\z/ ? $1 : () ) ) {
    my $p = path($try);
    $p = path($real_root)->child($try) unless $p->is_absolute;
    next unless -e $p;
    my $real = realpath("$p") // next;
    return unless $confine->allows($real);
    return if $self->has_permissions && $self->permissions->hides_read($real);
    return $real;
  }
  return;
}

# read_file and list_files of a file tools server over the root, confined
# to the allowed roots, without images, with a read state of its own.
sub _file_tools {
  my ( $self, $real_root, $extra ) = @_;
  my $server = build_file_tools_server(
    root        => $real_root,
    extra_roots => $extra,
    confine     => 1,
    sees_images => 0,
    read_state  => Langertha::Raider::FileTools::ReadState->new,
  );
  return { map { $_->name => $_ } grep { $_->name eq 'read_file' || $_->name eq 'list_files' } @{ $server->tools } };
}


sub record_reads {
  my ( $self, $result, $state ) = @_;
  for my $f ( @{ $result->{files_read} // [] } ) {
    next unless ( $f->{kind} // '' ) eq 'file';
    $state->record( $f->{path}, $f->{partial} ? ( partial => 1 ) : ( bytes => $f->{bytes} ) );
  }
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::SlashCommand - Internal renderer of a skill or command body for /name and the skill tool

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $renderer = Langertha::Raider::SlashCommand->new(
      root          => $app->root,
      permissions   => $app->permissions,
      validator     => $app->loadguard->validator,
      session_id    => $session ? $session->id : undef,
      disable_shell => $settings_say_disableSkillShellExecution,
    );
    my $r = $renderer->render(
      entry        => $catalog->find('review'),
      body         => $catalog->body('review'),
      arguments    => 'src/App.pm "be strict"',
      attach_files => 1,                       # a /name run, not the skill tool
    );
    if ( defined $r->{error} ) { say $r->{error}; return }
    $renderer->record_reads( $r, $app->file_read_state );   # after begin_run
    send_to_model( $r->{text} );

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

One renderer for the body of a catalogue entry (a skill or a command,
L<Langertha::Raider::Context::Skills>), used by C</name> and by the C<skill>
tool (ADR 0030 §2). L</render> runs three steps, in this order:

=over

=item 1. B<Arguments.> The argument string is split shell-style (quotes
group, a backslash escapes; L<Text::ParseWords>, and on unbalanced quotes at
whitespace). In one pass over the body -- an inserted value is never
expanded again:

    $ARGUMENTS            the whole argument string ('' without arguments)
    $ARGUMENTS[N], $N     the N-th argument, 0-based; stays as typed without one
    $name                 a name from the frontmatter "arguments" (a list, or
                          a space-separated string) for its position; '' without one
    ${CLAUDE_SKILL_DIR}   the entry's dir
    ${CLAUDE_PROJECT_DIR} the root
    ${CLAUDE_SESSION_ID}  the session id ('' without a session)
    ${CLAUDE_PLUGIN_ROOT} the entry's plugin_root (stays as typed for an entry
                          that is not from a plugin)
    \$                    a literal $

With arguments given and no argument placeholder (C<$ARGUMENTS>,
C<$ARGUMENTS[N]>, C<$N>, C<$name>) in the body, C<ARGUMENTS: E<lt>argsE<gt>>
is appended after a blank line. A placeholder whose index has no argument
still counts as used.

=item 2. B<Shell injection.> C<!`cmd`> at the start of a line or after
whitespace, and fenced blocks opened by a line C<```!> and closed by a line
C<```>, are commands. Every command is first held against the permission
policy as raider's C<bash> call (L</permissions>, ADR 0021), with the
entry's C<allowed-tools> (L</allowed_tool_rules>) added as run rules
(L<Langertha::Raider::Permissions/add_run_rules>, source
L</grant_source>) while the commands are checked and taken out again
after -- deny and ask rules still win. A command may run B<only> on C<allow>; C<deny> or C<ask> aborts the whole render with
the reason -- nobody is asked while a command renders. All commands are
checked before the first one runs, so a refusal leaves no side effect. Then
the loadguard gate (L</validator>, ADR 0018) is asked and the command runs
with C<bash -c> in the root (L</run_command>). Its output (standard output
and standard error together, trailing newlines taken off) replaces the
placeholder and is not scanned again -- neither for commands nor for
C<@file>. A non-zero exit aborts, except exit 1 of a search or compare
command (C<grep>, C<egrep>, C<fgrep>, C<rg>, C<diff>, C<cmp>, C<test>,
C<[>); so does a command still running after L</timeout> seconds. With
L</disable_shell> each command is replaced by
C<[shell command execution disabled by policy]> and nothing is checked or
run.

=item 3. B<File references> (only with C<< attach_files => 1 >>, a C</name>
run). Each C<@path> (or C<@"path with spaces">) at the start of a line or
after whitespace, in the text of the body and the arguments -- not in
command output -- that names an existing file or directory inside the root
or an additional directory (L</extra_roots>), and that no deny or ask rule
for reading hides (L<Langertha::Raider::Permissions/hides_read>), is
attached after the text. Punctuation that ends a sentence (C<.,;:!?)>) is
not part of the path when the path without it exists. A file is read the
way C<read_file> returns it (L<Langertha::Raider::FileTools>, the same
limits and texts; images and PDFs are not attached, as the result is text),
a directory is listed the way C<list_files> lists it. A reference that
names nothing, lies outside, or that the tool refuses stays plain text. Each
attachment is shaped after Claude Code's, with raider's tool names:

    <system-reminder>
    Called the read_file tool with the following input: {"path":"/abs/real/path"}
    </system-reminder>
    <system-reminder>
    Result of calling the read_file tool:
    1	first line
    ...
    </system-reminder>

The files attached count as read for read-before-write (ADR 0023):
L</record_reads> puts them into a run's
L<Langertha::Raider::FileTools::ReadState>.

=back

A skill's text (C<kind> not C<command>) starts with
C<Base directory for this skill: DIR> and a blank line, as the C<skill>
tool has always answered (ADR 0026); a command's text has no such line.

=head2 root

The project root. Required. Commands run in it, C<@path> is relative to
it, C<${CLAUDE_PROJECT_DIR}> is it.

=head2 permissions

The permission policy of the session (L<Langertha::Raider::Permissions>).
Without it no shell command passes: a body with one aborts. Its deny and
ask rules for reading also hide files from C<@path>.

=head2 validator

Optional. The loadguard gate as the C<bash> tool gets it
(L<Langertha::Raider::Loadguard/validator>): called as
C<< $validator->($command, $root) >>; C<1> lets the command run, anything
else aborts with C<Command REASON>.

=head2 extra_roots

The directories besides the root that C<@path> may reach: an ArrayRef, or
a CodeRef returning the list, asked on every render. Defaults to the
additional directories of L</permissions>.

=head2 session_id

The session's id for C<${CLAUDE_SESSION_ID}>; C<''> without one.

=head2 disable_shell

True (the Claude Code setting C<disableSkillShellExecution>): no command
runs, each is replaced by L</disabled_text>.

=head2 timeout

Seconds a command may run before the render aborts: 120, the C<bash>
tool's default.

=head2 kill_grace

Seconds between C<SIGTERM> and C<SIGKILL> to the process group of a
command that timed out.

=head2 runner

Optional. Replaces how a command is run (tests): called as
C<< $runner->($command, $root, $timeout) >>, it returns what
L</run_command> returns. The permission check and the loadguard gate still
come first.

=head2 disabled_text

C<[shell command execution disabled by policy]>, what a command becomes
with L</disable_shell>.

=head2 exit_one_commands

C<grep egrep fgrep rg diff cmp test [>: the commands whose exit 1 does not
abort the render.

=head2 split_arguments

    my @args = $renderer->split_arguments('a "b c" d\ e');   # a, b c, d e

The argument string split shell-style: quotes group, a backslash escapes.
With unbalanced quotes it is split at whitespace instead.

=head2 argument_names

    my @names = $renderer->argument_names($entry);

The names of the frontmatter C<arguments> (a list, or a space-separated
string), in position order. Names that are not identifiers are left out --
their position still counts.

=head2 expand_arguments

    my ( $text, $used ) = $renderer->expand_arguments( $entry, $body, $args );

Step 1 alone: the body with every placeholder replaced (see
L</DESCRIPTION>), and whether an argument placeholder was in it. Does not
append C<ARGUMENTS:>; L</render> does.

=head2 allowed_tool_rules

    my @rules = $renderer->allowed_tool_rules($entry);
    # 'Bash(git status:*)', 'Read', 'mcp__github'

The entry's frontmatter C<allowed-tools> (also C<allowed_tools>) as
permission rule texts in the syntax of ADR 0021 -- Claude Code's, which
L<Langertha::Raider::Permissions::Rule> reads, translating Claude Code tool
names through L<Langertha::Raider::ToolNames>. The value is a string with
the rules separated by commas or whitespace outside parentheses, or a YAML
list of such strings. A text that is not a valid rule is left out, as an
invalid rule never widens anything. Called with a plain value instead of an
entry, it parses that value.

=head2 grant_source

    my $source = $renderer->grant_source($entry);   # '/review allowed-tools'

The source the entry's C<allowed-tools> carry as run rules
(L<Langertha::Raider::Permissions/add_run_rules>).

=head2 check_command

    my $verdict = $renderer->check_command('git status');

The verdict of the policy (L<Langertha::Raider::Permissions/decide>) on
raider's C<bash> call with the command, as it stands -- with the run rules
it holds (L<Langertha::Raider::Permissions/run_rules>). Without
L</permissions> the verdict is C<deny>. L</render> adds the entry's
C<allowed-tools> as run rules while it checks.

=head2 run_command

    my $ran = $renderer->run_command('git status --short');
    # { exit_code => 0, output => "M lib/App.pm" }   or   { error => 'timed out after 120 seconds' }

Runs the command with C<bash -c> in the root, in a process group of its
own, standard input from F</dev/null>, standard output and standard error
into one file; returns its exit code and output (decoded as UTF-8,
trailing newlines taken off), or C<error> when it could not start or ran
longer than L</timeout> seconds (its process group is stopped then). With
L</runner> the runner does it.

=head2 render

    my $r = $renderer->render(
      entry        => $entry,     # a catalogue hash: name, dir, file, source, frontmatter, kind, plugin_root
      body         => $body,      # its text without frontmatter
      arguments    => $string,    # optional
      attach_files => 1,          # optional: step 3, for a /name run
    );

Renders the body (see L</DESCRIPTION>). Returns a hash:

    {
      text       => '...',        # on success -- what goes to the model
      error      => '...',        # instead of text when the render aborts
      arguments  => [ ... ],      # the split arguments
      commands   => [ { command, verdict, exit_code?, reason? }, ... ],
      files_read => [ { path => '/real/path', kind => 'file' | 'directory',
                        bytes => $raw | partial => 1 }, ... ],
    }

C<commands> lists every command found, in order, with its C<verdict>
(C<allow>, C<deny>, C<ask>, C<disabled>, C<refused> by the loadguard gate),
for tracing; C<files_read> the attachments (L</record_reads>). An abort
sends nothing to the model; its C<error> names the command and the reason.
Croaks without C<entry>.

=head2 record_reads

    $renderer->record_reads( $result, $app->file_read_state );

Records the files of C<files_read> in the read state of a run
(L<Langertha::Raider::FileTools::ReadState>): a file attached whole with
its bytes, a part of one as partial. Directories are not recorded. Call it
once the run has begun -- L<Langertha::Raider::Application/begin_run>
empties the read state.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Context::Skills>

=item * L<Langertha::Raider::Permissions>

=item * L<Langertha::Raider::FileTools>

=item * L<Langertha::Raider::Loadguard>

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
