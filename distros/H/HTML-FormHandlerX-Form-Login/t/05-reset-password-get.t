#!perl -T

use Test::More tests => 27;
use Test::Exception;

use HTML::FormHandlerX::Form::Login;

use constant RANDOM_SALT => 'SoMeThInG R4nD0M AnD PR1V4te';

my $email = 'rob@intelcompute.com';

my $token;

my $form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email ) ] );

$form->process( params => { email => $email } );

$form->token_salt( RANDOM_SALT );
$form->add_token_field( 'email' );
$form->token_expires( '3h' );

$token = $form->token;

# diag $token;



lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( token ) ] );
} "Constructed ok and activated token";

lives_ok {
	$form->token_salt( RANDOM_SALT );
} "set the token salt";

ok( $form->token_salt eq RANDOM_SALT, "salt is correct");

lives_ok {
	$form->add_token_field( 'email' );
} "Setting email in token field";

ok( ( $form->token_fields )[ 0 ] eq 'email', "token field to include");

lives_ok {
	$form->process( params => { token => $token } );
} "processed ok with token";


ok( $form->validated, "validated ok");

# diag $form->field('email')->value;

ok( $form->field('email')->value eq $email, "email came out ok");


ok( $form->field('submit')->value eq 'Reset Password', "Submit button is " . $form->field('submit')->value);

ok( $form->field('password')->label eq 'New Password', "Password label is " . $form->field('password')->label);


####################
# now test expired #
####################

$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email ) ] );

$form->process( params => { email => $email } );

$form->token_salt( RANDOM_SALT );
$form->add_token_field( 'email' );
$form->token_expires( '1' );

$token = $form->token;

diag "Sleeping for 2 seconds so the token expires";

sleep 2;


lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( token ) ] );
} "Constructed ok and activated token";

lives_ok {
	$form->token_salt( RANDOM_SALT );
} "set the token salt";

ok( $form->token_salt eq RANDOM_SALT, "salt is correct");

lives_ok {
	$form->add_token_field( 'email' );
} "Setting email in token field";

ok( ( $form->token_fields )[ 0 ] eq 'email', "token field to include");

lives_ok {
	$form->process( params => { token => $token } );
} "processed ok with token";


ok( ! $form->validated, "validated ok");

ok( $form->field('email')->value eq $email, "email is still extracted");


ok( ( grep { /expired/i } $form->errors) , "indeed that is an error");


#################################################
# now fiddle with the token, well the email bit #
#################################################

$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( email ) ] );

$form->process( params => { email => $email } );

$form->token_salt( RANDOM_SALT );
$form->add_token_field( 'email' );
$form->token_expires( '2d' );

$token = $form->token;


$token =~ s/^rob/foo/;


lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new( active => [ qw( token ) ] );
} "Constructed ok and activated token";

lives_ok {
	$form->token_salt( RANDOM_SALT );
} "set the token salt";

ok( $form->token_salt eq RANDOM_SALT, "salt is correct");

lives_ok {
	$form->add_token_field( 'email' );
} "Setting email in token field";

ok( ( $form->token_fields )[ 0 ] eq 'email', "token field to include");

lives_ok {
	$form->process( params => { token => $token } );
} "processed ok with token";


ok( ! $form->validated, "validated ok");


ok( ( grep { /invalid/i } $form->errors) , "indeed that is an error");



