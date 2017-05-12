package Inline::Select::Register ;

use strict ;
require Inline::Select ;




sub import {
	my $class = shift ;
	
	return Inline::Select->register(@_) ;
}



1 ;
