package Dist::Zilla::MVP::Assembler::Zilla 6.032;
# ABSTRACT: Dist::Zilla::MVP::Assembler for the Dist::Zilla object

use Moose;
extends 'Dist::Zilla::MVP::Assembler';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod This is a subclass of L<Dist::Zilla::MVP::Assembler> used when assembling the
#pod Dist::Zilla object.
#pod
#pod It has a C<zilla_class> attribute, which is used to determine what class of
#pod Dist::Zilla object to create.  (This isn't very useful now, but will be in the
#pod future when minting and building use different subclasses of Dist::Zilla.)
#pod
#pod Upon construction, the assembler will create a L<Dist::Zilla::MVP::RootSection>
#pod as the initial section.
#pod
#pod =cut

use MooseX::Types::Perl qw(PackageName);
use Dist::Zilla::MVP::RootSection;

sub BUILD {
  my ($self) = @_;

  my $root = Dist::Zilla::MVP::RootSection->new;
  $self->sequence->add_section($root);
}

has zilla_class => (
  is       => 'ro',
  isa      => PackageName,
  required => 1
);

#pod =method zilla
#pod
#pod This method is a shortcut for retrieving the C<zilla> from the root section.
#pod If called before that section has been finalized, it will result in an
#pod exception.
#pod
#pod =cut

sub zilla {
  my ($self) = @_;
  $self->sequence->section_named('_')->zilla;
}

#pod =method register_stash
#pod
#pod   $assembler->register_stash($name => $stash_object);
#pod
#pod This adds a stash to the assembler's zilla's stash registry -- unless the name
#pod is already taken, in which case an exception is raised.
#pod
#pod =cut

sub register_stash {
  my ($self, $name, $object) = @_;
  $self->log_fatal("tried to register $name stash entry twice")
    if $self->zilla->_local_stashes->{ $name };

  $self->zilla->_local_stashes->{ $name } = $object;
  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MVP::Assembler::Zilla - Dist::Zilla::MVP::Assembler for the Dist::Zilla object

=head1 VERSION

version 6.032

=head1 OVERVIEW

This is a subclass of L<Dist::Zilla::MVP::Assembler> used when assembling the
Dist::Zilla object.

It has a C<zilla_class> attribute, which is used to determine what class of
Dist::Zilla object to create.  (This isn't very useful now, but will be in the
future when minting and building use different subclasses of Dist::Zilla.)

Upon construction, the assembler will create a L<Dist::Zilla::MVP::RootSection>
as the initial section.

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

=head2 zilla

This method is a shortcut for retrieving the C<zilla> from the root section.
If called before that section has been finalized, it will result in an
exception.

=head2 register_stash

  $assembler->register_stash($name => $stash_object);

This adds a stash to the assembler's zilla's stash registry -- unless the name
is already taken, in which case an exception is raised.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
