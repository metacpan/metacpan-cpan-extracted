package Const;

use strict;
use warnings;

use base 'Import::Export';

use constant thing => 'ro';
use constant list => ( one => 'two' ); 

our %EX = (
	thing => ['all'],
	list => ['all'],
);

sub one { thing }

1;
