package Faker::Plugin::EsEs::InternetDomainWord;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $domain_word = lc $self->transliterate($self->faker->company_name);

  $domain_word =~ s/\W+/-/g;
  $domain_word =~ s/^\W+|\W+$//g;

  return $domain_word;
}

1;



=head1 NAME

Faker::Plugin::EsEs::InternetDomainWord - Internet Domain Word

=cut

=head1 ABSTRACT

Internet Domain Word for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::InternetDomainWord;

  my $plugin = Faker::Plugin::EsEs::InternetDomainWord->new;

  # bless(..., "Faker::Plugin::EsEs::InternetDomainWord")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet domain word.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::EsEs>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake internet domain word.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::InternetDomainWord;

  my $plugin = Faker::Plugin::EsEs::InternetDomainWord->new;

  # bless(..., "Faker::Plugin::EsEs::InternetDomainWord")

  # my $result = $plugin->execute;

  # 'asociacion-lujan';

  # my $result = $plugin->execute;

  # 'montano-y-alcala';

  # my $result = $plugin->execute;

  # 'mata-de-ibarra';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::InternetDomainWord;

  my $plugin = Faker::Plugin::EsEs::InternetDomainWord->new;

  # bless(..., "Faker::Plugin::EsEs::InternetDomainWord")

=back

=cut