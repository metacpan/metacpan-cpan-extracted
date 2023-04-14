package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::LoremParagraphs

=cut

$test->for('name');

=tagline

Lorem Paragraphs

=cut

$test->for('tagline');

=abstract

Lorem Paragraphs for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::LoremParagraphs;

  my $plugin = Faker::Plugin::LoremParagraphs->new;

  # bless(..., "Faker::Plugin::LoremParagraphs")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremParagraphs');

  $result
});

=description

This package provides methods for generating fake data for lorem paragraphs.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake lorem paragraphs.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

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

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremParagraphs');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  like $result->execute, qr/dolores magnam sed quasi quas vel earum est quaerat/;
  ok $result->faker->random->pick; # reset randomizer
  like $result->execute, qr/reiciendis blanditiis totam quia deleniti sint aut/;
  ok $result->faker->random->pick; # reset randomizer
  like $result->execute, qr/itaque et et hic pariatur eos et architecto aut/;

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

  use Faker::Plugin::LoremParagraphs;

  my $plugin = Faker::Plugin::LoremParagraphs->new;

  # bless(..., "Faker::Plugin::LoremParagraphs")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremParagraphs');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/LoremParagraphs.pod') if $ENV{RENDER};

ok 1 and done_testing;
