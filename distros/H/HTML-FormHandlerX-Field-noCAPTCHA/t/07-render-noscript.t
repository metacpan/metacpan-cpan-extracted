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
			remote_address => '127.0.0.1',
			noscript => 1,
		},
	],
);

my $text = $form->render;
like($text,qr/noscript/,'should render noscript markup');

done_testing();
