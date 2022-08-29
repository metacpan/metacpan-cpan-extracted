package Faker::Plugin::LoremSentences;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $count = $data->{count} //= 5;

  return join ' ', map $self->faker->lorem_sentence, 1..$count;
}

1;



=head1 NAME

Faker::Plugin::LoremSentences - Lorem Sentences

=cut

=head1 ABSTRACT

Lorem Sentences for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::LoremSentences;

  my $plugin = Faker::Plugin::LoremSentences->new;

  # bless(..., "Faker::Plugin::LoremSentences")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for lorem sentences.

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

The execute method returns a returns a random fake lorem sentences.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::LoremSentences;

  my $plugin = Faker::Plugin::LoremSentences->new;

  # bless(..., "Faker::Plugin::LoremSentences")

  # my $result = lplugin $result->execute;

  # "vero deleniti fugiat in accusantium animi c...";

  # my $result = lplugin $result->execute;

  # "enim accusantium aliquid id reprehenderit c...";

  # my $result = lplugin $result->execute;

  # "reprehenderit ut autem cumque ea sint dolor...";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::LoremSentences;

  my $plugin = Faker::Plugin::LoremSentences->new;

  # bless(..., "Faker::Plugin::LoremSentences")

=back

=cut