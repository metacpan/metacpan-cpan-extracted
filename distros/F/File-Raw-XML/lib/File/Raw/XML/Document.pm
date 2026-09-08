package File::Raw::XML::Document;

use 5.010;
use strict;
use warnings;

use File::Raw::XML ();    # one dist, one bootstrap: the class lives in its bundle

1;

__END__

=head1 NAME

File::Raw::XML::Document - a parsed XML document

=head1 SYNOPSIS

    my $doc  = file_xml_decode($bytes, id_attrs => ['ID']);
    my $root = $doc->root;
    my $node = $doc->by_id(ID => $value);

=head1 DESCRIPTION

What L<File::Raw::XML/file_xml_decode> and the C<xml> plugin return. The
document owns the tree, and every node handed out keeps the document
alive for as long as the node exists; there is nothing the caller has to
do about lifetime.

A document is read-only. It is not shareable across interpreter threads:
a cloned copy answers every method with an error naming the class.

=head1 METHODS

=head2 root

The root element, a L<File::Raw::XML::Node>.

=head2 document

The document node, whose children are the top-level comments and
processing instructions with the root element among them. This is the
apex for a whole-document canonicalisation.

=head2 by_id($attr => $value)

The one element whose attribute named C<$attr> - by local name, in any
namespace - carries C<$value>, or C<undef>. Only the attribute names given
in C<id_attrs> at parse time are indexed, and two elements sharing a value
were refused at parse time, so this cannot be steered to a second
element.

=head2 c14n(%options)

The canonical form of the whole document, with the top-level comments and
processing instructions rendered under the document-level rules. The
options are those of L<File::Raw::XML::Node/c14n>.

=head2 to_string(%options)

    my $bytes = $doc->to_string(indent => 2);
    my $chars = $doc->to_string(encoding => 'perl');

The document as markup: bytes with no character flag, in the encoding
asked for, with the XML declaration and the recorded DOCTYPE by default.
The options:

=over 4

=item * C<declaration> - write the XML declaration; on for a document,
off for a node.

=item * C<encoding> - C<UTF-8>, the default; C<UTF-16> or C<UTF-16LE>
and C<UTF-16BE>, with a byte order mark; C<ISO-8859-1>; C<US-ASCII>. A
character the encoding cannot hold becomes a hexadecimal character
reference in text and attribute values, and is an error in a comment, a
processing instruction or a name, where no reference can stand. The one
exception is C<perl>, which returns a character string, for the caller
about to print to a handle with a layer, and whose declaration names no
encoding; C<file_spew> refuses it, since a file takes bytes.

=item * C<indent> - spaces per level, 0 for none. Indentation never
touches text: an element holding text that is not whitespace, or named
in C<preserve>, or under C<xml:space="preserve">, is written as it is,
and so is one holding whitespace-only text unless C<drop_ws> is set.

=item * C<preserve> - an arrayref of element local names written as they
are, whatever C<indent> says.

=item * C<drop_ws> - drop whitespace-only text under an indented element
so its children can be laid out. Off by default: it is the one option
that changes the document.

=item * C<empty_short> - C<< <a/> >> for an element with no children, the
default; off writes C<< <a></a> >>.

=item * C<quote> - the attribute quote, C<"> by default or C<'>; the
chosen quote is escaped inside values, the other is not.

=item * C<escape_all> - escape C<"> and C<'> in text as well as C<&>,
C<< < >> and C<< > >>.

=item * C<doctype> - write the recorded DOCTYPE back, with its
identifiers and its internal subset as written; on for a document.

=back

Entity references were resolved when the document was parsed and are not
written back: the text is the replacement text, and an internal subset
that declares an entity the text no longer uses is still well-formed.
CDATA sections are written where they were read. A text node's characters
are written as they are, so a carriage return that arrived as a character
reference leaves as one.

=head2 equals($other)

True when the two documents are equal as data: the same elements by
namespace name and local name with the same attributes as an unordered
set of namespace, local name and value, the same text, comments and
processing instructions, the same children in the same order. Prefixes,
CDATA boundaries, which attributes were defaulted, and offsets do not
count. Parsing what C<to_string> wrote gives a document equal to this
one.

=head2 version

The XML version the document declared, C<1.0> when it declared none.

=head2 standalone

True when the XML declaration said C<standalone="yes">, false otherwise.

=head2 doctype

C<undef> when the document has no document type declaration. Otherwise a
hashref with C<name>, the document type name; C<public_id> and
C<system_id>, each C<undef> when the declaration gave none; and
C<internal_subset>, the text between the brackets as written, C<undef>
when there were no brackets and the empty string when they were empty.
Only a parse under C<< profile => 'full' >> reads a document type
declaration; the default profile refuses every one.

What the internal subset declared has already been applied to the tree:
attribute defaults are present on every element that lacked them,
attribute values are normalised by their declared type, and internal
entity references have been replaced by their text. There is no entity
reference node.

=head1 BUILDING

A document made by L<File::Raw::XML/new_document> starts with only its
document node; a parsed document can be edited the same way. Nodes are
made here, detached, and put in place with the methods of
L<File::Raw::XML::Node/EDITING>.

=head2 new_element($ns, $name)

A new, detached element in the namespace C<$ns> (the empty string or
C<undef> for none) named C<$name>, which may be C<prefix:local>; a prefix
needs a namespace. When it is appended, a declaration for its prefix is
added where one is needed.

=head2 new_text($text), new_comment($text), new_pi($target, $data)

New, detached nodes of those kinds. A comment may not contain C<-->, a
processing instruction may not contain C<< ?> >> or be targeted at C<xml>.

=head2 import_node($node), import($node)

A detached deep copy, in this document, of a node from another document,
with the namespace bindings in scope at its source declared on the copy's
root so it means the same wherever it is appended. The source document is
untouched, and the copy outlives it.

C<import> is the same call under the name the family reads. Perl calls
C<import> on the class itself for every C<use> of it, so that call, which
carries no document and no node, is answered with nothing.

=head2 xpath($expression, %options)

    my @items = $doc->xpath('//item');
    my $n     = $doc->xpath('count(//item)');

L<File::Raw::XML::Node/xpath> with the document node as the context node,
which is the context an absolute expression starts from anyway.

=head2 errors

The validity constraints this document breaks, in document order, each a
message naming the constraint and the byte offset it was found at. Empty
unless the document was parsed with C<< validate => 'collect' >>, which
is the one mode that gathers them rather than dying at the first; with
C<< validate => 1 >> a violation is a refusal and there is no document to
ask.

    my $doc = file_xml_decode($bytes, profile => 'full', validate => 'collect');
    warn "$_\n" for $doc->errors;

=head1 SEE ALSO

L<File::Raw::XML>, L<File::Raw::XML::Node>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
