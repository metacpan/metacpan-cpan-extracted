#!perl -T

use Test::More tests => 11;
use Test::Exception;

use HTML::FormHandlerX::Form::Login;

my $old_password = 'foo';
my $password = 'bar';
my $confirm_password = 'bar';

my $form;

lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( old_password password confirm_password ) ] );
} "Constructed ok and activated change-password fields";



ok( $form->field('submit')->value eq 'Change Password', "Submit button is " . $form->field('submit')->value);
ok( $form->field('password')->label eq 'New Password', "Password label is " . $form->field('password')->label);



lives_ok {
	$form->process( params => { old_password     => $old_password,
	                            password         => $password,
	                            confirm_password => $confirm_password,
	                          } );
} "Processed ok with passwords";

ok( $form->validated, "validated ok");
 


$old_password = '';

lives_ok {
	$form->process( params => { old_password     => $old_password,
	                            password         => $password,
	                            confirm_password => $confirm_password,
	                          } );
} "Processed ok with passwords";

ok( ! $form->validated, "old_password is required");




$old_password = 'foo';
$password = '';

lives_ok {
	$form->process( params => { old_password     => $old_password,
	                            password         => $password,
	                            confirm_password => $confirm_password,
	                          } );
} "Processed ok with passwords";

ok( ! $form->validated, "password is required");






$password = 'foo';
$confirm_password = 'baz';

lives_ok {
	$form->process( params => { old_password     => $old_password,
	                            password         => $password,
	                            confirm_password => $confirm_password,
	                          } );
} "Processed ok with passwords";

ok( ! $form->validated, "confirm password mismatch");






