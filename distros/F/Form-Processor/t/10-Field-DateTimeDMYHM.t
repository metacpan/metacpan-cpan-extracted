use strict;
use warnings;
use Test::More tests => 2;
use DateTime;



my $class = 'Form::Processor::Field::DateTimeDMYHM';


use_ok( $class );

my $field = $class->new(
    name => 'test_field',
    type => 'DateTimeDMYHM',
    form => undef,
);

ok( defined $field, 'new() called' );


