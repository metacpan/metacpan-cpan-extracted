use strict;
use warnings;
use Test::More tests => 7;
use Email::Valid;



my $class = 'Form::Processor::Field::Email';


use_ok( $class );
my $field = $class->new(
    name => 'test_field',
    type => 'Email',
    form => undef,
);

ok( defined $field, 'new() called' );

$field->input( 'foo@bar.com' );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 1' );
is( $field->value, 'foo@bar.com', 'value returned' );

$field->input( 'foo@bar' );
$field->validate_field;
ok( $field->has_error, 'Test for errors 1' );
is( $field->errors->[0], 'Email should be of the format someuser@example.com', 'Test error message' );

$field->input( 'someuser@example.com' );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 2 although probably should fail' );



