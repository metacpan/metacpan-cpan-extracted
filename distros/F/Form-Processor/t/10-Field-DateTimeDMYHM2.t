use strict;
use warnings;
use Test::More tests => 2;
use DateTime;


my $class = 'Form::Processor::Field::DateTimeDMYHM2';


use_ok( $class );

my $field = $class->new(
    name => 'test_field',
    type => 'DateTimeDMYHM2',
    form => undef,
);

ok( defined $field, 'new() called' );


