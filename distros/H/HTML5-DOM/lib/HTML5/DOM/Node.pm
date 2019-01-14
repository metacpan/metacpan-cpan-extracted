package HTML5::DOM::Node;
use strict;
use warnings;

use overload
	'""'		=> sub { $_[0]->html }, 
	'@{}'		=> sub { $_[0]->childrenNode->array }, 
	'%{}'		=> \&__attrHashAccess, 
	'=='		=> sub { defined $_[1] && $_[0]->isSameNode($_[1]) }, 
	'!='		=> sub { !defined $_[1] || !$_[0]->isSameNode($_[1]) }, 
	'bool'		=> sub { 1 }, 
	fallback	=> 1;

# https://developer.mozilla.org/pl/docs/Web/API/Element/nodeType
use constant	ELEMENT_NODE					=> 1; 
use constant	ATTRIBUTE_NODE					=> 2;	# not supported
use constant	TEXT_NODE						=> 3; 
use constant	CDATA_SECTION_NODE				=> 4;	# not supported
use constant	ENTITY_REFERENCE_NODE			=> 5;	# not supported
use constant	ENTITY_NODE						=> 6;	# not supported
use constant	PROCESSING_INSTRUCTION_NODE		=> 7;	# not supported
use constant	COMMENT_NODE					=> 8; 
use constant	DOCUMENT_NODE					=> 9; 
use constant	DOCUMENT_TYPE_NODE				=> 10; 
use constant	DOCUMENT_FRAGMENT_NODE			=> 11; 
use constant	NOTATION_NODE					=> 12;	# not supported

sub __attrHashAccess {
	my $self = shift;
	my %h;
	tie %h, 'HTML5::DOM::Node::_AttrHashAccess', $self;
	return \%h;
}

1;

package HTML5::DOM::Node::_AttrHashAccess;
use strict;
use warnings;

sub TIEHASH {
	my $p = shift;
	bless \shift, $p
}

sub EXISTS {
	defined ${shift()}->attr(shift);
}

sub DELETE {
	${shift()}->removeAttr(shift);
}

sub FETCH {
	${shift()}->attr(shift);
}

sub STORE {
	${shift()}->attr(shift, shift);
}

1;
