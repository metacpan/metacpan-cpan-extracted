package Faker::Plugin::LoremSentence;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->lorem_words({
    count => $self->faker->random->range(6, 20),
  }) . '.';
}

1;



=head1 NAME

Faker::Plugin::LoremSentence - Lorem Sentence

=cut

=head1 ABSTRACT

Lorem Sentence for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::LoremSentence;

  my $plugin = Faker::Plugin::LoremSentence->new;

  # bless(..., "Faker::Plugin::LoremSentence")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for lorem sentence.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake lorem sentence.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::LoremSentence;

  my $plugin = Faker::Plugin::LoremSentence->new;

  # bless(..., "Faker::Plugin::LoremSentence")

  # my $result = lplugin $result->execute;

  # "vitae et eligendi laudantium provident assu...";

  # my $result = lplugin $result->execute;

  # "aspernatur qui ad error numquam illum sunt ...";

  # my $result = lplugin $result->execute;

  # "incidunt ut ratione sequi non illum laborum...";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::LoremSentence;

  my $plugin = Faker::Plugin::LoremSentence->new;

  # bless(..., "Faker::Plugin::LoremSentence")

=back

=cut