package Langertha::Raider::SkillResolver;
# ABSTRACT: Internal chain of skill resolvers: a skill name to its directory and SKILL.md
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;


has resolvers => (
  is      => 'ro',
  isa     => 'ArrayRef[Object]',
  default => sub { [] },
);


sub resolve {
  my ( $self, $name ) = @_;
  return unless defined $name && length $name;
  for my $resolver (@{ $self->resolvers }) {
    my $skill = $resolver->resolve($name);
    return $skill if $skill;
  }
  return;
}


sub why_unresolved {
  my ( $self, $name ) = @_;
  return unless defined $name && length $name;
  for my $resolver (grep { $_->can('why_unresolved') } @{ $self->resolvers }) {
    my $reason = $resolver->why_unresolved($name);
    return $reason if defined $reason && length $reason;
  }
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::SkillResolver - Internal chain of skill resolvers: a skill name to its directory and SKILL.md

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $resolver = Langertha::Raider::SkillResolver->new(
      resolvers => [
        Langertha::Raider::SkillResolver::Catalog->new( catalog => $context->skill_catalog ),
      ],
    );
    my $skill = $resolver->resolve('getty-perl-core');
    # { name => 'getty-perl-core', dir => '/abs/.claude/skills/getty-perl-core',
    #   file => '/abs/.claude/skills/getty-perl-core/SKILL.md' }  or undef

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The one interface through which a skill an agent declares is found when
it is briefed (ADR 0020 E<sect>6): an ordered chain of resolvers, each
an object with a C<resolve($name)> method that returns
C<< { name, dir, file } >> or nothing. The first resolver that knows the
name wins.

The chain of an application is L<Langertha::Raider::Context/skill_resolver>,
built from L<Langertha::Raider::Context/skill_resolvers>: the skill
catalogue of the context (L<Langertha::Raider::SkillResolver::Catalog>),
then -- in the Claude layout -- the skills of the sources in
F<skilletor.json>, read straight from the source without installing them
(L<Langertha::Raider::SkillResolver::Skilletor>).

A resolver may also answer C<why_unresolved($name)> with a reason for a
name it knows of but cannot serve (a template, a source that cannot be
fetched); L</why_unresolved> asks them.

=head2 resolvers

The resolvers, first asked first. Defaults to none (nothing resolves).

=head2 resolve

    my $skill = $resolver->resolve('superpowers:brainstorming');

The C<< { name, dir, file } >> of the first resolver that knows C<$name>,
or C<undef>.

=head2 why_unresolved

    my $reason = $resolver->why_unresolved('tpl');   # 'skilletor: ...' or undef

The first reason a resolver of the chain gives for C<$name> not resolving
(a resolver without a C<why_unresolved> method has none), or C<undef>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::SkillResolver::Catalog>

=item * L<Langertha::Raider::SkillResolver::Skilletor>

=item * L<Langertha::Raider::Briefing>

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
