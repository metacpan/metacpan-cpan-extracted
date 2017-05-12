#!perl -T

use Test::More tests => 16;
use Test::Exception;

use HTML::FormHandlerX::Form::Login;

my $email = 'rob@intelcompute.com';
my $password = 'foo';
my $confirm_password = $password;

my $form;

lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email password confirm_password ) ] );
} "Constructed ok and activated email and password and confirm_password";


ok( $form->field('submit')->value eq 'Register', "Submit button is " . $form->field('submit')->value);



lives_ok {
	$form->process( params => { email => 'not-valid', password => $password } );
} "Processed ok with missing confirm_password";

ok( ! $form->validated, "validated failed ok");


lives_ok {
	$form->process( params => { email => 'not-valid', password => $password, confirm_password => $confirm_password } );
} "Processed ok with bad email and password";

ok( ! $form->validated, "validated failed ok");

lives_ok {
	$form->process( params => { email => $email, password => $password, confirm_password => $confirm_password } );
} "Processed ok with email and password";

ok( $form->validated, "validated ok");


$email = '';

lives_ok {
	$form->process( params => { email => $email, password => $password, confirm_password => $confirm_password } );
} "Processed ok with email and password";

ok( ! $form->validated, "email is required");



$email = 'rob@intelcompute.com';

$password = '';
$confirm_password = '';

lives_ok {
	$form->process( params => { email => $email, password => $password, confirm_password => $confirm_password } );
} "Processed ok with email and password";

ok( ! $form->validated, "password is required");


lives_ok {
	$form->process( params => { email => $email, password => 'foo', confirm_password => 'bar' } );
} "Processed ok with email and password";

ok( ! $form->validated, "passwords must be the same");


lives_ok {
	$form->process( params => { email => $email, password => 'foo', confirm_password => 'foo' } );
} "Processed ok with email and password";

ok( $form->validated, "passwords are the same");


 