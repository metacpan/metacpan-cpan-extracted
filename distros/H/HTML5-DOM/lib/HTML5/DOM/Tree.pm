package HTML5::DOM::Tree;
use strict;
use warnings;

use overload
	'""'		=> sub { $_[0]->document->html }, 
	'@{}'		=> sub { [$_[0]->document] }, 
	'bool'		=> sub { 1 }, 
	'=='		=> sub { defined $_[1] && $_[0]->isSameTree($_[1]) }, 
	'!='		=> sub { !defined $_[1] || !$_[0]->isSameTree($_[1]) }, 
	fallback	=> 1;

sub text { shift->document->text(@_) }
sub html { shift->document->html(@_) }

1;
