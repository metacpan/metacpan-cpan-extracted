package HTML5::DOM::CSS::Selector::Entry;
use strict;
use warnings;

use overload
	'""'		=> sub { shift->text }, 
	'%{}'		=> sub { shift->specificity }, 
	'bool'		=> sub { 1 }, 
	fallback	=> 1;

1;
__END__
