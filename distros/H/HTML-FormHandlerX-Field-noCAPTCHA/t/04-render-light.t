#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTML::FormHandler;

use_ok('HTML::FormHandlerX::Field::noCAPTCHA');

my $form = HTML::FormHandler->new(
	name => 'test_form',
	field_list => [
		'gcaptcha' => {
			type       => 'noCAPTCHA',
			site_key   => 'fake site key',
			secret_key => 'fake secret key',
			api_url    => 'file:t/success_response.json',
			remote_address => '127.0.0.1',
		},
	],
);

my $text = $form->render;

like($text,qr/data-theme="light"/,'should render data-theme light');

done_testing();
