#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTML::FormHandler;
use Test::Mock::Class ':all';

mock_class 'Captcha::noCAPTCHA' => 'Captcha::noCAPTCHA::Mock';
my $mock = Captcha::noCAPTCHA::Mock->new;
$mock->mock_return( verify => 0 );

my $form = HTML::FormHandler->new(
	name => 'test_form',
	field_list => [
		'gcaptcha' => {
			type       => 'noCAPTCHA',
			site_key   => 'fake site key',
			secret_key => 'fake secret key',
			remote_address => '127.0.0.1',
			_nocaptcha => $mock,
		},
	],
);

ok(!$form->process({what => 'ever'}),'all happy path');
my @errors = $form->errors;
cmp_ok(1,'==',scalar @errors);
cmp_ok('You must prove your Humanity!','eq',$errors[0]);

ok(!$form->process({'g-recaptcha-response' => 'happy'}),'all happy path');
@errors = $form->errors;
cmp_ok(1,'==',scalar @errors);
cmp_ok('You\'ve failed to prove your Humanity!','eq',$errors[0]);

$mock->mock_tally;


done_testing();
