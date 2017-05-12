#!perl -T

use Test::More tests => 16;
use Test::Exception;

use HTML::FormHandlerX::Form::Login;

my $email = 'rob@intelcompute.com';
my $password = 'foo';

my $form;

lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( openid_identifier ) ] );
} "Constructed ok and activated openid_identifier";


ok( $form->field('submit')->value eq 'Login', "Submit button is " . $form->field('submit')->value);


lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( password ) ] );
} "Constructed ok and activated password";


ok( $form->field('submit')->value eq 'Login', "Submit button is " . $form->field('submit')->value);


lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( username password ) ] );
} "Constructed ok and activated username and password";


ok( $form->field('submit')->value eq 'Login', "Submit button is " . $form->field('submit')->value);




lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email password ) ] );
} "Constructed ok and activated email and password";


ok( $form->field('submit')->value eq 'Login', "Submit button is " . $form->field('submit')->value);


lives_ok {
	$form->process( params => { email => 'not-valid', password => $password } );
} "Processed ok with bad email and password";

ok( ! $form->validated, "validated failed ok");

lives_ok {
	$form->process( params => { email => $email, password => $password } );
} "Processed ok with email and password";

ok( $form->validated, "validated ok");


$email = '';

lives_ok {
	$form->process( params => { email => $email, password => $password } );
} "Processed ok with email and password";

ok( ! $form->validated, "email is required");



$email = 'rob@intelcompute.com';

$password = '';

lives_ok {
	$form->process( params => { email => $email, password => $password } );
} "Processed ok with email and password";

ok( ! $form->validated, "password is required");





 