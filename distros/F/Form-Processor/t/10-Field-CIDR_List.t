use strict;
use warnings;
use Test::More tests => 6;
use Net::CIDR;

my $class = 'Form::Processor::Field::CIDR_List';


use_ok( $class );
my $field = $class->new(
    name => 'test_field',
    type => 'CIDR_List',
    form => undef,
);

ok( defined $field, 'new() called' );

$field->input( '192.168.1.1/24' );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 1' );
is( $field->value, '192.168.1.1/24', 'value returned' );

$field->input( '192.168.1.1/300' );
$field->validate_field;
ok( $field->has_error, 'Test for errors 1' );
is( $field->errors->[0], "Failed to parse address '192.168.1.1/300'", 'Test error message' );


