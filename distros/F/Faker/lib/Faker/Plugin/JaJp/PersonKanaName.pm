package Faker::Plugin::JaJp::PersonKanaName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_format($self->faker->random->select(format_for_name()));
}

sub format_for_name {
  state $name = [
    [
      '{{person_last_kana_name}}',
      '{{person_first_kana_name}}',
    ],
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::PersonKanaName - Person Kana Name

=cut

=head1 ABSTRACT

Person Kana Name for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::PersonKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonKanaName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person kana name.

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

The execute method returns a returns a random fake person kana name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::PersonKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonKanaName")

  # my $result = $plugin->execute;

  # 'ウノ ハナコ';

  # my $result = $plugin->execute;

  # 'ムラヤマ アケミ';

  # my $result = $plugin->execute;

  # 'ヤマモト ツバサ';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::PersonKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonKanaName")

=back

=cut