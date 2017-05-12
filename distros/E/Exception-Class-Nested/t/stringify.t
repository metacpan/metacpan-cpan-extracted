use strict;
use warnings;

use Test::More tests => 2;

use Exception::Class::Nested (
	'MyException' => {
		description => 'This is mine!',

		'YetAnotherException' => {
			description => 'These exceptions are related to IPC',

			'ExceptionWithFields' => {
				fields => [ 'grandiosity', 'quixotic' ],
				alias => 'throw_fields',
				full_message => sub {
					my $self = shift;
					my $msg = ref($self) . ": " . $self->message;
					$msg .= " and grandiosity was " . $self->grandiosity;
					return $msg;
				},

				SubEx => {
				}
			}
		}
	},
);

eval {
	ExceptionWithFields->throw(message => "Bleagth", grandiosity => 'very very big');
};
is ( $@, 'ExceptionWithFields: Bleagth and grandiosity was very very big', "special stringification");

eval {
	SubEx->throw(message => "Blah", grandiosity => 'kinda small');
};
is ( $@, 'SubEx: Blah and grandiosity was kinda small', "special stringification for subclass");