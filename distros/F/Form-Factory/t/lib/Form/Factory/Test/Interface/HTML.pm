package Form::Factory::Test::Interface::HTML;

use Test::Class::Moose;
use Test::More;

with qw( Form::Factory::Test::Interface );

has '+name' => (
    default => 'HTML',
);

1;
