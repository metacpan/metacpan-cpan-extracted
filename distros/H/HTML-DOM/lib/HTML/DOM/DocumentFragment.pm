package HTML::DOM::DocumentFragment;

use strict;

use HTML::DOM::Node 'DOCUMENT_FRAGMENT_NODE';

our @ISA = 'HTML::DOM::Node';
our $VERSION = '0.058';

sub new {
	SUPER::new{shift} '~frag';
}

sub nodeName {'#document-fragment'}
*nodeType = \& DOCUMENT_FRAGMENT_NODE;

1;

__END__

=head1 NAME

HTML::DOM::DocumentFragment - A boring class that's rarely used.

=head1 VERSION

Version 0.058

=head1 DESCRIPTION

This class implements the DocumentFragment interface described in the W3C's
DOM spec. It inherits from L<HTML::DOM::Node>.

=head1 METHODS

=head2 HTML::DOM::DocumentFragment's Own Methods

=over 4

=item nodeName

This returns '#document-fragment'.

=item nodeType

This returns the constant HTML::DOM::Node::DOCUMENT_FRAGMENT_NODE.

=back

=head2 Inherited Methods

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

L<HTML::DOM::Node>
