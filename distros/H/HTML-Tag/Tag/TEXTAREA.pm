package HTML::Tag::TEXTAREA;

use strict;
use warnings;

use base qw(Class::AutoAccess HTML::Tag);

our $VERSION = '1.00';

BEGIN {
	our $class_def	= {
							element			=> 'TEXTAREA',
							tag 				=> 'TEXTAREA',
							value				=> '',
							cols				=> 40,
							rows				=> 5,
							attributes	=> ['cols','rows'],
    }
	}

sub inner {
	return $_[0]->value;
}


1;

# vim: set ts=2:
