package Dist::Zilla::MVP::Assembler::GlobalConfig 6.032;
# ABSTRACT: Dist::Zilla::MVP::Assembler for global configuration

use Moose;
extends 'Dist::Zilla::MVP::Assembler';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod This is a subclass of L<Dist::Zilla::MVP::Assembler> used when assembling the
#pod global configuration.  It has a C<stash_registry> attribute, a hashref, into
#pod which stashes will be registered.
#pod
#pod They get registered via the C<register_stash> method, below, generally called
#pod by the C<register_component> method on L<Dist::Zilla::Role::Stash>-performing
#pod class.
#pod
#pod =cut

has stash_registry => (
  is  => 'ro',
  isa => 'HashRef[Object]',
  default => sub { {} },
);

#pod =method register_stash
#pod
#pod   $assembler->register_stash($name => $stash_object);
#pod
#pod This adds a stash to the assembler's stash registry -- unless the name is
#pod already taken, in which case an exception is raised.
#pod
#pod =cut

sub register_stash {
  my ($self, $name, $object) = @_;

  # $self->log_fatal("tried to register $name stash entry twice")
  confess("tried to register $name stash entry twice")
    if $self->stash_registry->{ $name };

  $self->stash_registry->{ $name } = $object;
  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MVP::Assembler::GlobalConfig - Dist::Zilla::MVP::Assembler for global configuration

=head1 VERSION

version 6.032

=head1 OVERVIEW

This is a subclass of L<Dist::Zilla::MVP::Assembler> used when assembling the
global configuration.  It has a C<stash_registry> attribute, a hashref, into
which stashes will be registered.

They get registered via the C<register_stash> method, below, generally called
by the C<register_component> method on L<Dist::Zilla::Role::Stash>-performing
class.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 register_stash

  $assembler->register_stash($name => $stash_object);

This adds a stash to the assembler's stash registry -- unless the name is
already taken, in which case an exception is raised.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
