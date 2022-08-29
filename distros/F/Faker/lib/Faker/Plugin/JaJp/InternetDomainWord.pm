package Faker::Plugin::JaJp::InternetDomainWord;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_format(
    $self->faker->random->select(data_for_internet_domain_word())
  );
}

sub data_for_internet_domain_word {
  state $internet_domain_word = [
    '{{person_last_name_ascii}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::InternetDomainWord - Internet Domain Word

=cut

=head1 ABSTRACT

Internet Domain Word for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::InternetDomainWord;

  my $plugin = Faker::Plugin::JaJp::InternetDomainWord->new;

  # bless(..., "Faker::Plugin::JaJp::InternetDomainWord")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet domain word.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::JaJp>

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

  use Faker::Plugin::JaJp::InternetDomainWord;

  my $plugin = Faker::Plugin::JaJp::InternetDomainWord->new;

  # bless(..., "Faker::Plugin::JaJp::InternetDomainWord")

  # my $result = $plugin->execute;

  # 'uno';

  # my $result = $plugin->execute;

  # 'yamagishi';

  # my $result = $plugin->execute;

  # 'harada';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::InternetDomainWord;

  my $plugin = Faker::Plugin::JaJp::InternetDomainWord->new;

  # bless(..., "Faker::Plugin::JaJp::InternetDomainWord")

=back

=cut