package Faker::Plugin::JaJp::InternetEmailAddress;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $email_address = $self->process_markers(
    $self->process_format(
      $self->faker->random->select(data_for_internet_email_address())
    )
  );

  $email_address =~ s/\s+/-/g;

  return lc $email_address;
}

sub data_for_internet_email_address {
  state $internet_email_address = [
    '{{person_last_name_ascii}}.{{person_first_name_ascii}}@{{internet_domain_name}}',
    '{{person_last_name_ascii}}.{{person_first_name_ascii}}@{{internet_email_domain}}',
    '{{person_first_name_ascii}}.{{person_last_name_ascii}}@{{internet_domain_name}}',
    '{{person_first_name_ascii}}.{{person_last_name_ascii}}@{{internet_email_domain}}',
    '{{person_first_name_ascii}}##@{{internet_domain_name}}',
    '{{person_first_name_ascii}}##@{{internet_email_domain}}',
    '{{person_first_name_ascii}}####@{{internet_domain_name}}',
    '{{person_first_name_ascii}}####@{{internet_email_domain}}',
    '?{{person_last_name_ascii}}@{{internet_domain_name}}',
    '?{{person_last_name_ascii}}@{{internet_email_domain}}',
    '?{{person_last_name_ascii}}####@{{internet_domain_name}}',
    '?{{person_last_name_ascii}}####@{{internet_email_domain}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::InternetEmailAddress - Internet Email Address

=cut

=head1 ABSTRACT

Internet Email Address for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::InternetEmailAddress;

  my $plugin = Faker::Plugin::JaJp::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::JaJp::InternetEmailAddress")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet email address.

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

The execute method returns a returns a random fake internet email address.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::InternetEmailAddress;

  my $plugin = Faker::Plugin::JaJp::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::JaJp::InternetEmailAddress")

  # my $result = $plugin->execute;

  # 'tomoya45@sugiyama.jp';

  # my $result = $plugin->execute;

  # 'nagisa.naoto@saito.com';

  # my $result = $plugin->execute;

  # 'skiriyama0225@gmail.com';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::InternetEmailAddress;

  my $plugin = Faker::Plugin::JaJp::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::JaJp::InternetEmailAddress")

=back

=cut