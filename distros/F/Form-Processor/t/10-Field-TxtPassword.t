use strict;
use warnings;

use Test::More;
my $tests = 6;
plan tests => $tests;

my $class = 'Form::Processor::Field::TxtPassword';


use_ok( $class );


# TODO why not just grab $field = $form->field('password') ?

my $form = my_form->new;

my $field = $class->new(
    name => 'test_field',
    type => 'TxtPassword',

    #form    => my_form->new, # this doesn't work but the next line does?
    form => $form,    # TODO - something wrong with Field::form()?
);



ok( defined $field, 'new() called' );

$field->input( 'short' );
$field->validate_field;
ok( $field->has_error, 'Test for errors 1' );

my $long = '-' x 200;

$field->input( $long );
$field->validate_field;
ok( $field->has_error, 'too long' );

$field->input( 'helloworld' );    # Long enough, and on the common list;
$field->validate_field;
ok( $field->has_error, 'Common password' );

$field->input( 'this is a valid password' );
$field->validate_field;
ok( !$field->has_error, 'valid password.' );

package my_form;
use strict;
use warnings;
use base 'Form::Processor';

sub profile {
    return {
        optional => {
            login    => 'Text',
            username => 'Text',
            password => 'TxtPassword',
        },
    };
}


sub params {
    return {
        login    => 'my4login55',
        username => 'my4username',
    };
}

