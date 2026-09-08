package File::Raw::XML::Node;

use 5.010;
use strict;
use warnings;

use File::Raw::XML ();    # one dist, one bootstrap: the class lives in its bundle

1;

__END__

=head1 NAME

File::Raw::XML::Node - a node of a parsed XML document

=head1 SYNOPSIS

    my $root = $doc->root;
    for my $child ($root->elements) {
        printf "%s in %s\n", $child->local, $child->ns;
    }
    my ($assertion) = $root->find($SAML_NS, 'Assertion');
    my $id           = $assertion->attr('ID');
    my $text         = $assertion->text;

=head1 DESCRIPTION

An element, a text run, a comment, a processing instruction or the
document node, distinguished by C<kind>. One class for every kind. A node
keeps its document alive for as long as it exists.

Names, attribute values and text come back as character strings. Where a
method takes a namespace, C<undef> means any namespace and the empty
string means no namespace.

=head1 METHODS

=head2 kind

An integer: the constants C<FRX_ELEMENT>, C<FRX_TEXT>, C<FRX_COMMENT>,
C<FRX_PI> and C<FRX_DOCUMENT>, exported by L<File::Raw::XML> under
C<:const>.

=head2 ns

The element's namespace URI, or the empty string when it has none.

=head2 prefix

The element's prefix as written, or the empty string.

=head2 local

The element's local name. For a processing instruction, its target.

=head2 name

The element's qualified name as written.

=head2 attr($local)

The value of the first attribute in document order with that local name,
in any namespace, or C<undef>.

=head2 attr_ns($ns, $local)

The value of the attribute with that namespace and local name, or
C<undef>. C<undef> for C<$ns> means any namespace; the empty string means
no namespace, which is what an unprefixed attribute has.

=head2 attrs

An arrayref of C<[uri, prefix, local, value]> in document order. Namespace
declarations are not attributes and do not appear.

=head2 children

Every child node, in order.

=head2 elements

The child elements only, in order.

=head2 find($ns, $local)

The direct child elements matching, in order.

=head2 descendants($ns, $local)

Every descendant element matching, in document order.

=head2 text

The text of the subtree, concatenated in document order; for a text,
comment or processing instruction node, its own value.

=head2 parent

The parent node, or C<undef> above the document node.

=head2 doc

The L<File::Raw::XML::Document> this node belongs to.

=head2 c14n(%options)

    my $bytes = $node->c14n(mode        => 'exclusive',   # or 'inclusive', 'inclusive-1.1'
                            comments    => 0,
                            prefix_list => ['xs', '#default'],
                            without     => [$signature_node]);

The canonical form of this node's subtree, as bytes with no character
flag, because a signature is over bytes. C<mode> is C<exclusive> by
default (Exclusive XML Canonicalization 1.0), or C<inclusive> (Canonical
XML 1.0) or C<inclusive-1.1> (Canonical XML 1.1). C<comments> renders
comments. C<prefix_list> is the C<InclusiveNamespaces PrefixList> of the
exclusive algorithm, with C<#default> naming the default namespace; the
inclusive modes ignore it. C<without> names subtrees left out of the
node set, which is the enveloped-signature transform; a node from another
document is an error. An unknown option is an error.

An element whose ancestors lie outside the node set inherits from them
what the chosen algorithm says: every C<xml:> attribute under Canonical
XML 1.0, C<xml:lang> and C<xml:space> plus a joined C<xml:base> under
1.1, and nothing under the exclusive algorithm.

=head2 to_string(%options)

This node's subtree as markup, with the options of
L<File::Raw::XML::Document/to_string>; the declaration and the DOCTYPE are
off unless asked for. An element written on its own carries the
namespace bindings in scope at it, after its own, so what is written
parses on its own and canonicalises as the element did in place.

=head2 base_uri

The base URI in force at this node: the document's own URI, which the
C<base> option gives and the plugin fills in from the file's path, with
every C<xml:base> from the outermost ancestor inwards resolved onto it,
as XML Base section 3 says. The empty string when the document has no URI
and no C<xml:base> is in force. Nothing is cached, so the answer follows
an edit.

=head2 lang

The language in force: the nearest C<xml:lang> at or above this node, or
C<undef> when none is, and C<undef> when the nearest one is empty, which
section 2.12 gives as the way to say the language is unknown.

=head2 space

C<preserve> when the nearest C<xml:space> at or above this node says so,
C<default> otherwise.

=head1 EDITING

Every method below changes the tree in place and returns the node it
acted on or created, so calls chain. A refusal dies naming the method
and the reason, and leaves the tree as it was. A node is never moved or
freed by an edit: a detached node is still a node of its document and
keeps the document alive as any node does. Every string written is
checked as XML characters under the document's version and every name as
a name, so a document that cannot be written cannot be built. Edits pay
in the document's memory, which is returned when the document is freed:
a long loop of edits on one document grows it, and C<to_string> followed
by a parse is the compaction.

Nodes are made by the document: L<File::Raw::XML::Document/new_element>
and its siblings. A node from another document is refused by every method
here; L<File::Raw::XML::Document/import> copies it across.

=head2 append($child)

C<$child>, which must have no parent, becomes this node's last child.
Under the document node only one element may stand, with comments and
processing instructions around it; text may not. When an element or
attribute in the appended subtree uses a prefix that is unbound where it
now stands, or bound to a different namespace than the node carries, a
declaration is added on the appended subtree's root; an unprefixed
element whose namespace is not the default in force there is given a
generated prefix (C<ns1>, C<ns2>, ...) and a declaration rather than a
default declaration, so no unprefixed name already present changes
meaning, and an unprefixed element with no namespace under a default
namespace gets C<xmlns=""> on the appended root.

=head2 insert_before($new)

C<$new> becomes the sibling before this node, under this node's parent,
with the namespace handling of C<append>.

=head2 detach

Takes this node and its subtree out of the tree. The node stays a valid
node of its document, and appending it somewhere else later is how a
subtree moves.

=head2 set_attr($ns, $name, $value)

Sets the attribute named by C<$name> in the namespace C<$ns> (the empty
string or C<undef> for none) to C<$value>, replacing one with the same
namespace and local name. A namespaced attribute needs a prefix, given as
C<prefix:local>; if the prefix is unbound or bound to another namespace
where the element stands, the element gets a declaration for it. An
attribute named in the document's C<id_attrs> updates the index, and a
value another element already carries is refused with nothing changed.

=head2 remove_attr($ns, $local)

Removes the attribute; nothing happens when there is none. The attributes
after it move up one place, so an attribute object taken earlier from an
XPath result, which holds its element and its position, then names the
attribute that moved into that place. Read attributes again after
removing one.

=head2 set_text($text)

On a text node, comment or processing instruction, replaces its value. On
an element, replaces every child with one text node holding C<$text>: it
does not append.

=head2 declare_ns($prefix, $uri)

Declares C<$prefix> (the empty string for the default namespace) bound to
C<$uri> on this element, replacing an existing declaration of the prefix,
under the rules the parser applies to C<xmlns> attributes.

=head2 set_name($ns, $name)

Renames the element, with the namespace handling of C<append> when it is
attached.

=head2 xpath($expression, %options)

    my @cells  = $row->xpath('td');
    my $count  = $row->xpath('count(td)');
    my ($sub)  = $node->xpath('//s:Subject', ns => { s => $SAML_NS });

Evaluates an XPath 1.0 expression with this node as the context node. In
list context a node-set is its members in document order; in scalar
context it is the first of them, or C<undef>. A string, a number and a
boolean each come back as one scalar.

The options are C<ns>, a hashref of prefix to namespace URI, which is the
only source of namespace URIs and without which a prefix in the
expression is an error; C<vars>, a hashref of values for the C<$name>
references in it; and C<max_expr_depth>. The expression is compiled for
this one call. L<File::Raw::XML::XPath> compiles once and evaluates many
times, and documents all of it.

=head1 SEE ALSO

L<File::Raw::XML>, L<File::Raw::XML::Document>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
