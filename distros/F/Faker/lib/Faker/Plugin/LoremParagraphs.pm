package Faker::Plugin::LoremParagraphs;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $count = $data->{count} //= 2;

  return join "\n\n", map $self->faker->lorem_paragraph, 1..$count;
}

1;



=head1 NAME

Faker::Plugin::LoremParagraphs - Lorem Paragraphs

=cut

=head1 ABSTRACT

Lorem Paragraphs for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::LoremParagraphs;

  my $plugin = Faker::Plugin::LoremParagraphs->new;

  # bless(..., "Faker::Plugin::LoremParagraphs")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for lorem paragraphs.

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

The execute method returns a returns a random fake lorem paragraphs.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::LoremParagraphs;

  my $plugin = Faker::Plugin::LoremParagraphs->new;

  # bless(..., "Faker::Plugin::LoremParagraphs")

  # my $result = lplugin $result->execute;

  # "eligendi laudantium provident assumenda vol...";

  # my $result = lplugin $result->execute;

  # "accusantium ex pariatur perferendis volupta...";

  # my $result = lplugin $result->execute;

  # "sit ut molestiae consequatur error tempora ...";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::LoremParagraphs;

  my $plugin = Faker::Plugin::LoremParagraphs->new;

  # bless(..., "Faker::Plugin::LoremParagraphs")

=back

=cut