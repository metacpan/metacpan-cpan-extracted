package TestFormConfigured;

use v5.10;
use strict;
use warnings;

use Form::Tiny;

extends 'TestBaseFormConfigured';

form_field 'shown' => (
	data => {type => 'text'},
);

field_validator '--text-must-be-short--' => sub {
	return length pop() < 5;
};

1;
