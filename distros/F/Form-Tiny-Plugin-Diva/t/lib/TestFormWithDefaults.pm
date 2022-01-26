package TestFormWithDefaults;

use v5.10;
use strict;
use warnings;

use Form::Tiny plugins => [qw(Diva)];

form_field 'shown_default' => (
	default => sub { 'shown-default' },
	data => {t => 'text'},
);

form_field 'shown_default_overridden' => (
	default => sub { 'shown-default-bad' },
	data => {type => 'text', d => 'shown-default-good'},
);

form_field 'not_shown' => (
	default => sub { 'not-shown-default' }
);

1;
