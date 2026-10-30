package Langertha::Raider::SkillResolver::Catalog;
# ABSTRACT: Internal skill resolver over the skill catalogue of a context
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;


has catalog => (
  is       => 'ro',
  isa      => 'Langertha::Raider::Context::Skills',
  required => 1,
);


sub resolve {
  my ( $self, $name ) = @_;
  my $skill = $self->catalog->find($name) or return;
  return { name => $skill->{name}, dir => $skill->{dir}, file => $skill->{file} };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::SkillResolver::Catalog - Internal skill resolver over the skill catalogue of a context

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $r = Langertha::Raider::SkillResolver::Catalog->new( catalog => $context->skill_catalog );
    my $skill = $r->resolve('helper:tidy');   # { name, dir, file } or undef

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The first resolver of L<Langertha::Raider::SkillResolver>: a skill of the
L<Langertha::Raider::Context::Skills> catalogue -- every root and enabled
plugin (C<plugin:skill>), model-invocable or not
(L<Langertha::Raider::Context::Skills/find>).

=head2 catalog

The L<Langertha::Raider::Context::Skills>. Required.

=head2 resolve

    my $skill = $r->resolve('pdf');

C<< { name, dir, file } >> of the catalogue's skill of that name, or
C<undef>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::SkillResolver>

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
