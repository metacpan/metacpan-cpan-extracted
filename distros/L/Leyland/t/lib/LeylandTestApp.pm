package LeylandTestApp;

use Moo;

extends 'Leyland';

sub setup {
	return {
		views => ['Tenjin'],
		view_dir => 't/views',
		default_mime => 'application/json'
	};
}

1;
