package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);

=name

Faker::Plugin

=cut

$test->for('name');

=tagline

Fake Data Plugin

=cut

$test->for('tagline');

=abstract

Fake Data Plugin Base

=cut

$test->for('abstract');

=includes

method: new
method: execute
method: process
method: process_format
method: process_markers
method: resolve

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin;

  my $plugin = Faker::Plugin->new;

  # bless(..., "Faker::Plugin")

  # my $result = $plugin->execute;

  # ""

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin');

  $result
});

=description

This distribution provides a library of fake data generators and a framework
for extending the library via plugins.

+=encoding utf8

=cut

$test->for('description');

=integrates

Venus::Role::Buildable
Venus::Role::Optional

=cut

$test->for('integrates');

=attribute faker

The faker attribute holds the L<Faker> object.

=signature faker

  faker(Object $data) (Object)

=metadata faker

{
  since => '1.10',
}

=example-1 faker

  # given: synopsis

  package main;

  my $faker = $plugin->faker;

  # bless(..., "Faker")

=cut

$test->for('example', 1, 'faker', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');

  $result
});

=example-2 faker

  # given: synopsis

  package main;

  my $faker = $plugin->faker({});

  # bless(..., "Faker")

=cut

$test->for('example', 2, 'faker', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');

  $result
});

=example-3 faker

  # given: synopsis

  package main;

  use Faker;

  my $faker = $plugin->faker(Faker->new);

  # bless(..., "Faker")

=cut

$test->for('example', 3, 'faker', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');

  $result
});

=method execute

The execute method should be overridden by a plugin subclass, and should
generate and return a random string.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  # given: synopsis

  package main;

  my $data = $plugin->execute;

  # ""

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);

  !$result
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

  use Faker::Plugin;

  my $plugin = Faker::Plugin->new;

  # bless(... "Faker::Plugin")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin');
  ok $result->faker;

  $result
});

=example-2 new

  package main;

  use Faker::Plugin;

  my $plugin = Faker::Plugin->new({faker => ['en-us', 'es-es']});

  # bless(... "Faker::Plugin")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin');
  ok $result->faker;
  is $result->faker->locales->count, 2;
  is $result->faker->locales->first, 'en-us';
  is $result->faker->locales->last, 'es-es';

  $result
});

=example-3 new

  package main;

  use Faker::Plugin;

  my $plugin = Faker::Plugin->new({faker => Faker->new('ja-jp')});

  # bless(... "Faker::Plugin")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin');
  ok $result->faker;
  is $result->faker->locales->count, 1;
  is $result->faker->locales->first, 'ja-jp';

  $result
});

=method process

The process method accepts a data template and calls L</process_format> and
L</process_markers> with the arguments provided and returns the result.

=signature process

  process(Str $data) (Str)

=metadata process

{
  since => '1.10',
}

=example-1 process

  # given: synopsis

  package main;

  $plugin->faker->locales(['en-us']);

  my $process = $plugin->process('@?{{person_last_name}}####');

  # "\@ZWilkinson4226"

=cut

$test->for('example', 1, 'process', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=method process_format

The process_format method accepts a data template replacing any tokens found
with the return value from L</resolve>.

=signature process_format

  process_format(Str $data) (Str)

=metadata process_format

{
  since => '1.10',
}

=example-1 process_format

  # given: synopsis

  package main;

  my $process_format = $plugin->process_format('Version {{software_version}}');

  # "Version 0.78"

=cut

$test->for('example', 1, 'process_format', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=method process_markers

The process_markers method accepts a string with markers, replaces the markers
(i.e. special symbols) and returns the result. This method also, optionally,
accepts a list of the types of replacements to be performed. The markers are:
C<#> (see L<Venus::Random/digit>), C<%> (see L<Venus::Random/nonzero>), C<?>
(see L<Venus::Random/letter>), and C<\n>. The replacement types are:
I<"letters">, I<"numbers">, and I<"newlines">.

=signature process_markers

  process_markers(Str $data, Str @types) (Str)

=metadata process_markers

{
  since => '1.10',
}

=example-1 process_markers

  # given: synopsis

  package main;

  my $process_markers = $plugin->process_markers('Version %##');

  # "Version 342"

=cut

$test->for('example', 1, 'process_markers', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=example-2 process_markers

  # given: synopsis

  package main;

  my $process_markers = $plugin->process_markers('Version %##', 'numbers');

  # "Version 185"

=cut

$test->for('example', 2, 'process_markers', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=example-3 process_markers

  # given: synopsis

  package main;

  my $process_markers = $plugin->process_markers('Dept. %-??', 'letters', 'numbers');

  # "Dept. 6-EL"

=cut

$test->for('example', 3, 'process_markers', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=example-4 process_markers

  # given: synopsis

  package main;

  my $process_markers = $plugin->process_markers('root\nsecret', 'newlines');

  # "root\nsecret"

=cut

$test->for('example', 4, 'process_markers', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=method resolve

The resolve method replaces tokens from L</process_format> with the return
value from their corresponding plugins.

=signature resolve

  resolve(Str $name) (Str)

=metadata resolve

{
  since => '1.10',
}

=example-1 resolve

  # given: synopsis

  package main;

  my $color_hex_code = $plugin->resolve('color_hex_code');

  # "#adfc4b"

=cut

$test->for('example', 1, 'resolve', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=example-2 resolve

  # given: synopsis

  package main;

  my $internet_ip_address = $plugin->resolve('internet_ip_address');

  # "edb6:0311:c3e3:fdc1:597d:115c:c179:3998"

=cut

$test->for('example', 2, 'resolve', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=example-3 resolve

  # given: synopsis

  package main;

  my $color_name = $plugin->resolve('color_name');

  # "MintCream"

=cut

$test->for('example', 3, 'resolve', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=feature subclass-feature

This package is meant to be subclassed.

=cut

=example-1 subclass-feature

  package Faker::Plugin::UserId;

  use base 'Faker::Plugin';

  sub execute {
    my ($self) = @_;

    return $self->process('####-####');
  }

  package main;

  use Faker;

  my $faker = Faker->new;

  # bless(..., "Faker")

  my $result = $faker->user_id;

  # "8359-6325"

=cut

$test->for('example', 1, 'subclass-feature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

# END

$test->render('lib/Faker/Plugin.pod') if $ENV{RENDER};

ok 1 and done_testing;
