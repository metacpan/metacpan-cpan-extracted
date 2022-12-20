package Faker::Plugin::LoremParagraph;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return join ' ', map
    +(join ' ', map $self->faker->random->select(data_for_lorem_word()),
      1 .. $self->faker->random->range(6, 20)), 1..$self->faker->random->range(3, 9);
}

sub data_for_lorem_word {
  state $lorem_word = [
    'alias',
    'consequatur',
    'aut',
    'perferendis',
    'sit',
    'voluptatem',
    'accusantium',
    'doloremque',
    'aperiam',
    'eaque',
    'ipsa',
    'quae',
    'ab',
    'illo',
    'inventore',
    'veritatis',
    'et',
    'quasi',
    'architecto',
    'beatae',
    'vitae',
    'dicta',
    'sunt',
    'explicabo',
    'aspernatur',
    'aut',
    'odit',
    'aut',
    'fugit',
    'sed',
    'quia',
    'consequuntur',
    'magni',
    'dolores',
    'eos',
    'qui',
    'ratione',
    'voluptatem',
    'sequi',
    'nesciunt',
    'neque',
    'dolorem',
    'ipsum',
    'quia',
    'dolor',
    'sit',
    'amet',
    'consectetur',
    'adipisci',
    'velit',
    'sed',
    'quia',
    'non',
    'numquam',
    'eius',
    'modi',
    'tempora',
    'incidunt',
    'ut',
    'labore',
    'et',
    'dolore',
    'magnam',
    'aliquam',
    'quaerat',
    'voluptatem',
    'ut',
    'enim',
    'ad',
    'minima',
    'veniam',
    'quis',
    'nostrum',
    'exercitationem',
    'ullam',
    'corporis',
    'nemo',
    'enim',
    'ipsam',
    'voluptatem',
    'quia',
    'voluptas',
    'sit',
    'suscipit',
    'laboriosam',
    'nisi',
    'ut',
    'aliquid',
    'ex',
    'ea',
    'commodi',
    'consequatur',
    'quis',
    'autem',
    'vel',
    'eum',
    'iure',
    'reprehenderit',
    'qui',
    'in',
    'ea',
    'voluptate',
    'velit',
    'esse',
    'quam',
    'nihil',
    'molestiae',
    'et',
    'iusto',
    'odio',
    'dignissimos',
    'ducimus',
    'qui',
    'blanditiis',
    'praesentium',
    'laudantium',
    'totam',
    'rem',
    'voluptatum',
    'deleniti',
    'atque',
    'corrupti',
    'quos',
    'dolores',
    'et',
    'quas',
    'molestias',
    'excepturi',
    'sint',
    'occaecati',
    'cupiditate',
    'non',
    'provident',
    'sed',
    'ut',
    'perspiciatis',
    'unde',
    'omnis',
    'iste',
    'natus',
    'error',
    'similique',
    'sunt',
    'in',
    'culpa',
    'qui',
    'officia',
    'deserunt',
    'mollitia',
    'animi',
    'id',
    'est',
    'laborum',
    'et',
    'dolorum',
    'fuga',
    'et',
    'harum',
    'quidem',
    'rerum',
    'facilis',
    'est',
    'et',
    'expedita',
    'distinctio',
    'nam',
    'libero',
    'tempore',
    'cum',
    'soluta',
    'nobis',
    'est',
    'eligendi',
    'optio',
    'cumque',
    'nihil',
    'impedit',
    'quo',
    'porro',
    'quisquam',
    'est',
    'qui',
    'minus',
    'id',
    'quod',
    'maxime',
    'placeat',
    'facere',
    'possimus',
    'omnis',
    'voluptas',
    'assumenda',
    'est',
    'omnis',
    'dolor',
    'repellendus',
    'temporibus',
    'autem',
    'quibusdam',
    'et',
    'aut',
    'consequatur',
    'vel',
    'illum',
    'qui',
    'dolorem',
    'eum',
    'fugiat',
    'quo',
    'voluptas',
    'nulla',
    'pariatur',
    'at',
    'vero',
    'eos',
    'et',
    'accusamus',
    'officiis',
    'debitis',
    'aut',
    'rerum',
    'necessitatibus',
    'saepe',
    'eveniet',
    'ut',
    'et',
    'voluptates',
    'repudiandae',
    'sint',
    'et',
    'molestiae',
    'non',
    'recusandae',
    'itaque',
    'earum',
    'rerum',
    'hic',
    'tenetur',
    'a',
    'sapiente',
    'delectus',
    'ut',
    'aut',
    'reiciendis',
    'voluptatibus',
    'maiores',
    'doloribus',
    'asperiores',
    'repellat',
  ]
}

1;



=head1 NAME

Faker::Plugin::LoremParagraph - Lorem Paragraph

=cut

=head1 ABSTRACT

Lorem Paragraph for Faker

=cut

=head1 VERSION

1.17

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