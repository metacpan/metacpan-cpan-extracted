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
use constant {
	ELEMENT_NODE					=> 1, 
	ATTRIBUTE_NODE					=> 2,	# not supported
	TEXT_NODE						=> 3, 
	CDATA_SECTION_NODE				=> 4,	# not supported
	ENTITY_REFERENCE_NODE			=> 5,	# not supported
	ENTITY_NODE						=> 6,	# not supported
	PROCESSING_INSTRUCTION_NODE		=> 7,	# not supported
	COMMENT_NODE					=> 8, 
	DOCUMENT_NODE					=> 9, 
	DOCUMENT_TYPE_NODE				=> 10, 
	DOCUMENT_FRAGMENT_NODE			=> 11, 
	NOTATION_NODE					=> 12	# not supported
};

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
