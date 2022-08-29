package Faker::Plugin::LoremParagraph;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->lorem_sentences({
    count => $self->faker->random->range(3, 9),
  });
}

1;



=head1 NAME

Faker::Plugin::LoremParagraph - Lorem Paragraph

=cut

=head1 ABSTRACT

Lorem Paragraph for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::LoremParagraph;

  my $plugin = Faker::Plugin::LoremParagraph->new;

  # bless(..., "Faker::Plugin::LoremParagraph")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for lorem paragraph.

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

The execute method returns a returns a random fake lorem paragraph.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::LoremParagraph;

  my $plugin = Faker::Plugin::LoremParagraph->new;

  # bless(..., "Faker::Plugin::LoremParagraph")

  # my $result = lplugin $result->execute;

  # "deleniti fugiat in accusantium animi corrup...";

  # my $result = lplugin $result->execute;

  # "ducimus placeat autem ut sit adipisci asper...";

  # my $result = lplugin $result->execute;

  # "dignissimos est magni quia aut et hic eos a...";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::LoremParagraph;

  my $plugin = Faker::Plugin::LoremParagraph->new;

  # bless(..., "Faker::Plugin::LoremParagraph")

=back

=cut