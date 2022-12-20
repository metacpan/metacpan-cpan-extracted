package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::PersonKanaName

=cut

$test->for('name');

=tagline

Person Kana Name

=cut

$test->for('tagline');

=abstract

Person Kana Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp::PersonKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonKanaName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::PersonKanaName');

  $result
});

=description

This package provides methods for generating fake data for person kana name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake person kana name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

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

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::PersonKanaName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'ウノ ハナコ';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'ムラヤマ アケミ';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'ヤマモト ツバサ';

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

  use Faker::Plugin::JaJp::PersonKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonKanaName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::PersonKanaName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/JaJp/PersonKanaName.pod') if $ENV{RENDER};

ok 1 and done_testing;
