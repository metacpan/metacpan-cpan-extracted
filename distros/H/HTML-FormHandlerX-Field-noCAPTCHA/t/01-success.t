#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTML::FormHandler;
use Test::Mock::Class ':all';

mock_class 'Captcha::noCAPTCHA' => 'Captcha::noCAPTCHA::Mock';
my $mock = Captcha::noCAPTCHA::Mock->new;
$mock->mock_return( verify => 1 );

use_ok('HTML::FormHandlerX::Field::noCAPTCHA');

my $form = HTML::FormHandler->new(
	name => 'test_form',
	field_list => [
		'gcaptcha' => {
			type       => 'noCAPTCHA',
			site_key   => 'fake site key',
			secret_key => 'fake secret key',
			remote_address => '127.0.0.1',
			_nocaptcha => $mock
		},
	],
);

ok($form->process({'g-recaptcha-response' => 'happy'}),'all happy path');
my @errors = $form->errors;
cmp_ok(0,'==',scalar @errors);

done_testing();
