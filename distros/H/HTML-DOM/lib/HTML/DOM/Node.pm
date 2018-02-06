package HTML::DOM::Node;

our $VERSION = '0.058';


use strict;
use warnings;

use constant {
	ELEMENT_NODE                => 1,
	ATTRIBUTE_NODE              => 2,
	TEXT_NODE                   => 3,
	CDATA_SECTION_NODE          => 4,
	ENTITY_REFERENCE_NODE       => 5,
	ENTITY_NODE                 => 6,
	PROCESSING_INSTRUCTION_NODE => 7,
	COMMENT_NODE                => 8,
	DOCUMENT_NODE               => 9,
	DOCUMENT_TYPE_NODE          => 10,
	DOCUMENT_FRAGMENT_NODE      => 11,
	NOTATION_NODE               => 12,
};

use Exporter 5.57 'import';
use HTML::DOM::Event;
use HTML::DOM::Exception qw'NO_MODIFICATION_ALLOWED_ERR NOT_FOUND_ERR
                               HIERARCHY_REQUEST_ERR 
                                 UNSPECIFIED_EVENT_TYPE_ERR';
use Scalar::Util qw'refaddr weaken blessed';

require HTML::DOM::EventTarget;
require HTML::DOM::Implementation;
require HTML::DOM::NodeList;
require HTML::DOM::_Element;

our @ISA =('HTML::DOM::_Element', # No, a node isn't an HTML element,
 'HTML::DOM::EventTarget');    # but HTML::DOM::_Element (forked from
                             # HTML::Element) has some nice tree-handling
                            # methods (and, after all, TreeBuilder's
                            # pseudo-elements aren't elements either).

our @EXPORT_OK = qw'
	ELEMENT_NODE               
	ATTRIBUTE_NODE             
	TEXT_NODE                  
	CDATA_SECTION_NODE         
	ENTITY_REFERENCE_NODE      
	ENTITY_NODE                
	PROCESSING_INSTRUCTION_NODE
	COMMENT_NODE               
	DOCUMENT_NODE              
	DOCUMENT_TYPE_NODE         
	DOCUMENT_FRAGMENT_NODE     
	NOTATION_NODE              
';
our %EXPORT_TAGS = (all => \@EXPORT_OK);



=head1 NAME

HTML::DOM::Node - A Perl class for representing the nodes of an HTML DOM tree

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM::Node ':all'; # constants
  use HTML::DOM;
  $doc = HTML::DOM->new;
  $doc->isa('HTML::DOM::Node'); # true
  $doc->nodeType == DOCUMENT_NODE; # true

  $doc->firstChild;
  $doc->childNodes;
  # etc

=head1 DESCRIPTION

This is the base class for all nodes in an HTML::DOM tree. (See
L<HTML::DOM/CLASSES AND DOM INTERFACES>.) It implements the Node
interface, and, indirectly, the EventTarget interface (see 
L<HTML::DOM::EventTarget>.

=head1 METHODS

=head2 Attributes

The following DOM attributes are supported:

=over 4

=item nodeName

=item nodeType

These two are implemented not by HTML::DOM::Node itself, but by its
subclasses.

=item nodeValue

=item parentNode

=item childNodes

=item firstChild

=item lastChild

=item previousSibling

=item nextSibling

=item attributes

=item ownerDocument

=item namespaceURI

=item prefix

=item localName

Those last three always return nothing.

=back

There is also a C<_set_ownerDocument> method, which you probably do not
need to know about.

=cut

# ----------- ATTRIBUTE METHODS ------------- #

# sub nodeName {} # every subclass overrides this
# sub nodeType {} # likewise

sub nodeValue {
	if(@_ > 1) {
		die new HTML::DOM::Exception
			NO_MODIFICATION_ALLOWED_ERR,
			'Read-only node';# ~~~ only when the node is
		                                 #     readonly
	}
	return; # empty list
}

sub parentNode {
	my $p = $_[0]->parent;
	defined $p ? $p :()
}

sub childNodes {
	wantarray ? $_[0]->content_list :
		new HTML::DOM::NodeList $_[0]->content_array_ref;
}

sub firstChild {
	($_[0]->content_list)[0];
}

sub lastChild {
	($_[0]->content_list)[-1];
}

sub previousSibling {
	my $sib = scalar $_[0]->left;
	defined $sib ? $sib : ();
}

sub nextSibling {
	my $sib = scalar $_[0]->right;
	defined $sib ? $sib : ();
}

sub attributes {} # null for most nodes; overridden by Element

sub ownerDocument {
	my $self = shift;
	$$self{_HTML_DOM_Node_owner} || do {
		my $root = $self->root;
		# ~~~ I’m not sure this logic is right. I need to revisit
		#     this. Do we ever have a case in which ->root returns
		#     the wrong value? If so, can we guarantee that the
		#     ‘root’ has its _HTML_DOM_Node_owner attribute set?
		$$self{_HTML_DOM_Node_owner} = 
			$$root{_HTML_DOM_Node_owner} || $root;
		weaken $$self{_HTML_DOM_Node_owner};
		$$self{_HTML_DOM_Node_owner}
	};
}

sub _set_ownerDocument {
	$_[0]{_HTML_DOM_Node_owner} = $_[1];
	weaken $_[0]{_HTML_DOM_Node_owner};
}

*prefix = *localName = *namespaceURI = *attributes;


=head2 Other Methods

See the DOM spec. for descriptions of most of these. The first four
automatically trigger mutation events. (See L<HTML::DOM::Event::Mutation>.)

=over 4

=item insertBefore

=item replaceChild

=item removeChild

=item appendChild

=item hasChildNodes

=item cloneNode

=item normalize

=item hasAttributes

=item isSupported

=cut

# ----------- METHOD METHODS ------------- #

sub insertBefore {
	# ~~~ NO_MODIFICATION_ALLOWED_ERR is meant to be raised if the
	#     node is read-only.
	# ~~~ HIERARCHY_REQUEST_ERR is also supposed to be raised if the
	#     node type does not allow children of $new_node's type.

	my($self,$new_node,$before) = @_;

	$self->is_inside($new_node) and
		die new HTML::DOM::Exception HIERARCHY_REQUEST_ERR,
		'A node cannot be inserted into one of its descendants';

	my $doc = $self->ownerDocument || $self;

	my $index;
	my @kids = $self->content_list;
	if($before) { FIND_INDEX: {
		for (0..$#kids) {
			$kids[$_] == $before 
				and $index = $_, last FIND_INDEX;
		}
		die new HTML::DOM::Exception NOT_FOUND_ERR,
		'insertBefore\'s 2nd argument is not a child of this node';
	}}
	else {
		$index = @kids;
	}

#$new_node->can('parent') or warn JE::Code::add_line_number("cant parent");
	my $old_parent = $new_node->parent;
	$old_parent and $new_node->trigger_event('DOMNodeRemoved',
		rel_node => $old_parent);
	my $was_inside_doc = $new_node->is_inside($doc);
	if($was_inside_doc) {
		$_->trigger_event('DOMNodeRemovedFromDocument')
		  for $new_node, $new_node->descendants;
	}

	$self->splice_content($index, 0, my @nodes =
		$new_node->isa('HTML::DOM::DocumentFragment')
		? $new_node->childNodes
		: $new_node
	);
	$_->_set_ownerDocument($doc) for @nodes;

	$new_node->trigger_event('DOMNodeInserted', rel_node => $self);
	if($self->is_inside($doc)) {
		for($new_node, $new_node->descendants) {
			if(
			 !$was_inside_doc
			 and my $sub = $doc->elem_handler(lc $_->tag)
			) {
				&$sub($doc,$_)
			}
			$_->trigger_event('DOMNodeInsertedIntoDocument')
		}
	}
	$_->trigger_event('DOMSubtreeModified')
	  for _nearest_common_parent($old_parent, $self);

	$doc->_modified;

	$new_node;
}

sub replaceChild {
	# ~~~ NO_MODIFICATION_ALLOWED_ERR is meant to be raised if the
	#     node is read-only.
	# ~~~ HIERARCHY_REQUEST_ERR is also supposed to be raised if the
	#     node type does not allow children of $new_node's type.

	my($self,$new_node,$old_node) = @_;

	$self->is_inside($new_node) and
		die new HTML::DOM::Exception HIERARCHY_REQUEST_ERR,
		'A node cannot be inserted into one of its descendants';

	my $doc = $self->ownerDocument || $self;

	no warnings 'uninitialized';
	$self == $old_node->parent or
		die new HTML::DOM::Exception NOT_FOUND_ERR,
		'replaceChild\'s 2nd argument is not a child of this node';

	$old_node->trigger_event('DOMNodeRemoved',
		rel_node => $self);
	my $in_doc = $self->is_inside($doc);
	if($in_doc) {
		$_->trigger_event('DOMNodeRemovedFromDocument')
		  for $old_node, $old_node->descendants;
	}
	my $old_parent = $new_node->parent;
	$old_parent and $new_node->trigger_event('DOMNodeRemoved',
		rel_node => $old_parent);
	if($new_node->is_inside($doc) && !$new_node->is_inside($old_node)){
		$_->trigger_event('DOMNodeRemovedFromDocument')
		  for $new_node, $new_node->descendants;
	}

	# If the owner is not set explicitly inside the node, it will lose
	# its owner.  The ownerDocument method  sets  it  if  it  is  not
	# already set.
	$old_node->ownerDocument;

	my $ret = $old_node->replace_with(
		my @nodes
		 = $new_node->isa('HTML::DOM::DocumentFragment')
		 ? $new_node->childNodes
		 : $new_node
	);
	$_->_set_ownerDocument($doc) for @nodes;

	$new_node->trigger_event('DOMNodeInserted', rel_node => $self);
	if($in_doc) {
		for($new_node, $new_node->descendants) {
			if(my $sub = $doc->elem_handler(lc $_->tag)) {
				&$sub($doc,$_)
			}
			$_->trigger_event('DOMNodeInsertedIntoDocument')
		}
	}
	$_->trigger_event('DOMSubtreeModified')
	  for _nearest_common_parent($old_parent, $self);

	$doc->_modified;

	$ret;
}

sub removeChild {
	# ~~~ NO_MODIFICATION_ALLOWED_ERR is meant to be raised if the
	#     node is read-only.

	my($self,$child) = @_;

	no warnings 'uninitialized';
	$self == $child->parent or
		die new HTML::DOM::Exception NOT_FOUND_ERR,
		'removeChild\'s argument is not a child of this node';

	# If the owner is not set explicitly inside the node, it will lose
	# its owner.  The ownerDocument method  sets  it  if  it  is  not
	# already set.
	my $doc = $child->ownerDocument;

	$child->trigger_event('DOMNodeRemoved',
		rel_node => $self);
	if($child->is_inside($doc)) {
		$_->trigger_event('DOMNodeRemovedFromDocument')
		  for $child, $child->descendants;
	}

	$child->detach;

	$self->trigger_event('DOMSubtreeModified');

	{($self->ownerDocument||next)->_modified;}

	$child;
}

sub appendChild {
	# ~~~ NO_MODIFICATION_ALLOWED_ERR is meant to be raised if the
	#     node is read-only.
	# ~~~ HIERARCHY_REQUEST_ERR is also supposed to be raised if the
	#     node type does not allow children of $new_node's type.

	my($self,$new_node) = @_;

	$self->is_inside($new_node) and
		die new HTML::DOM::Exception HIERARCHY_REQUEST_ERR,
		'A node cannot be inserted into one of its descendants';

	my $doc = $self->ownerDocument || $self;

	my $old_parent = $new_node->parent;
	$old_parent and $new_node->trigger_event('DOMNodeRemoved',
		rel_node => $old_parent);
	my $was_inside_doc = $new_node->is_inside($doc);
	if($was_inside_doc) {
		$_->trigger_event('DOMNodeRemovedFromDocument')
		  for $new_node, $new_node->descendants;
	}

	$self->push_content(
	 my @nodes = $new_node->isa('HTML::DOM::DocumentFragment')
	             ? $new_node->childNodes
	             : $new_node
	);
	$_->_set_ownerDocument($doc) for @nodes;

	$new_node->trigger_event('DOMNodeInserted', rel_node => $self);
	if($self->is_inside($doc)) {
		for($new_node, $new_node->descendants) {
			if(
			 !$was_inside_doc
			 and my $sub = $doc->elem_handler(lc $_->tag)
			) {
				&$sub($doc,$_)
			}
			$_->trigger_event('DOMNodeInsertedIntoDocument')
		}
	}
	$_->trigger_event('DOMSubtreeModified')
	  for _nearest_common_parent($old_parent, $self);

	$doc->_modified;

	$new_node;
}

# This is used to determine who gets a DOMSubtreeModified event. Despite
# its name, it may choose one of the two nodes passed to it if one is the
# parent of the other. If neither of the nodes is in the same tree, they
# are both returned. The first arg may be undef, in which case the 2nd
# is returned.
sub _nearest_common_parent {
	my ($node1,$node2)=@_;
	!defined $node1 and return $node2;
	$node1->root != $node2->root and return $node1, $node2;
	my $addr1 = $node1->address;
	my $addr2 = $node2->address;
	while(substr $addr1, 0, length $addr2, ne $addr2 and
	      substr $addr2, 0, length $addr1, ne $addr1) {
		s/\.[^.]*\z// for $addr1, $addr2;
	}
	$node2->address(
	  length $addr1 < length $addr2 ? $addr1 : $addr2
	)
}

sub hasChildNodes {
	!!$_[0]->content_list
}

sub cloneNode {
	my($self,$deep) = @_;
	if($deep) {
		(my $clown = $self->clone)
		  ->_set_ownerDocument($self->ownerDocument);
		$clown;
	}
	else {
		# ~~~ Do I need to reweaken any attributes?
		bless +(my $clone = { %$self }), ref $self;
		$clone->_set_ownerDocument($self->ownerDocument);
		delete $clone->{$_} for qw/ _parent _content /;
		$clone
	}
}

sub normalize {
	my @pile = my $self = shift;
	while(@pile) {
		if($pile[0]{_tag} eq '~text') {
			if($pile[0]{text} eq '') {
				shift(@pile)->detach, next
			}
			_:{while((my $next = $pile[0]->nextSibling||next _)
			       ->{_tag} eq '~text') {
				$pile[0]{text}.=$next->{text};
				$next->detach;
			}}
			shift @pile;
		}
		else {
			unshift @pile, @{(shift@pile)->{'_content'}||[]};
		}
	}
	return
}

sub hasAttributes {
	(shift->attributes||return 0)->length
}

sub isSupported {
	my $self = shift;
	$HTML::DOM::Implementation::it->hasFeature(@_)
}

# ----------- EVENT STUFF ------------- #

=item trigger_event

This overrides L<HTML::DOM::EventTarget>'s (non-DOM) method of the same 
name, so that
the document's default event handler is called.

=cut

sub trigger_event { # non-DOM method
	my ($n,$evnt) = (shift,shift);
	my $doc = $n->ownerDocument||$n;
	$n->SUPER::trigger_event(
		$evnt,
		default => $doc->default_event_handler,
		view => scalar $doc->defaultView,
		@_,
	);
}

=item as_text

=item as_HTML

These two (non-DOM) methods of L<HTML::Element> are overridden, so that
they work correctly with comment and text nodes.

=cut

sub as_text{
	(my $clone = shift->clone)->deobjectify_text;
	$clone->SUPER::as_text(@_);
}

sub as_HTML{
	(my $clone = shift->clone)->deobjectify_text;
	$clone->SUPER::as_HTML(@_);
}

sub push_content {
	my $self  = shift; 
	@_ or return $self;
	my $count = ()=$self->content_list;
	$self->SUPER::push_content(@_);
	my $ary = $self->{_content};
	ref and weaken $_->{_parent} for @$ary[$count-@$ary..-1];
	$self
}

sub unshift_content {
	my $self  = shift; 
	my $count = ()=$self->content_list;
	$self->SUPER::unshift_content(@_);
	my $ary = $self->{_content};
	ref and weaken $_->{_parent} for @$ary[0..$#$ary-$count];
	$self
}

sub splice_content {
	my($self,$start,$deleted) = (shift,@_); 
	my $orig_count = ()=$self->content_list;
	$self->SUPER::splice_content(@_);
	my $ary = $self->{_content};

	# orig_length - deleted_items + x = final_length,
	# where x is the number of items added (to be weakened), so
	# x = final_length - orig_length + deleted_items.
	# x needs to be adjusted so it is an ending offset, so we use
	# $#$ary instead of the final length (@$ary) and add $start
	ref and weaken $_->{_parent}
		for @$ary[$start..$#$ary-$orig_count+$deleted+$start];

	$self
}

sub clone {
	my $self = shift;
	my $clone = $self->SUPER::clone;
	for ($clone->content_list) {
		ref or next;
		weaken $_->{_parent};
	}
	$clone;
}

sub replace_with {
	my $self = shift;
	$self->SUPER::replace_with(@_);
	for(@_) {
		no warnings;
		ref and weaken $_->{_parent};
	}
	$self;
}


=back

=cut

1;
__END__





=head1 EXPORTS

The following node type constants are exportable:

=over 4

=item ELEMENT_NODE (1)

=item ATTRIBUTE_NODE (2)

=item TEXT_NODE (3)

=item CDATA_SECTION_NODE (4)

=item ENTITY_REFERENCE_NODE (5)

=item ENTITY_NODE (6)

=item PROCESSING_INSTRUCTION_NODE (7)

=item COMMENT_NODE (8)

=item DOCUMENT_NODE (9)

=item DOCUMENT_TYPE_NODE (10)

=item DOCUMENT_FRAGMENT_NODE (11)

=item NOTATION_NODE (12)

=back

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::EventTarget>
