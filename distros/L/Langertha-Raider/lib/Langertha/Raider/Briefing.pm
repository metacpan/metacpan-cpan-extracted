package Langertha::Raider::Briefing;
# ABSTRACT: Internal briefing of a subagent: its declared skills in front of its task
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use utf8;
use Encode ();
use Path::Tiny;


has agent => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has skills => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
);

has resolver => (
  is       => 'ro',
  required => 1,
);


has _resolved => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build__resolved',
);

sub missing { @{ $_[0]->_resolved->{missing} } }
sub missing_reason { $_[0]->_resolved->{reasons}{ $_[1] } }
sub blocks  { @{ $_[0]->_resolved->{blocks} } }
sub text    { $_[0]->_resolved->{text} }
sub size    { $_[0]->_resolved->{size} }

sub has_missing { scalar( () = $_[0]->missing ) ? 1 : 0 }

sub _build__resolved {
  my ( $self ) = @_;
  my ( @missing, %reasons, @blocks, @texts );
  my $resolver = $self->resolver;
  for my $name (@{ $self->skills }) {
    my $skill = $resolver->resolve($name);
    unless ($skill) {
      push @missing, $name;
      my $why = $resolver->can('why_unresolved') ? $resolver->why_unresolved($name) : undef;
      $reasons{$name} = $why if defined $why && length $why;
      next;
    }
    my $file = path($skill->{file});
    my $dir  = defined $skill->{dir} ? $skill->{dir} : $file->absolute->parent->stringify;
    my $text = eval { $file->slurp_utf8 } // '';
    my $body = $self->strip( $self->split_frontmatter($text) );
    push @blocks, { name => $name, dir => $dir, file => $file->stringify };
    push @texts, '<skill name="'.$name.'" dir="'.$dir.'">'."\n".$body."\n".'</skill>';
  }
  my $text = join "\n\n", @texts;
  return {
    missing => \@missing,
    reasons => \%reasons,
    blocks  => \@blocks,
    text    => $text,
    size    => length Encode::encode('UTF-8', $text),
  };
}


sub split_frontmatter {
  my ( $self, $text ) = @_;
  return $text =~ /\A---\r?\n(.*?)\r?\n---\r?\n(.*)\z/s ? $2 : $text;
}

sub strip {
  my ( $self, $text ) = @_;
  $text =~ s/\A[\s\x1c-\x1f]+//;
  $text =~ s/[\s\x1c-\x1f]+\z//;
  return $text;
}


sub budget_bytes { 64 * 1024 }

sub oversized { $_[0]->size > $_[0]->budget_bytes ? 1 : 0 }


sub header {
  return "# Briefing — pre-loaded skills\n\n"
    ."The skills below have been injected directly into your context by the\n"
    ."briefing plugin, one <skill> element each. Treat them as already loaded —\n"
    ."do NOT call the Skill tool for any of these names; their content is already here. Only the SKILL.md body is\n"
    ."included: paths a skill mentions (references/, scripts/, …) are relative to\n"
    ."its element's dir, so read them from there when you need them.\n\n";
}


sub prompt {
  my ( $self, $task ) = @_;
  $task //= '';
  return $task unless @{ $self->skills };
  return $self->header.$self->text."\n\n---\n\n# Original task\n\n".$task;
}


sub missing_note {
  my ( $self ) = @_;
  return 'briefing: agent \''.$self->agent.'\' references unknown skill(s): '.join( ', ',
    map { my $why = $self->missing_reason($_); defined $why ? $_.' ('.$why.')' : $_ } $self->missing );
}

sub size_note {
  my ( $self ) = @_;
  return 'briefing: agent \''.$self->agent.'\' is briefed with '.int( $self->size / 1024 ).' kB '
    .'of skill text (over '.int( $self->budget_bytes / 1024 ).' kB) — consider declaring '
    .'fewer or smaller skills.';
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Briefing - Internal briefing of a subagent: its declared skills in front of its task

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $b = Langertha::Raider::Briefing->new(
      agent    => 'raider-worker',
      skills   => [ 'getty-perl-core', 'perl-mcp' ],
      resolver => $context->skill_resolver,
    );
    return ( $b->missing_note, 1 ) if $b->has_missing;   # no spawn
    warn $b->size_note if $b->oversized;                 # spawn anyway
    my $prompt = $b->prompt($task);

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

ADR 0020 E<sect>6: the skills an agent declares are put in front of its
task in the format of the briefing plugin (F<hooks/briefing-preload>,
C<main_claude>), so an agent reads the same under Claude Code with that
plugin and under raider:

    BRIEFING_HEADER                    (the plugin's text, word for word)
    <skill name="NAME" dir="/abs/dir">
    BODY
    </skill>                           (one block per skill, "\n\n" between)

    ---

    # Original task

    TASK

C<NAME> is the name as declared, C<dir> the directory of the resolved
F<SKILL.md>, C<BODY> the file without its frontmatter (the plugin's
C<split_frontmatter>) and stripped of leading and trailing whitespace.

Every name goes through L</resolver>. A name that does not resolve is
listed in L</missing>; the caller then starts nothing (the plugin's
hard-fail policy, never a partial briefing). Above L</budget_bytes> of
skill text the briefing is L</oversized>: the spawn goes ahead with
L</size_note>.

=head2 agent

The agent's name, for the notes. Required.

=head2 skills

The declared skill names, in order (L<Langertha::Raider::Context::Agents>
puts Claude Code's C<skills> before C<briefing.skills>, each once).
Defaults to none.

=head2 resolver

The L<Langertha::Raider::SkillResolver> (anything with C<resolve($name)>
returning C<< { name, dir, file } >> or nothing). Required.

=head2 missing

The declared names that did not resolve, in order.

=head2 has_missing

True when L</missing> lists a name: the spawn is refused.

=head2 missing_reason

    my $why = $b->missing_reason('tpl');   # 'skilletor: ...' or undef

Why a name of L</missing> did not resolve, when the resolver says
(C<why_unresolved>, L<Langertha::Raider::SkillResolver/why_unresolved>).

=head2 blocks

One C<< { name, dir, file } >> per resolved skill, in order.

=head2 text

The C<< <skill> >> blocks joined by a blank line; empty without skills.

=head2 size

The length of L</text> in UTF-8 bytes.

=head2 split_frontmatter

    my $body = $briefing->split_frontmatter($text);

The text after a leading C<---> ... C<---> block, or the whole text when
there is none -- the plugin's C<split_frontmatter>, which is stricter than
L<Langertha::Raider::Context::Frontmatter>.

=head2 strip

Leading and trailing whitespace removed, as Python's C<str.strip> does
(which counts C<\x1c>-C<\x1f> as whitespace too).

=head2 budget_bytes

C<65536>: above this many bytes of skill text the briefing is
L</oversized>.

=head2 oversized

True when L</size> is over L</budget_bytes>.

=head2 header

The plugin's C<BRIEFING_HEADER> for Claude Code, word for word (its
C<{dont}> is "do NOT call the Skill tool for any of these names").

=head2 prompt

    my $prompt = $briefing->prompt($task);

The subagent's prompt: L</header>, L</text>, then C<\n\n---\n\n# Original
task\n\n> and C<$task>. C<$task> unchanged when no skill is declared.

=head2 missing_note

    briefing: agent 'NAME' references unknown skill(s): a, b
    briefing: agent 'NAME' references unknown skill(s): a (skilletor: a@src is a template; ...), b

=head2 size_note

    briefing: agent 'NAME' is briefed with N kB of skill text (over 64 kB) — consider declaring fewer or smaller skills.

The plugin's texts. A missing name the resolver gives a reason for
(L</missing_reason>) is followed by it in parentheses; without reasons the
note is the plugin's word for word.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::SkillResolver>

=item * L<Langertha::Raider::Subagent>

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
