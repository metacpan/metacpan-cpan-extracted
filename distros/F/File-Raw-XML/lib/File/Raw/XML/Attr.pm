package File::Raw::XML::Attr;

use 5.010;
use strict;
use warnings;

use File::Raw::XML ();    # one dist, one bootstrap: the class lives in its bundle

1;

__END__

=head1 NAME

File::Raw::XML::Attr - an attribute in an XPath result

=head1 SYNOPSIS

    my @ids = $doc->xpath('//@id');
    for my $a (@ids) {
        printf "%s=%s on %s\n", $a->name, $a->value, $a->owner->local;
    }

=head1 DESCRIPTION

What an attribute comes back as when an XPath node-set holds one. An
attribute is not a node of the tree, so it is not a
L<File::Raw::XML::Node>: it belongs to an element and is named by its
position on it. Like a node, it keeps its document alive for as long as
it exists.

These are never constructed directly. L<File::Raw::XML::XPath/find> and
L<File::Raw::XML::Node/xpath> return them; L<File::Raw::XML::Node/attrs>
returns plain arrayrefs instead, which is the cheaper answer when you
already have the element.

An attribute holds its element and its position on it, so removing an
earlier attribute from that element leaves it naming whatever moved into
its place. See L<File::Raw::XML::Node/remove_attr>.

=head1 METHODS

=head2 name

The qualified name as written, so C<xml:lang> rather than C<lang>.

=head2 local

The local part of the name.

=head2 ns

The namespace URI, or the empty string when the attribute has none. An
unprefixed attribute has none, never the default namespace.

=head2 prefix

The prefix as written, or the empty string.

=head2 value

The value, normalised: as CDATA when nothing declared a type for it, and
by the declared type when a document type declaration did.

=head2 owner

The L<File::Raw::XML::Node> this attribute is on.

=head2 doc

The L<File::Raw::XML::Document> it belongs to.

=head1 SEE ALSO

L<File::Raw::XML::XPath>, L<File::Raw::XML::Namespace>,
L<File::Raw::XML::Node>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
