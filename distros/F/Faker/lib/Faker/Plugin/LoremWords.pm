package Faker::Plugin::LoremWords;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $count = $data->{count} //= 5;

  return join ' ', map $self->faker->lorem_word, 1..$count;
}

1;



=head1 NAME

Faker::Plugin::LoremWords - Lorem Words

=cut

=head1 ABSTRACT

Lorem Words for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::LoremWords;

  my $plugin = Faker::Plugin::LoremWords->new;

  # bless(..., "Faker::Plugin::LoremWords")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for lorem words.

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

The execute method returns a returns a random fake lorem words.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::LoremWords;

  my $plugin = Faker::Plugin::LoremWords->new;

  # bless(..., "Faker::Plugin::LoremWords")

  # my $result = $plugin->execute;

  # "aut vitae et eligendi laudantium";

  # my $result = $plugin->execute;

  # "accusantium animi corrupti dolores aliquid";

  # my $result = $plugin->execute;

  # "eos pariatur quia corporis illo";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::LoremWords;

  my $plugin = Faker::Plugin::LoremWords->new;

  # bless(..., "Faker::Plugin::LoremWords")

=back

=cut