package Dist::Zilla::MVP::RootSection 6.032;
# ABSTRACT: a standard section in Dist::Zilla's configuration sequence

use Moose;
extends 'Config::MVP::Section';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This is a subclass of L<Config::MVP::Section>, used as the starting section by
#pod L<Dist::Zilla::MVP::Assembler::Zilla>.  It has a number of useful defaults, as
#pod well as a C<zilla> attribute which will, after section finalization, contain a
#pod Dist::Zilla object with which subsequent plugin sections may register.
#pod
#pod Those useful defaults are:
#pod
#pod =for :list
#pod * name defaults to _
#pod * aliases defaults to { author => 'authors' }
#pod * multivalue_args defaults to [ 'authors' ]
#pod
#pod =cut

use MooseX::LazyRequire;
use MooseX::SetOnce;
use Moose::Util::TypeConstraints;

has '+name'    => (default => '_');

has '+aliases' => (default => sub { return { author => 'authors' } });

has '+multivalue_args' => (default => sub { [ qw(authors) ] });

has zilla => (
  is     => 'ro',
  isa    => class_type('Dist::Zilla'),
  traits => [ qw(SetOnce) ],
  writer => 'set_zilla',
  lazy_required => 1,
);

after finalize => sub {
  my ($self) = @_;

  my $assembler = $self->sequence->assembler;

  my %payload = %{ $self->payload };

  my %dzil;
  $dzil{$_} = delete $payload{":$_"} for grep { s/\A:// } keys %payload;

  my $zilla = $assembler->zilla_class->new( \%payload );

  if (defined $dzil{version}) {
    Dist::Zilla::Util->_assert_loaded_class_version_ok(
      'Dist::Zilla',
      $dzil{version},
    );
  }

  $self->set_zilla($zilla);
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MVP::RootSection - a standard section in Dist::Zilla's configuration sequence

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This is a subclass of L<Config::MVP::Section>, used as the starting section by
L<Dist::Zilla::MVP::Assembler::Zilla>.  It has a number of useful defaults, as
well as a C<zilla> attribute which will, after section finalization, contain a
Dist::Zilla object with which subsequent plugin sections may register.

Those useful defaults are:

=over 4

=item *

name defaults to _

=item *

aliases defaults to { author => 'authors' }

=item *

multivalue_args defaults to [ 'authors' ]

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

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
