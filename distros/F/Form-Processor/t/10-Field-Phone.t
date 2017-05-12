use strict;
use warnings;

use Test::More;
my $tests = 2;
plan tests => $tests;

my $class = 'Form::Processor::Field::Phone';


use_ok( $class );
my $field = $class->new(
    name => 'test_field',
    type => 'Phone',
    form => undef,
);

ok( defined $field, 'new() called' );
