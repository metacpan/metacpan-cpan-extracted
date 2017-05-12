#!perl -T

use Test::More tests => 10;
use Test::Exception;

use HTML::FormHandlerX::Form::Login;

use constant RANDOM_SALT => 'SoMeThInG R4nD0M AnD PR1V4te';

my $email = 'rob@intelcompute.com';

my $form;

lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email ) ] );
} "Constructed ok and activated forgot-password fields";


ok( $form->field('submit')->value eq 'Forgot Password', "Submit button is " . $form->field('submit')->value);

lives_ok {
	$form->process( params => { email => $email } );
} "Processed ok with email";

ok( $form->validated, "validated ok");


lives_ok {
	$form->token_salt( RANDOM_SALT );
} "set the token salt";

ok( $form->token_salt eq RANDOM_SALT, "salt is correct");

lives_ok {
	$form->add_token_field( 'email' );
} "set the field to include in the token";

ok( ( $form->token_fields )[ 0 ] eq 'email', "token field to include");

lives_ok { 
	$form->token_expires( '3h' );
} "set the expiry to 3 hours";


my $token;

lives_ok {
	$token = $form->token;
} "got a token";

diag $token;

