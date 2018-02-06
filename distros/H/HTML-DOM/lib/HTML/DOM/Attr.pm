package HTML::DOM::Attr;

use warnings;

# attribute constants (array elems)
BEGIN{
 my $x;
 %constants
  = map +($_=>$x++), qw[
     _doc _elem _name _val _list _styl
    ]
}
use constant 1.03 \%constants;
# after compilation:
delete @{__PACKAGE__."::"}{ keys %constants, 'constants' };

use strict;

# The internal fields are:
#  _doc   # owner document
#  _elem  # owner element
#  _name
#  _val   # actually contains an array with one element, so
#  _list  # node list  # that nodelists can work efficiently
#  _styl  # style obj


use overload fallback => 1,
	'""' => sub { shift->value },
	'bool' => sub{1};

use HTML::DOM::Exception qw'NOT_FOUND_ERR NO_MODIFICATION_ALLOWED_ERR
                            HIERARCHY_REQUEST_ERR ';
use HTML::DOM::Node 'ATTRIBUTE_NODE';
use Scalar::Util qw'weaken blessed refaddr';

require HTML::DOM::EventTarget;
require HTML::DOM::NodeList;

our @ISA = 'HTML::DOM::EventTarget';

our $VERSION = '0.058';

# -------- NON-DOM AND PRIVATE METHODS -------- #

sub new { # @_[1..2] contains the nayme & vallew
# ~~~ INVALID_CHARACTER_ERR is meant to be raised if the specified name contains an invalid character.
	my @self;
	@self[_name,_val] = ($_[1],[defined$_[2]?$_[2]:'']);
	                        # value should be an empty
	bless \@self, shift;         # string, not undef
}



sub _set_ownerDocument {
	weaken ($_[0][_doc] = $_[1]);
}

sub _element { # This is like ownerElement, except that it lets you set it.
	if(@_ > 1) {
		my $old = $_[0][_elem];
		weaken ($_[0][_elem] = $_[1]);
		return $old
	}
	$_[0][_elem];
}

sub DOES {
	return !0 if $_[1] eq 'HTML::DOM::Node';
	eval { shift->SUPER::DOES(@_) } || !1
}

sub _value { # returns the value as it is, whether it is a node or scalar
	$_[0][_val][0];
}

sub _val_as_node { # turns the attribute's value into a text node if it is
                   # not one already and returns it
	my $val = $_[0][_val][0];
	defined blessed $val && $val->isa('HTML::DOM::Text')
	    ? $val
	    : do {
	        my $val = $_[0][_val][0] =
	          $_[0]->ownerDocument->createTextNode(
		    $_[0][_styl] ? $_[0][_styl]->cssText : $val
		  );
	        weaken($val->{_parent}=($_[0]));
	        $val
	      }
}

# ~~~ Should I make this public? This actually allows a style object to be
#     attached to any attr node, not just a style attr. Is this useful?
#     (Actually, it would be problematic for event attributes, unless some-
#     one really wants to run css code :-)
sub style {
	my $self = shift;
	$self->[_styl] ||= do{
		require CSS::DOM::Style,
		my $ret = CSS::DOM::Style::parse(my $val = $self->value);
		$ret->modification_handler(my $cref = sub {
			if(ref(my $text = $self->_value)) {
				# We can’t use ->data here because it will
				# trigger chardatamodified  (see sub new),
				# which sets cssText, which calls this.
				$text->attr('text', shift->cssText)
			}
			$self->_modified;
		});
		weaken $self;
		my $css_code = $ret->cssText;
		if($val ne $css_code) { &$cref($ret) }
		$ret;
	};
}

sub _modified {
	my $self = shift;
	my ($old_val,$new) = @_;
	my $element = $self->[_elem] || return;
	defined $new or $new = value $self;
	if ($self->[_name] =~ /^on(.*)/is
	    and my $listener_maker = $self->ownerDocument
			->event_attr_handler
	) {
		my $eavesdropper = &$listener_maker(
			$element, my $evt_name = lc $1, $new
		);
		defined $eavesdropper
			and $element->event_handler(
				$evt_name, $eavesdropper
			);
	}

	$element->trigger_event(
		DOMAttrModified =>
		attr_name => $self->[_name],
		attr_change_type => 1,
		prev_value => defined $old_val?$old_val:$new,
		new_value  => $new,
		rel_node => $self,
	)
}

sub _text_node_modified {
	my $self = shift;
	if($$self[_styl]) {
		$$self[_styl]->cssText(shift->newValue)
	}
	else {
		$self->_modified($_[0]->prevValue,$_[0]->newValue);
	}
}


# ----------- ATTR-ONLY METHODS ---------- #

sub name {
	$_[0][_name];
}

sub value {
	if(my $style = $_[0][_styl]) {
		shift;
		return $style->cssText(@_);
	}
	if(@_ > 1){
		my $old = $_[0][_val][0];
		if(ref $old) {
			$old = $old->data;
			$_[0][_val][0]->data($_[1]);
			# ~~~ Can we combine these two statements by using data’s retval?
		}
		elsif((my $new_val = $_[0][_val][0] = "$_[1]") ne $old) {
			if($_[0]->get_event_listeners(	
				'DOMCharacterDataModified'
			)) {
				$_[0]->firstChild->trigger_event(
					'DOMCharacterDataModified',
					prev_value => $old,
					new_value => $new_val
				)
			}
			else {
				$_[0]->_modified($old,$new_val);
			}
		}
		return $old;
	}
	my $val = $_[0][_val][0];
	ref $val ? $val->data : $val;
}

sub specified {
	my $attr=shift;
	($$attr[_elem]||return 1)->_attr_specified($$attr[_name]);
}

sub ownerElement { # ~~~ If the attr is detached, is _element currently
                   #     erased as it should be?
	shift->_element || ()
}

# ------------------ NODE METHODS ------------ #

*nodeName = \&name;
*nodeValue = \&value;
*nodeType =\&ATTRIBUTE_NODE;

# These all return null
*previousSibling = *nextSibling = *attributes = *parentNode = *prefix =
*namespaceURI = *localName = *normalize
 = sub {};

sub childNodes {
	wantarray ? $_[0]->_val_as_node :(
		$_[0]->_val_as_node,
		$_[0][_list] ||= HTML::DOM::NodeList->new($_[0][_val])
	);
}

*firstChild = *lastChild = \&_val_as_node;

sub ownerDocument { $_[0][_doc] }

sub insertBefore {
	die HTML::DOM::Exception->new(NO_MODIFICATION_ALLOWED_ERR,
	    'The list of child nodes of an attribute cannot be modified');
}

sub replaceChild {
	my($self,$new_node,$old_node) = @_;
	my $val = $self->_value;
	die HTML::DOM::Exception->new(NOT_FOUND_ERR,
	'The node passed to replaceChild is not a child of this attribute')
		if !ref $val || $old_node != $val;
	if(defined blessed $new_node and
	   isa $new_node 'HTML::DOM::DocumentFragment') {
		(($new_node) = $new_node->childNodes) != 1 and
		die HTML::DOM::Exception->new(HIERARCHY_REQUEST_ERR,
			'The document fragment passed to replaceChild ' .
			'does not have exactly one child node');
	}
	die HTML::DOM::Exception->new(HIERARCHY_REQUEST_ERR,
		'The node passed to replaceChild is not a text node')
		if !defined blessed $new_node ||
			!$new_node->isa('HTML::DOM::Text');

	$old_node->trigger_event('DOMNodeRemoved',
		rel_node => $self);
	my $in_doc = $self->[_elem] && $self->[_elem]->is_inside(
		$self->[_doc]
	);
	if($in_doc) {
		$old_node->trigger_event('DOMNodeRemovedFromDocument')
	}
	my $old_parent = $new_node->parent;
	$old_parent and $new_node->trigger_event('DOMNodeRemoved',
		rel_node => $old_parent);
	if($new_node->is_inside($self->[_doc])){
		$new_node->trigger_event('DOMNodeRemovedFromDocument')
	}
	else {
		# Even if it’s already the same document, it’s actually
		# quicker just to set it than to check first.
		$new_node->_set_ownerDocument( $self->[_doc] );
	}

	($_[0][_val][0] = $new_node)->detach;
	weaken($new_node->{_parent}=($self));
	$old_node->parent(undef);

	$new_node->trigger_event('DOMNodeInserted', rel_node => $self);
	if($in_doc) {
		$new_node->trigger_event('DOMNodeInsertedIntoDocument')
	}
	$_->trigger_event('DOMSubtreeModified')
	  for grep defined, $old_parent, $self;
	$self->_modified($old_node->data, $new_node->data);

	$old_node;
}


*removeChild = *appendChild = \&insertBefore;

sub hasChildNodes { 1 }

sub cloneNode {
	# ~~~ The spec.  is not clear as to what should be done with  an
	#     Attr’s child node when it is cloned shallowly. I’m here fol-
	#     lowing the behaviour of Safari and Firefox, which both ignore
	#     the ‘deep’ option.
	my($self,$deep) = @_;
	my $clone = bless [@$self], ref $self;
	weaken $$clone[_doc];
	delete $$clone[$_] for _elem, _list;
	$$clone[_val] = ["$$clone[_val][0]"]; # copy the single-elem array
	                                     # that ->[_val] contains,
	                                   # flattening it in order effec-
	                                # tively to clone it.
	$clone;
}

sub hasAttributes { !1 }

sub isSupported {
	my $self = shift;
	return !1 if $_[0] =~ /events\z/i;
	$HTML::DOM::Implementation::it->hasFeature(@_)
}


1

__END__

=head1 NAME

HTML::DOM::Attr - A Perl class for representing attribute nodes in an HTML DOM tree

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $attr = $doc->createAttribute('href');
  $attr->nodeValue('http://localhost/');
  $elem = $doc->createElement('a');
  $elem->setAttributeNode($attr);
  
  $attr->nodeName;  # href
  $attr->nodeValue; # http://...
  
  $attr->firstChild; # a text node
  
  $attr->ownerElement; # returns $elem

=head1 DESCRIPTION

This class is used for attribute nodes in an HTML::DOM tree. It implements 
the Node and 
Attr DOM interfaces and inherits from L<HTML::DOM::EventTarget>. An 
attribute node stringifies to its value. As a
boolean it is true, even if its value is false.

=head1 METHODS

=head2 Attributes

The following DOM attributes are supported:

=over 4

=item nodeName

=item name

These both return the name of the attribute.

=item nodeType

Returns the constant C<HTML::DOM::Node::ATTRIBUTE_NODE>.

=item nodeValue

=item value

These both return the attribute's value, setting it if there is an 
argument.

=item specified

Returns true if the attribute was specified explicitly in
the source code or was explicitly added to the tree.

=item parentNode

=item previousSibling

=item nextSibling

=item attributes

=item namespaceURI

=item prefix

=item localName

All of these simply return an empty list.

=item childNodes

In scalar context, this returns a node list object with one text node in
it. In list context it returns a list containing just that text node.

=item firstChild

=item lastChild

These both return the attribute's text node.

=item ownerDocument

Returns the document to which the attribute node belongs.

=item ownerElement

Returns the element to which the attribute belongs.

=back

=head2 Other Methods

=over 4

=item insertBefore

=item removeChild

=item appendChild

These three just throw exceptions.

=item replaceChild

If the first argument is a text node and the second is the attribute node's
own text node, then the latter is replaced with the former. This throws an
exception otherwise.

=item hasChildNodes

Returns true.

=item cloneNode

Returns a clone of the attribute.

=item normalize

Does nothing.

=item hasAttributes

Returns false.

=item isSupported

Does the same thing as L<HTML::DOM::Implementation>'s
L<hasFeature|HTML::DOM::Implementation/hasFeature> method.

=back

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::Node>

L<HTML::DOM::Element>

L<HTML::DOM::EventTarget>
