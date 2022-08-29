package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::LoremSentence

=cut

$test->for('name');

=tagline

Lorem Sentence

=cut

$test->for('tagline');

=abstract

Lorem Sentence for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::LoremSentence;

  my $plugin = Faker::Plugin::LoremSentence->new;

  # bless(..., "Faker::Plugin::LoremSentence")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremSentence');

  $result
});

=description

This package provides methods for generating fake data for lorem sentence.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake lorem sentence.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

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

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremSentence');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  like $result->execute, qr/vitae et eligendi laudantium provident assu/;
  ok $result->faker->random->make; # reset randomizer
  like $result->execute, qr/aspernatur qui ad error numquam illum sunt /;
  ok $result->faker->random->make; # reset randomizer
  like $result->execute, qr/incidunt ut ratione sequi non illum laborum/;

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

  use Faker::Plugin::LoremSentence;

  my $plugin = Faker::Plugin::LoremSentence->new;

  # bless(..., "Faker::Plugin::LoremSentence")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremSentence');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/LoremSentence.pod') if $ENV{RENDER};

ok 1 and done_testing;
