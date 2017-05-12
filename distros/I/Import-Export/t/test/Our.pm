package Our;

use strict;
use warnings;

use base 'Import::Export';

our $scalar = 'ro';
our %hash   = ( one => 'two' ); 
our @array  = qw/one two/;

our %EX = (
	'$scalar' => ['all'],
	'%hash'   => ['all'],
	'@array'  => ['all'], 
);

1;
