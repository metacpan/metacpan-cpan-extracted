package HTML::Tag::HIDDEN;

use strict;
use warnings;

our $VERSION = '1.00';

use Class::AutoAccess;
use base qw(Class::AutoAccess HTML::Tag);

BEGIN {
	our $class_def	= {
							element			=> 'HIDDEN',
							tag 				=> 'INPUT',
							type 				=> 'hidden',
							has_end_tag	=> 0,
							value				=> '',
							attributes 	=> ['type','value'],
 	}
}

1;

# vim: set ts=2:
