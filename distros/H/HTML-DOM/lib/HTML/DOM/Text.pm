package HTML::DOM::Text;

use warnings;
use strict;

use HTML::DOM::Node qw 'TEXT_NODE ATTRIBUTE_NODE';

require HTML::DOM::CharacterData;

our @ISA = 'HTML::DOM::CharacterData';
our $VERSION = '0.058';


=head1 NAME

HTML::DOM::Text - A Perl class for representing text nodes in an HTML DOM tree

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $text_node = $doc->createTextNode('the text goes here, I think');

  $text_node->data;              # 'the text goes here, I think'
  $text_node->length;            #  27
  $text_node->substringData(22); # 'think' 
  # etc.

=head1 DESCRIPTION

This class implements the Text interface for L<HTML::DOM>. It inherits from
L<HTML::DOM::CharacterData>, which inherits from L<HTML::DOM::Node>.

=head1 METHODS

=head2 HTML::DOM::Text's Own Methods

=over 4

=item $text->splitText($offset)

Splits the node into two separate sibling text nodes at the given offset.

=item $text->splitText16($offset)

This is just like C<splitText> except that the offset is given in UTF-16,
rather than Unicode.

=item $text->nodeName

This returns '#text'.

=item $text->nodeType

This returns the constant HTML::DOM::Node::TEXT_NODE.

=cut


sub new { # $_[1] contains the text
	$_[0]->SUPER::new('~text', text => "$_[1]");
}

sub splitText {
	my($self,$setoff) = @_;
	my $new_node = __PACKAGE__->new(
		# subtstringData takes care of throwing the right errors
		$self->substringData($setoff)
	);
	$self->deleteData($setoff);
	$self->postinsert($new_node);
	$new_node;
}

sub splitText16 { # UTF-16 version
	my($self,$setoff) = @_;
	my $new_node = __PACKAGE__->new(
		$self->substringData16($setoff)
	);
	$self->deleteData16(($setoff,));
	$self->postinsert($new_node);
	$new_node;
}

# ---------------- NODE METHODS ---------- #

sub nodeName { '#text' }
*nodeType = \&TEXT_NODE;


# --------- OVERRIDDEN EVENT TARGET METHOD -------- #

sub trigger_event {
	my ($n,$evnt) = (shift,shift);
	my $p = $n->parent;
	$n->SUPER::trigger_event(
		$evnt,
		$p && $p->nodeType == ATTRIBUTE_NODE
		  ?(
			DOMCharacterDataModified_default =>sub {
				$_[0]->target->parent->_text_node_modified(
					$_[0]
				)
			},
		  ):(),
		@_,
	);
}

1
__END__


=back

=head2 Inherited Methods

These are inherited from L<HTML::DOM::CharacterData>:

=over 4

=item data

=item length

=item length16

=item substringData

=item substringData16

=item appendData

=item insertData

=item insertData16

=item deleteData

=item deleteData16

=item replaceData

=item replaceData16

=item nodeValue

=back

These are inherited from L<HTML::DOM::Node>:

=over 4

=item nodeValue

=item parentNode

=item childNodes

=item firstChild

=item lastChild

=item previousSibling

=item nextSibling

=item attributes

=item ownerDocument

=item insertBefore

=item replaceChild

=item removeChild

=item appendChild

=item hasChildNodes

=item cloneNode

=back

=cut

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::CharacterData>

L<HTML::DOM::Node>
