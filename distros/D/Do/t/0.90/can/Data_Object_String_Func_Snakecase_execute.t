use 5.014;

use strict;
use warnings;
use utf8;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::String->new("hello world");

  my $func = Data::Object::String::Func::Snakecase->new(
    arg1 => $data
  );

  my $result = $func->execute;

=description

Executes the function logic and returns the result.

=signature

execute() : Object

=type

method

=cut

# TESTING

use Data::Object::String;
use Data::Object::String::Func::Snakecase;

can_ok "Data::Object::String::Func::Snakecase", "execute";

my %tests = (
  'hello world'   => 'hello_world',
  'hello  world'  => 'hello_world',
  'helloWorld'    => 'helloWorld',
  'hello-world'   => 'hello_world',
  'helloworld'    => 'helloworld',
  'Hello, World!' => 'Hello_World',
  'Helló, Wörld!' => 'Helló_Wörld',
  'foo, _bar_!'   => 'foo_bar',
  '__'            => '',
  ''              => '',
);

for my $in (keys %tests) {
  my $out = $tests{$in};
  my $data;
  my $func;

  $data = Data::Object::String->new($in);
  $func = Data::Object::String::Func::Snakecase->new(
    arg1 => $data
  );

  my $result = $func->execute;

  is_deeply $result, $out, $in;
}

ok 1 and done_testing;
