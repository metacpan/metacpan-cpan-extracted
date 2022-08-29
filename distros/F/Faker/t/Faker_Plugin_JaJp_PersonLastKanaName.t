package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::PersonLastKanaName

=cut

$test->for('name');

=tagline

Person Last Kana Name

=cut

$test->for('tagline');

=abstract

Person Last Kana Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp::PersonLastKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonLastKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastKanaName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::PersonLastKanaName');

  $result
});

=description

This package provides methods for generating fake data for person last kana name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake person last kana name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::JaJp::PersonLastKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonLastKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastKanaName")

  # my $result = $plugin->execute;

  # 'サイトウ';

  # my $result = $plugin->execute;

  # 'ササダ';

  # my $result = $plugin->execute;

  # 'ヤマギシ';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::PersonLastKanaName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'サイトウ';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'ササダ';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'ヤマギシ';

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

  use Faker::Plugin::JaJp::PersonLastKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonLastKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastKanaName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::PersonLastKanaName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/JaJp/PersonLastKanaName.pod') if $ENV{RENDER};

ok 1 and done_testing;
