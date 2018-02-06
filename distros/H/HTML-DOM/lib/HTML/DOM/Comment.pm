package HTML::DOM::Comment;

use warnings;
use strict;

use HTML::DOM::Node 'COMMENT_NODE';

require HTML::DOM::CharacterData;

our @ISA = 'HTML::DOM::CharacterData';
our $VERSION = '0.058';

sub new { # $_[1] contains the text
	$_[0]->SUPER::new('~comment', text => $_[1]);
}

# ---------------- NODE METHODS ---------- #

sub nodeName { '#comment' }
*nodeType = \&COMMENT_NODE;

# ---------------- OVERRIDDEN HTML::Element METHODS ---------- #

sub starttag { sprintf "<!--%s-->", shift->data }
sub endtag   { '' }

sub isa { # Lie to HTML::Element 4
 caller eq 'HTML::Element' && VERSION HTML::Element >= 4
  and $_[1] eq 'HTML::DOM::Element' and return 1;
 goto &{;can{$_[0]}"SUPER::isa"};
}

1
__END__


=head1 NAME

HTML::DOM::Text - A Perl class for representing text nodes in an HTML DOM tree

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $comment = $doc->createComment("yayayayayayaaya");

  $comment->data;              # 'yayayayayayaaya'
  $comment->length;            #  27
  $comment->substringData(13); # 'ya' 
  # etc.

=head1 DESCRIPTION

This class implements the Comment interface for L<HTML::DOM>. It inherits 
from
L<HTML::DOM::CharacterData>, which inherits from L<HTML::DOM::Node>.

=head1 METHODS

=head2 HTML::DOM::Comment's Own Methods

=over 4

=item $text->nodeName

This returns '#comment'.

=item $text->nodeType

This returns the constant HTML::DOM::Node::COMMENT_NODE.

=item $text->starttag

An overridden version of HTML::Element's method, which returns the return
value of C<data> surrounded by S<<< C<< <!-- --> >> >>>.

=item $text->endtag

An overridden version of HTML::Element's method, which returns an empty 
string.

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
