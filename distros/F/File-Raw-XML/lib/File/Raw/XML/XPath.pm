package File::Raw::XML::XPath;

use 5.010;
use strict;
use warnings;

use File::Raw::XML ();    # one dist, one bootstrap: the class lives in its bundle

1;

__END__

=head1 NAME

File::Raw::XML::XPath - XPath 1.0 over a parsed document

=head1 SYNOPSIS

    use File::Raw::XML qw(file_xml_decode);
    use File::Raw::XML::XPath;

    my $doc = file_xml_decode($bytes, id_attrs => ['ID']);

    my $xp = File::Raw::XML::XPath->new(
        '//s:Assertion[@ID = $id]/s:Subject',
        ns   => { s => 'urn:oasis:names:tc:SAML:2.0:assertion' },
        vars => { id => $value },
    );
    my @nodes = $xp->find($doc->document);
    my $first = $xp->find($doc->root);

    my $count = $doc->root->xpath('count(//item)');

=head1 DESCRIPTION

XPath Version 1.0 (W3C Recommendation, 16 November 1999) in full: the
four value types, the thirteen axes, the 27 core functions, and the
comparison rules of section 3.4. XPath 2.0 and later are a different data
model and are not here.

An expression is compiled once and evaluated as many times as you like,
against as many documents as you like. A compiled expression holds no
document and keeps none alive.

=head1 METHODS

=head2 new($expression, %options)

Compiles the expression, or dies with a message naming the character
offset in the expression the refusal was found at. The options are:

=over 4

=item * C<ns> - a hashref of prefix to namespace URI. It is the only
source of namespace URIs: a prefix in the expression that is not a key
here is a compile error, and the document's own declarations are never
consulted, so an expression means the same thing wherever it is
evaluated. The C<xml> prefix is bound without being named.

=item * C<vars> - a hashref of variable name to value, for the C<$name>
references in the expression. Every variable the expression names must
have a value here, and one that does not is named in the refusal. A value
is bound as a number when the scalar is a number and as a string
otherwise; a reference is an error.

=item * C<max_expr_depth> - how deeply the expression may nest, 64 by
default. Nesting is counted over the compiled form, so a long chain of
C<and> or C<or> counts as deeply as it is long.

=back

An unprefixed name test matches names in no namespace, which is section
2.3: a qualified name without a prefix expands with a null namespace URI,
never with the default one. To match a name in a namespace, give the
prefix a binding and use it, whatever prefix the document happens to
write.

=head2 find($context)

Evaluates against C<$context>, which is a L<File::Raw::XML::Document> -
the context node is then the document node - or any
L<File::Raw::XML::Node>. What comes back depends on the type of the
result:

=over 4

=item * A node-set, in list context, is the list of its members in
document order, with no duplicates. In scalar context it is the first
member in document order, or C<undef> when the set is empty.

=item * A string is a character string, a number is a number, and a
boolean is 1 or 0.

=back

An element in a node-set is a L<File::Raw::XML::Node>. An attribute is a
L<File::Raw::XML::Attr> and a namespace node is a
L<File::Raw::XML::Namespace>, because neither is a node of the tree. All
three keep the document alive for as long as they exist.

=head1 THE PER-CALL FORM

    my @nodes = $node->xpath($expression, %options);
    my @nodes = $doc->xpath($expression, %options);

The same thing with the compilation done for one call and thrown away.
The options are those of L</new>. Use it where the expression is written
once; use a compiled object where one expression is evaluated many times.

=head1 NOTES

C<//a[1]> is not the first C<a> in the document. C<//> is
C<< /descendant-or-self::node()/ >>, so the predicate belongs to the
C<child::a> step and selects the first C<a> child of each element that
has one. C<(//a)[1]> is the first in the document.

Numbers are IEEE doubles with the specification's semantics: C<1 div 0>
is C<Infinity>, C<0 div 0> is C<NaN>, and C<string()> of a number never
uses exponent notation and never shows a trailing zero.

C<id()> answers over whatever index the document has: the attribute names
given in C<id_attrs>, or the ID attributes its document type declaration
named when it was parsed with C<< validate => 1 >>, or C<xml:id> under
C<< profile => 'full' >>. A document with none of those has an empty
index, and C<id()> finds nothing rather than guessing.

=head1 SEE ALSO

L<File::Raw::XML>, L<File::Raw::XML::Document>, L<File::Raw::XML::Node>,
L<File::Raw::XML::Attr>, L<File::Raw::XML::Namespace>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
