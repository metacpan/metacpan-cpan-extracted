package File::Raw::XML::Namespace;

use 5.010;
use strict;
use warnings;

use File::Raw::XML ();    # one dist, one bootstrap: the class lives in its bundle

1;

__END__

=head1 NAME

File::Raw::XML::Namespace - a namespace node in an XPath result

=head1 SYNOPSIS

    for my $ns ($doc->xpath('/*/namespace::*')) {
        printf "%s -> %s\n", $ns->prefix || '(default)', $ns->uri;
    }

=head1 DESCRIPTION

What the XPath namespace axis returns. A namespace node is not stored on
the tree and is not a L<File::Raw::XML::Node>: it is one of the bindings
in scope on an element, worked out when the axis asks for them. Like a
node, it keeps its document alive for as long as it exists.

The bindings are the nearest declaration of each prefix, with C<xml>
always among them because the XML Namespaces Recommendation declares it
implicitly, and with a prefix undeclared by C<xmlns=""> absent because
that declares the absence of a namespace rather than a namespace. XPath
leaves the relative order of namespace nodes to the implementation and
asks only that it be stable; here it is by prefix, so it is the same
order every time.

=head1 METHODS

=head2 prefix

The prefix this binding declares, or the empty string for the default
namespace.

=head2 name

The same thing. A namespace node's expanded name has a null namespace URI
and the prefix as its local part, which is why C<namespace::foo> matches
by prefix and a prefixed name test matches nothing.

=head2 uri

The namespace URI the prefix is bound to.

=head2 value

The same thing: a namespace node's string-value is its URI.

=head2 owner

The L<File::Raw::XML::Node> the binding is in scope on. That is the
element the axis was evaluated at, not necessarily the one that declared
it.

=head2 doc

The L<File::Raw::XML::Document> it belongs to.

=head1 SEE ALSO

L<File::Raw::XML::XPath>, L<File::Raw::XML::Attr>, L<File::Raw::XML::Node>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
