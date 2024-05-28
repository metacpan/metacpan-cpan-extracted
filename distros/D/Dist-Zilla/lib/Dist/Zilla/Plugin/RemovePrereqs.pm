package Dist::Zilla::Plugin::RemovePrereqs 6.032;
# ABSTRACT: a plugin to remove gathered prereqs

use Moose;
with 'Dist::Zilla::Role::PrereqSource';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use MooseX::Types::Moose qw(ArrayRef);
use MooseX::Types::Perl  qw(ModuleName);

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod   [RemovePrereqs]
#pod   remove = Foo::Bar
#pod   remove = MRO::Compat
#pod
#pod This will remove any prerequisite of any type from any prereq phase.  This is
#pod useful for eliminating incorrectly detected prereqs.
#pod
#pod =head1 SEE ALSO
#pod
#pod Dist::Zilla plugins:
#pod L<Prereqs|Dist::Zilla::Plugin::Prereqs>,
#pod L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>.
#pod
#pod =cut

sub mvp_multivalue_args { qw(modules_to_remove) }

sub mvp_aliases {
  return { remove => 'modules_to_remove' }
}

has modules_to_remove => (
  is  => 'ro',
  isa => ArrayRef[ ModuleName ],
  required => 1,
);

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  my $this_config = {
    modules_to_remove  => [ sort @{ $self->modules_to_remove } ],
  };

  $config->{'' . __PACKAGE__} = $this_config;

  return $config;
};

my @phases = qw(configure build test runtime develop);
my @types  = qw(requires recommends suggests conflicts);

sub register_prereqs {
  my ($self) = @_;

  my $prereqs = $self->zilla->prereqs;

  for my $p (@phases) {
    for my $t (@types) {
      for my $m (@{ $self->modules_to_remove }) {
        $prereqs->requirements_for($p, $t)->clear_requirement($m);
      }
    }
  }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::RemovePrereqs - a plugin to remove gathered prereqs

=head1 VERSION

version 6.032

=head1 SYNOPSIS

In your F<dist.ini>:

  [RemovePrereqs]
  remove = Foo::Bar
  remove = MRO::Compat

This will remove any prerequisite of any type from any prereq phase.  This is
useful for eliminating incorrectly detected prereqs.

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

=head1 SEE ALSO

Dist::Zilla plugins:
L<Prereqs|Dist::Zilla::Plugin::Prereqs>,
L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
