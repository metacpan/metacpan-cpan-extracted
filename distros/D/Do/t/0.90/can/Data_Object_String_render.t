use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

render

=usage

  # given "Hi, {name}!"

  $string->render({name => 'Friend'}); # Hi, Friend!

=description

The render method treats the string as a template and performs a simple token
replacement using the argument provided.

=signature

render(HashRef $arg1) : StrObject

=type

method

=cut

# TESTING

use Data::Object::String;

my $string = Data::Object::String->new("Hi, {name}! Welcome to the {group}.");
my $rendered = $string->render({ name => 'Friend', group => 'club' });

is $rendered, "Hi, Friend! Welcome to the club.";

ok 1 and done_testing;
