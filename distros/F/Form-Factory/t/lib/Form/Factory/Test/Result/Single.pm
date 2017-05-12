package Form::Factory::Test::Result::Single;

use Test::Class::Moose;

with qw( Form::Factory::Test::Result );

use Form::Factory::Result::Single;

has '+result_class' => (
    default   => 'Form::Factory::Result::Single',
);

1;
