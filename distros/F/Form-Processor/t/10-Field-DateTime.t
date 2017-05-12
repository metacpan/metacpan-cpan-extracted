use strict;
use warnings;
use Test::More tests => 16;
use DateTime;
use Date::Manip;
use DateTime::Format::DateManip;


my $class = 'Form::Processor::Field::DateTime';



use_ok( $class );
my $field = $class->new(
    name => 'test_field',
    type => 'DateTime',
    form => undef,
);

ok( defined $field, 'new() called' );

$field->input( 'today' );
$field->validate_field;
ok( !$field->has_error, 'Test for today errors' );
isa_ok( $field->value, 'DateTime' );

$field->input( 'April 25, 2000' );
$field->validate_field;
ok( !$field->has_error, 'Test for April 25, 2000 errors' );
isa_ok( $field->value, 'DateTime' );
is( $field->value->year,  2000, 'Found year' );
is( $field->value->month, 4,    'Found month' );
is( $field->value->day,   25,   'Found day' );

$field->input( 'Jan 25, 2000 10:32:12am EST' );
$field->validate_field;
ok( !$field->has_error, 'Test for Jan 25, 2000 errors' );
isa_ok( $field->value, 'DateTime' );
is( $field->value->year,  2000, 'Found year' );
is( $field->value->month, 1,    'Found month' );
is( $field->value->day,   25,   'Found day' );

$field->input( 'Jan 45, 2000 10:32:12am EST' );
$field->validate_field;
ok( $field->has_error, 'Test for Jan 45, 2000 errors' );

# Not sure how to best test thsi with I10N
is( $field->errors->[0], "Sorry, don't understand date", 'Compare error string' );


