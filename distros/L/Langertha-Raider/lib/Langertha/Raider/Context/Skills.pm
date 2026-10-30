package Langertha::Raider::Context::Skills;
# ABSTRACT: Internal catalogue of the skills raider lists and loads on demand
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Path::Tiny;
use Langertha::Raider::Context::Frontmatter;


has roots => (
  is       => 'ro',
  isa      => 'ArrayRef[HashRef]',
  required => 1,
);


has plugins => (
  is      => 'ro',
  isa     => 'ArrayRef[HashRef]',
  default => sub { [] },
);


has base => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);

has activated => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

# The longest fallback description taken from a body line.
sub description_limit { 250 }

has _catalog => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build__catalog {
  my ( $self ) = @_;
  my %cat = ( skills => [], shadowed => [], problems => [], by_name => {}, body => {}, base => {} );

  $self->_scan_root(\%cat, $_) for @{ $self->roots };

  for my $plugin (@{ $self->plugins }) {
    my %common = (
      source => 'plugin '.$plugin->{name},
      base   => $self->base,
      ( defined $plugin->{root} ? ( plugin_root => path($plugin->{root})->absolute->stringify ) : () ),
    );
    for my $d (@{ $plugin->{dirs} // [] }) {
      my $sd = path($d)->absolute;
      next unless -f $sd->child('SKILL.md');
      $self->_add(\%cat, %common, name => $plugin->{name}.':'.$sd->basename,
        file => $sd->child('SKILL.md'), dir => $sd, kind => 'skill');
    }
    for my $c (@{ $plugin->{commands} // [] }) {
      my $p = path($c)->absolute;
      my @found = -d $p ? $self->_commands_in($p)
        : -f $p && $p->basename =~ /\.md\z/ ? ( [ $p->basename(qr/\.md\z/), $p ] )
        : ();
      $self->_add(\%cat, %common, name => $plugin->{name}.':'.$_->[0],
        file => $_->[1], dir => $_->[1]->parent, kind => 'command') for @found;
    }
  }
  return \%cat;
}

sub _scan_root {
  my ( $self, $cat, $root ) = @_;
  my %common = ( source => $root->{source}, base => $root->{base} // $self->base );
  if (($root->{layout} // '') eq 'file') {
    my $file = path($root->{file})->absolute;
    if (-f $file) {
      $self->_add($cat, %common, name => $file->basename(qr/\.md\z/), file => $file,
        dir => $file->parent, kind => 'skill');
    }
    else {
      push @{ $cat->{problems} }, { file => $file->stringify, reason => 'skill file not found' };
    }
    return;
  }
  my $dir = $root->{dir};
  return unless defined $dir && -d $dir;
  my $base = path($dir)->absolute;
  my $layout = $root->{layout} // 'skills';
  if ($layout eq 'commands') {
    $self->_add($cat, %common, name => $_->[0], file => $_->[1], dir => $_->[1]->parent,
      kind => 'command') for $self->_commands_in($base);
    return;
  }
  my @found;
  if ($layout eq 'flat') {
    @found = map { [ $_->basename(qr/\.md\z/), $_, $base ] }
      grep { -f $_ } $base->children(qr/\.md\z/);
  }
  else {
    @found = map { [ $_->basename, $_->child('SKILL.md'), $_ ] }
      grep { -d $_ && -f $_->child('SKILL.md') } $base->children;
  }
  $self->_add($cat, %common, name => $_->[0], file => $_->[1], dir => $_->[2], kind => 'skill')
    for sort { $a->[0] cmp $b->[0] } @found;
  return;
}

# The command files below $dir, each [ name, file ], sorted by name: every
# *.md at any depth (hidden entries skipped, each real directory once),
# named by its path below $dir without .md, directories joined with ':'.
sub _commands_in {
  my ( $self, $dir ) = @_;
  return sort { $a->[0] cmp $b->[0] } $self->_walk_commands($dir, {});
}

sub _walk_commands {
  my ( $self, $dir, $seen, @prefix ) = @_;
  my $real = eval { $dir->realpath->stringify } // $dir->stringify;
  return if $seen->{$real}++;
  my @found;
  for my $child (grep { $_->basename !~ /\A\./ } eval { $dir->children }) {
    if (-d $child) {
      push @found, $self->_walk_commands($child, $seen, @prefix, $child->basename);
    }
    elsif (-f $child && $child->basename =~ /\.md\z/) {
      push @found, [ join(':', @prefix, $child->basename(qr/\.md\z/)), $child ];
    }
  }
  return @found;
}

# One entry into the catalogue: name, file, dir (Path::Tiny), kind, source,
# base and plugin_root. The first of a name wins -- but a skill beats a
# command of its name whatever came first; the command is then shadowed.
sub _add {
  my ( $self, $cat, %e ) = @_;
  my ( $name, $file, $kind ) = @e{qw( name file kind )};
  my $loser = $cat->{by_name}{$name};
  if ($loser && !( $kind eq 'skill' && $loser->{kind} eq 'command' )) {
    push @{ $cat->{shadowed} }, {
      name   => $name,
      source => $e{source},
      file   => $file->stringify,
      by     => $loser->{source},
    };
    return;
  }
  my $text = eval { $file->slurp_utf8 };
  unless (defined $text) {
    push @{ $cat->{problems} }, { file => $file->stringify, reason => 'unreadable' };
    return;
  }
  if ($loser) {
    @{ $cat->{skills} } = grep { $_ != $loser } @{ $cat->{skills} };
    delete $cat->{$_}{$name} for qw( by_name body base );
    push @{ $cat->{shadowed} }, {
      name   => $name,
      source => $loser->{source},
      file   => $loser->{file},
      by     => $e{source},
    };
  }
  my ( $fm, $body ) = $self->_split($text, $file, $cat->{problems});
  my $skill = {
    name            => $name,
    kind            => $kind,
    description     => $self->_description($fm, $body),
    dir             => $e{dir}->stringify,
    file            => $file->stringify,
    source          => $e{source},
    frontmatter     => $fm,
    model_invocable => $self->_is_true($fm->{'disable-model-invocation'}) ? 0 : 1,
    user_invocable  => $self->_is_false($fm->{'user-invocable'}) ? 0 : 1,
    ( defined $e{plugin_root} ? ( plugin_root => $e{plugin_root} ) : () ),
  };
  push @{ $cat->{skills} }, $skill;
  $cat->{by_name}{$name} = $skill;
  $cat->{body}{$name} = $body;
  $cat->{base}{$name} = $e{base} if defined $e{base};
  return;
}

# ( frontmatter hashref, body ) of a skill file, through the shared lenient
# reader; a broken frontmatter is a problem and leaves the frontmatter empty.
sub _split {
  my ( $self, $text, $file, $problems ) = @_;
  my ( $fm, $body, $problem ) = $self->frontmatter_class->parse($text, booleans => [ $self->boolean_keys ]);
  push @$problems, { file => $file->stringify, reason => $problem } if defined $problem;
  return ( $fm, $body );
}

sub frontmatter_class { 'Langertha::Raider::Context::Frontmatter' }

# The frontmatter keys whose true / false the line reader reads as booleans.
sub boolean_keys { qw( disable-model-invocation user-invocable ) }

sub _description {
  my ( $self, $fm, $body ) = @_;
  my $desc = $fm->{description};
  if (defined $desc && !ref $desc && $desc =~ /\S/) {
    $desc =~ s/\s+/ /g;
    $desc =~ s/\A | \z//g;
    return $desc;
  }
  for my $line (split /\r?\n/, $body) {
    next unless $line =~ /\S/;
    next if $line =~ /\A\s*#/;
    $line =~ s/\A\s+|\s+\z//g;
    my $limit = $self->description_limit;
    $line = substr($line, 0, $limit - 3).'...' if length $line > $limit;
    return $line;
  }
  return '';
}

# Frontmatter booleans: a boolean object, Perl's own (YAML::PP reads true as
# 1 and false as ''), or the words a schema leaves as strings --
# true/yes/on/1 and false/no/off/0, any case. Unset or anything else is
# neither.
sub _is_true {
  my ( $self, $v ) = @_;
  return 0 unless defined $v;
  return $v ? 1 : 0 if ref $v;
  return $v =~ /\A(?:true|yes|on|1)\z/i ? 1 : 0;
}

sub _is_false {
  my ( $self, $v ) = @_;
  return 0 unless defined $v;
  return $v ? 0 : 1 if ref $v;
  return $v =~ /\A(?:false|no|off|0|)\z/i ? 1 : 0;
}


sub skills   { @{ $_[0]->_catalog->{skills} } }
sub shadowed { @{ $_[0]->_catalog->{shadowed} } }
sub problems { @{ $_[0]->_catalog->{problems} } }


sub find {
  my ( $self, $name ) = @_;
  return unless defined $name;
  $name =~ s{\A/}{};
  return $self->_catalog->{by_name}{$name};
}


sub find_user_invocable {
  my ( $self, $name ) = @_;
  my $entry = $self->find($name) or return;
  return $entry->{user_invocable} ? $entry : undef;
}

sub user_invocable { grep { $_->{user_invocable} } $_[0]->skills }


sub is_listed {
  my ( $self, $skill ) = @_;
  return 0 unless $skill->{model_invocable};
  return 1 unless $self->paths_of($skill);
  return $self->activated->{ $skill->{name} } ? 1 : 0;
}

sub listed    { my ( $self ) = @_; grep { $self->is_listed($_) } $self->skills }
sub invocable { grep { $_->{model_invocable} } $_[0]->skills }

sub paths_of {
  my ( $self, $skill ) = @_;
  my $p = $skill->{frontmatter}{paths};
  return unless defined $p;
  my @globs = ref $p eq 'ARRAY' ? @$p : ref $p ? () : split /\s*,\s*(?![^{]*\})/, $p;
  return grep { defined && !ref && length } map { my $g = $_; $g =~ s/\A\s*["']?|["']?\s*\z//g if defined $g && !ref $g; $g } @globs;
}


sub add_roots {
  my ( $self, @roots ) = @_;
  my $cat = $self->_catalog;
  my %had = map { ( "$_" => 1 ) } @{ $cat->{skills} };
  push @{ $self->roots }, @roots;
  $self->_scan_root($cat, $_) for @roots;
  return grep { !$had{"$_"} } @{ $cat->{skills} };
}

sub activate_for {
  my ( $self, $target ) = @_;
  return unless defined $target && length $target;
  my $cat = $self->_catalog;
  my @new;
  for my $skill ($self->invocable) {
    next if $self->activated->{ $skill->{name} };
    my @globs = $self->paths_of($skill) or next;
    my $base = $cat->{base}{ $skill->{name} } // next;
    my ( $b, $t ) = ( path($base), path($target) );
    next unless $b->subsumes($t);
    my $rel = $t->relative($b)->stringify;
    next unless grep { $rel =~ $self->_glob_re($_) } @globs;
    $self->activated->{ $skill->{name} } = 1;
    push @new, $skill;
  }
  return @new;
}

# A glob as an anchored regex (see paths_of).
sub _glob_re {
  my ( $self, $glob ) = @_;
  $glob =~ s{\A\./}{};
  $glob =~ s{\A/}{};
  my $re = $self->_glob_part($glob);
  return $glob =~ m{/} ? qr{\A$re\z} : qr{\A(?:.*/)?$re\z};
}

sub _glob_part {
  my ( $self, $glob ) = @_;
  my $re = '';
  while ($glob =~ m{\G(\*\*/|\*\*|\*|\?|\{[^{}]*\}|.)}gcs) {
    my $t = $1;
    $re .= $t eq '**/' ? '(?:.*/)?'
      : $t eq '**'     ? '.*'
      : $t eq '*'      ? '[^/]*'
      : $t eq '?'      ? '[^/]'
      : $t =~ /\A\{(.*)\}\z/s ? '(?:'.join('|', map { $self->_glob_part($_) } split /,/, $1, -1).')'
      :                  quotemeta $t;
  }
  return $re;
}


sub body {
  my ( $self, $name ) = @_;
  my $skill = $self->find($name) or return;
  return $self->_catalog->{body}{ $skill->{name} };
}


sub tool_text {
  my ( $self, $name, $args ) = @_;
  my $skill = $self->find($name) or return;
  my $body = $self->body($name);
  my $have = defined $args && length $args;
  my $value = $have ? "$args" : '';
  if ($body =~ /\$ARGUMENTS/) {
    $body =~ s/\$ARGUMENTS/$value/g;
  }
  elsif ($have) {
    $body =~ s/\s+\z//;
    $body .= "\n\nARGUMENTS: ".$value;
  }
  return $body if ( $skill->{kind} // '' ) eq 'command';
  return 'Base directory for this skill: '.$skill->{dir}."\n\n".$body;
}


sub prompt_text {
  my ( $self ) = @_;
  my @listed = $self->listed or return;
  return join "\n",
    'Skills: specialised instructions loaded on demand. When a task matches a skill\'s'
      .' description, call the `skill` tool with its name BEFORE acting, then follow what it'
      .' returns. Available skills:',
    map { $self->_entry($_) } @listed;
}


sub announce_text {
  my ( $self, @skills ) = @_;
  return unless @skills;
  return join "\n\n", 'The following skills are available for use with the Skill tool:',
    join "\n", map { $self->_entry($_) } @skills;
}

sub _entry {
  my ( $self, $skill ) = @_;
  return '- '.$skill->{name}.( length $skill->{description} ? ': '.$skill->{description} : '' );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Context::Skills - Internal catalogue of the skills raider lists and loads on demand

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $skills = Langertha::Raider::Context::Skills->new(
      roots => [
        { dir => "$root/.raider/skills", source => '.raider/skills', layout => 'skills' },
        { dir => "$root/my-skills",      source => '--skills my-skills', layout => 'flat' },
      ],
      plugins => [ { name => 'superpowers', dirs => [ @skill_dirs ] } ],
    );
    my $prompt = $skills->prompt_text;            # undef when nothing is listed
    my $text   = $skills->tool_text('pdf', 'report.pdf');

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The skill catalogue of ADR 0019 §4, which holds the custom commands too
(ADR 0030 E<sect>1: commands are skills). It takes roots in precedence
order and the skill directories and command paths of plugins, and knows
every entry's name, description and body. Which roots exist in which
layout mode is the caller's decision; this module only reads what it is
given. A root or skill directory that does not exist is skipped silently.

An entry -- a skill or a command -- is a plain hash ref:

    {
      name            => 'pdf',               # the identifier the model calls, /pdf for the user
      kind            => 'skill',             # or 'command' (a commands root or plugin commands)
      description     => 'Work with PDF files ...',
      dir             => '/abs/skills/pdf',   # base directory; a command's: the directory of its file
      file            => '/abs/skills/pdf/SKILL.md',
      source          => '.claude/skills',    # root label, or 'plugin superpowers'
      frontmatter     => { name => 'pdf', description => '...', ... },   # every key kept
      model_invocable => 1,                   # 0 iff disable-model-invocation is true
      user_invocable  => 1,                   # 0 iff user-invocable is false
      plugin_root     => '/abs/plugin',       # plugin entries only: ${CLAUDE_PLUGIN_ROOT}
    }

=over

=item * B<Name.> In the C<skills> layout the skill directory's name, as
Claude Code uses it as the identifier. A frontmatter C<name> that differs
stays in C<frontmatter> but does not rename the skill. In the C<flat>
layout the file name without F<.md>. In the C<commands> layout the file's
path below the root without F<.md>, directories joined with C<:>
(F<frontend/component.md> is C<frontend:component>). Plugin skills are
C<E<lt>pluginE<gt>:E<lt>dirE<gt>>, plugin commands
C<E<lt>pluginE<gt>:E<lt>nameE<gt>> (C<plugin:sub:name> below a
subdirectory).

=item * B<Booleans.> C<disable-model-invocation> and C<user-invocable>
take C<true> / C<yes> / C<on> / C<1> and C<false> / C<no> / C<off> /
C<0>, in any case. Unset, C<disable-model-invocation> is false and
C<user-invocable> true.

=item * B<Description.> The frontmatter C<description> (whitespace
collapsed), else the first non-empty line of the body that is not a
Markdown heading, trimmed and cut to 250 characters.

=item * B<Frontmatter.> A leading C<---> ... C<---> block, read by
L<Langertha::Raider::Context::Frontmatter>: YAML, else the lenient line
reader for what YAML rejects but Claude Code reads (C<true> / C<false> are
booleans for C<disable-model-invocation> and C<user-invocable>). Only when
that finds no key either, or the YAML is not a mapping, the frontmatter is
empty and L</problems> gets an entry; the skill is still loaded.

=item * B<Precedence.> Roots in the given order, then plugins (each
plugin's skills, then its commands). The first entry of a name wins;
later ones are reported by L</shadowed>. One exception: a skill beats a
command of the same name wherever either came from -- the command is
shadowed (Claude Code). Plugin names carry a C<:>, so they never meet a
root skill (a root command in a subdirectory can).

=back

=head2 roots

Roots, highest precedence first. Required. Each a hash ref:

    { dir => '/abs/dir', source => 'label', layout => 'skills' | 'flat' | 'commands' }

C<skills>: a directory of skill directories, each with a F<SKILL.md>.
C<flat>: a directory of F<*.md> files, each one skill (the old
C<--skills DIR> behaviour); without top-level F<*.md> files it holds no
skills.
C<file>: one skill file (the hash has C<file>; C<dir> is its
parent): named by its file name without F<.md>; a file that is not there
is a L<problem|/problems>.
C<commands>: a directory searched recursively for F<*.md> (hidden entries
skipped), each one command (C<kind> C<command>), named as above.

A root may name its own C<base> (see L</base>).

=head2 plugins

Plugin skill directories and command paths, after all roots. Defaults to
none. Each a hash ref

    {
      name     => 'plugin',
      dirs     => [ '/abs/skill/dir', ... ],              # Plugins->skill_dirs
      commands => [ '/abs/commands', '/abs/x.md', ... ],  # Plugins->command_dirs, optional
      root     => '/abs/plugin',                          # optional, becomes plugin_root
    }

-- the name, L<Langertha::Raider::Context::Plugins/skill_dirs>,
L<Langertha::Raider::Context::Plugins/command_dirs> and root of a plugin.
A command path is a directory, read like a C<commands> root, or one
F<*.md> file, named by its file name.

=head2 base

The directory the C<paths:> globs of a skill are relative to, unless its
root names its own C<base> (the directory with the F<.claude/> or
F<.raider/> the skill lives in). Optional; without it a skill with
C<paths:> can never be activated.

=head2 activated

HashRef of the names of skills with C<paths:> that a touched file has
activated (L</activate_for>). Shared with the caller, who keeps it across
catalogues -- a C</reload> builds a new one.

=head2 skills

    for my $s ($skills->skills) { say $s->{name}.' ('.$s->{source}.')' }

Every entry (skill or command) that won its name, in precedence order:
roots in the given order, sorted by name inside a root, then the plugins
in the given order. Model- or user-invocable or not. A skill that took
its name from a command stands where the skill was read.

=head2 shadowed

    for my $s ($skills->shadowed) { say $s->{name}.' in '.$s->{source}.' shadowed by '.$s->{by} }

Entries that lost their name to an earlier one, or commands that lost it
to a skill, each C<< { name, source, file, by } >> -- C<by> is the
winner's C<source>.

=head2 problems

    warn $_->{file}.': '.$_->{reason}."\n" for $skills->problems;

Skill files that could not be read (not loaded) or whose frontmatter is
broken (loaded with an empty frontmatter), each C<< { file, reason } >>.

=head2 find

    my $skill = $skills->find('/pdf');   # or 'pdf', 'superpowers:brainstorming'

The skill of exactly that name (a leading C</> is ignored), or C<undef>.
Finds skills that are not model-invocable too.

=head2 find_user_invocable

    my $entry = $skills->find_user_invocable('/frontend:component');

The entry a user runs as C</name>: L</find>, but only an entry with
C<user_invocable>; C<undef> otherwise. Commands and skills alike, also
those that are not model-invocable.

=head2 user_invocable

    for my $e ($skills->user_invocable) { say '/'.$e->{name} }

The L</skills> with C<user_invocable>, in catalogue order.

=head2 listed

    my @offered = $skills->listed;

The L</skills> the model may see and load (L</is_listed>).

=head2 is_listed

    if ($skills->is_listed($skill)) { ... }

True for a skill with C<model_invocable> that has no C<paths:> in its
frontmatter, or whose C<paths:> a touched file matched (L</activate_for>).

=head2 invocable

The L</skills> with C<model_invocable>, listed or not yet: the skills the
model can have now or later.

=head2 paths_of

    my @globs = $skills->paths_of($skill);

The globs of the C<paths:> frontmatter of a skill (Claude Code's
conditional skills): a YAML list, or a string with the globs separated by
commas (not inside C<{a,b}>). None for a skill without. A glob is matched
against the path relative to the skill's base: C<*> within a path segment,
C<**> over any number of segments, C<?> one character, C<{a,b}>
alternatives; a glob without C</> matches the file name in any directory.

=head2 add_roots

    my @new = $skills->add_roots({ dir => ..., source => ..., layout => 'skills', base => ... });

Reads more roots into the catalogue, after everything it holds: a name
that is known keeps its entry (the new one is L</shadowed>) -- unless the
known one is a command and the new one a skill. Returns the entries that
are new. Nested F<.claude/skills> found while working in a
subtree come in this way.

=head2 activate_for

    my @new = $skills->activate_for('/abs/path/to/file');

Marks every skill whose C<paths:> glob matches the path (relative to its
base) as L</activated>, and returns those that were not activated before.

=head2 body

    my $md = $skills->body('pdf');

The skill file's text without the frontmatter and leading blank lines, or
C<undef> for an unknown name.

=head2 tool_text

    my $text = $skills->tool_text('pdf', 'report.pdf');

What the C<skill> tool returns (the shape of Claude Code's Skill tool), or
C<undef> for an unknown name:

    Base directory for this skill: /abs/skills/pdf

    <body>

A command (C<kind> C<command>) has no C<Base directory> line: its text is
the body alone (ADR 0030 E<sect>2).

Every C<$ARGUMENTS> in the body is replaced by C<$args>; without C<$args>
(undefined or empty) by nothing, as Claude Code does. When the body has no
C<$ARGUMENTS> and C<$args> is given, C<ARGUMENTS: $args> is appended after
a blank line.

This is the plain text without a renderer. The application's C<skill> tool
renders through L<Langertha::Raider::SlashCommand> instead
(L<Langertha::Raider::Application/skill_tool_text>, ADR 0030 E<sect>2):
every placeholder and C<!`cmd`>, the same shape.

=head2 prompt_text

    my $block = $skills->prompt_text;

The system-prompt block that lists the L</listed> skills, or C<undef> when
none is listed:

    Skills: specialised instructions loaded on demand. When a task matches a
    skill's description, call the `skill` tool with its name BEFORE acting,
    then follow what it returns. Available skills:
    - pdf: Work with PDF files ...
    - superpowers:brainstorming: ...

(the first paragraph is one line). A skill without description is listed
by its name alone.

=head2 announce_text

    my $text = $skills->announce_text(@new);

The note for skills that became available during the session (a nested
F<.claude/skills> or a C<paths:> match), worded as Claude Code does:

    The following skills are available for use with the Skill tool:

    - name: description

C<undef> for none.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::SkillTools>

=item * L<Langertha::Raider::Context::Plugins>

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
