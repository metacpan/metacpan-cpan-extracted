package TestBaseFormConfigured;

use v5.10;
use strict;
use warnings;

use Form::Tiny plugins => [qw(Diva)];

diva_config
	'id_base' => 'myident-',
	'label_class' => 'mylabel-class',
	;

diva_config 'error_class' => 'myerror-class';

1;

