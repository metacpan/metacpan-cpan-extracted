package Faker::Plugin::EsEs::InternetEmailAddress;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $email_address = $self->process_markers(
    $self->process_format(
      $self->faker->random->select(data_for_internet_email_address())
    )
  );

  $email_address = lc $self->transliterate($email_address);

  $email_address =~ s/\s+/-/g;

  return $email_address;
}

sub data_for_internet_email_address {
  state $internet_email_address = [
    '{{person_last_name}}.{{person_first_name}}@{{internet_domain_name}}',
    '{{person_last_name}}.{{person_first_name}}@{{internet_email_domain}}',
    '{{person_first_name}}.{{person_last_name}}@{{internet_domain_name}}',
    '{{person_first_name}}.{{person_last_name}}@{{internet_email_domain}}',
    '{{person_first_name}}##@{{internet_domain_name}}',
    '{{person_first_name}}##@{{internet_email_domain}}',
    '{{person_first_name}}####@{{internet_domain_name}}',
    '{{person_first_name}}####@{{internet_email_domain}}',
    '?{{person_last_name}}@{{internet_domain_name}}',
    '?{{person_last_name}}@{{internet_email_domain}}',
    '?{{person_last_name}}####@{{internet_domain_name}}',
    '?{{person_last_name}}####@{{internet_email_domain}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::InternetEmailAddress - Internet Email Address

=cut

=head1 ABSTRACT

Internet Email Address for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::InternetEmailAddress;

  my $plugin = Faker::Plugin::EsEs::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailAddress")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet email address.

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

The execute method returns a returns a random fake internet email address.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::InternetEmailAddress;

  my $plugin = Faker::Plugin::EsEs::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailAddress")

  # my $result = $plugin->execute;

  # 'rafael94@montano-y-alcala.org';

  # my $result = $plugin->execute;

  # 'alba82@terra.com';

  # my $result = $plugin->execute;

  # 'quesada.jordi@hotmail.com';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::InternetEmailAddress;

  my $plugin = Faker::Plugin::EsEs::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailAddress")

=back

=cut