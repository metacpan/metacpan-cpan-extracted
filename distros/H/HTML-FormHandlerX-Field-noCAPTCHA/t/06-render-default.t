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
		},
	],
);

my $expected=<<EOT;
<form id="test_form" method="post">
<div class="form_messages">
</div>
<div>
<label for="gcaptcha">Gcaptcha</label>
<script src="https://www.google.com/recaptcha/api.js" async defer></script>
<div class="g-recaptcha" data-sitekey="fake site key" data-theme="light"></div>

</div>
</form>
EOT

is($form->render,$expected,'make sure no unexpected output changes are made');

done_testing();
