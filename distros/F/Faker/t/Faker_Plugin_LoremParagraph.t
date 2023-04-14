package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::LoremParagraph

=cut

$test->for('name');

=tagline

Lorem Paragraph

=cut

$test->for('tagline');

=abstract

Lorem Paragraph for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::LoremParagraph;

  my $plugin = Faker::Plugin::LoremParagraph->new;

  # bless(..., "Faker::Plugin::LoremParagraph")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremParagraph');

  $result
});

=description

This package provides methods for generating fake data for lorem paragraph.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake lorem paragraph.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

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

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremParagraph');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  like $result->execute, qr/error at numquam et illum numquam iste cupiditate/;
  ok $result->faker->random->pick; # reset randomizer
  like $result->execute, qr/earum consequuntur perspiciatis laborum maiores aperiam/;
  ok $result->faker->random->pick; # reset randomizer
  like $result->execute, qr/eveniet tenetur sed quod omnis et delectus sapiente non/;

  $result
});

=method new

The new method returns a new instance of the class.

=signature new

  new(HashRef $data) (Plugin)

=metadata new

{
  since => '1.10',
}

=example-1 new

  package main;

  use Faker::Plugin::LoremParagraph;

  my $plugin = Faker::Plugin::LoremParagraph->new;

  # bless(..., "Faker::Plugin::LoremParagraph")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremParagraph');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/LoremParagraph.pod') if $ENV{RENDER};

ok 1 and done_testing;
