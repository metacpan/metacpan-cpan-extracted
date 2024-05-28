package Dist::Zilla::Prereqs 6.032;
# ABSTRACT: the prerequisites of a Dist::Zilla distribution

use Moose;

use Dist::Zilla::Pragmas;

use MooseX::Types::Moose qw(Bool HashRef);

use CPAN::Meta::Prereqs 2.120630; # add_string_requirement
use String::RewritePrefix;
use CPAN::Meta::Requirements 2.121; # requirements_for_module

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod Dist::Zilla::Prereqs is a subcomponent of Dist::Zilla.  The C<prereqs>
#pod attribute on your Dist::Zilla object is a Dist::Zilla::Prereqs object, and is
#pod responsible for keeping track of the distribution's prerequisites.
#pod
#pod In fact, a Dist::Zilla::Prereqs object is just a thin layer over a
#pod L<CPAN::Meta::Prereqs> object, stored in the C<cpan_meta_prereqs> attribute.
#pod
#pod Almost everything this object does is proxied to the CPAN::Meta::Prereqs
#pod object, so you should really read how I<that> works.
#pod
#pod Dist::Zilla::Prereqs proxies the following methods to the CPAN::Meta::Prereqs
#pod object:
#pod
#pod =for :list
#pod * finalize
#pod * is_finalized
#pod * requirements_for
#pod * as_string_hash
#pod
#pod =cut

has cpan_meta_prereqs => (
  is  => 'ro',
  isa => 'CPAN::Meta::Prereqs',
  init_arg => undef,
  default  => sub { CPAN::Meta::Prereqs->new },
  handles  => [ qw(
    finalize
    is_finalized
    requirements_for
    as_string_hash
  ) ],
);

# storing this is sort of gross, but MakeMaker winds up needing the same data
# anyway. -- xdg, 2013-10-22
# This does *not* contain configure requires, as MakeMaker explicitly should
# not have it in its fallback prereqs.
has merged_requires => (
  is => 'ro',
  isa => 'CPAN::Meta::Requirements',
  init_arg => undef,
  default => sub { CPAN::Meta::Requirements->new },
);

#pod =method register_prereqs
#pod
#pod   $prereqs->register_prereqs(%prereqs);
#pod
#pod   $prereqs->register_prereqs(\%arg, %prereqs);
#pod
#pod This method adds new minimums to the prereqs object.  If a hashref is the first
#pod arg, it may have entries for C<phase> and C<type> to indicate what kind of
#pod prereqs are being registered.  (For more information on phase and type, see
#pod L<CPAN::Meta::Spec>.)  For example, you might say:
#pod
#pod   $prereqs->register_prereqs(
#pod     { phase => 'test', type => 'recommends' },
#pod     'Test::Foo' => '1.23',
#pod     'XML::YZZY' => '2.01',
#pod   );
#pod
#pod If not given, phase and type default to runtime and requires, respectively.
#pod
#pod =cut

sub register_prereqs {
  my $self = shift;
  my $arg  = ref($_[0]) ? shift(@_) : {};
  my %prereq = @_;

  my $phase = $arg->{phase} || 'runtime';
  my $type  = $arg->{type}  || 'requires';

  my $req = $self->requirements_for($phase, $type);

  while (my ($package, $version) = each %prereq) {
    $req->add_string_requirement($package, $version || 0);
  }

  return;
}

before 'finalize' => sub {
  my ($self) = @_;
  $self->sync_runtime_build_test_requires;
};


# this avoids a long-standing CPAN.pm bug that incorrectly merges runtime and
# "build" (build+test) requirements by ensuring requirements stay unified
# across all three phases
sub sync_runtime_build_test_requires {
  my $self = shift;

  # first pass: generated merged requirements
  for my $phase ( qw/runtime build test/ ) {
    my $req = $self->requirements_for($phase, 'requires');
    $self->merged_requires->add_requirements( $req );
  };

  # second pass: update from merged requirements
  for my $phase ( qw/runtime build test/ ) {
    my $req = $self->requirements_for($phase, 'requires');
    for my $mod ( $req->required_modules ) {
      $req->clear_requirement( $mod );
      $req->add_string_requirement(
        $mod => $self->merged_requires->requirements_for_module($mod)
      );
    }
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Prereqs - the prerequisites of a Dist::Zilla distribution

=head1 VERSION

version 6.032

=head1 DESCRIPTION

Dist::Zilla::Prereqs is a subcomponent of Dist::Zilla.  The C<prereqs>
attribute on your Dist::Zilla object is a Dist::Zilla::Prereqs object, and is
responsible for keeping track of the distribution's prerequisites.

In fact, a Dist::Zilla::Prereqs object is just a thin layer over a
L<CPAN::Meta::Prereqs> object, stored in the C<cpan_meta_prereqs> attribute.

Almost everything this object does is proxied to the CPAN::Meta::Prereqs
object, so you should really read how I<that> works.

Dist::Zilla::Prereqs proxies the following methods to the CPAN::Meta::Prereqs
object:

=over 4

=item *

finalize

=item *

is_finalized

=item *

requirements_for

=item *

as_string_hash

=back

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

=head2 register_prereqs

  $prereqs->register_prereqs(%prereqs);

  $prereqs->register_prereqs(\%arg, %prereqs);

This method adds new minimums to the prereqs object.  If a hashref is the first
arg, it may have entries for C<phase> and C<type> to indicate what kind of
prereqs are being registered.  (For more information on phase and type, see
L<CPAN::Meta::Spec>.)  For example, you might say:

  $prereqs->register_prereqs(
    { phase => 'test', type => 'recommends' },
    'Test::Foo' => '1.23',
    'XML::YZZY' => '2.01',
  );

If not given, phase and type default to runtime and requires, respectively.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
