package HTML::Tag::SPAN;

use strict;
use warnings;

use Class::AutoAccess;
use base qw(Class::AutoAccess HTML::Tag);

our $VERSION = '1.00';

BEGIN {
  our $class_def = {
							element			=> 'SPAN',
							tag 				=> 'SPAN',
							has_end_tag => 1,
	}
}

1;

# vim: set ts=2:
