package HTML::Tag::PASSWORD;

use strict;
use warnings;

use Class::AutoAccess;
use base qw(Class::AutoAccess HTML::Tag);

our $VERSION = '1.00';

BEGIN {
	our $class_def	= {
							element			=> 'PASSWORD',
							tag 				=> 'INPUT',
							has_end_tag => 0, 
							type 				=> 'password',
							value				=> '',
							attributes 	=> ['type','value'],
	}
}


1;

# vim: set ts=2:
