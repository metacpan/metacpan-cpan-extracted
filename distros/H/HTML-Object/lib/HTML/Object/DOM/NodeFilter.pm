##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/NodeFilter.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/01
## Modified 2022/01/01
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::NodeFilter;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use HTML::Object::Exception;
    use constant {
        # Shows all nodes.
        SHOW_ALL                    => 4294967295,
        # Shows Element nodes.
        SHOW_ELEMENT                => 1,
        # Shows attribute Attr nodes.
        SHOW_ATTRIBUTE              => 2,
        # Shows Text nodes.
        SHOW_TEXT                   => 4,
        # Shows CDATASection nodes.
        SHOW_CDATA_SECTION          => 8,
        # Legacy, no more used.
        SHOW_ENTITY_REFERENCE 	    => 16,
        # Legacy, no more used.
        SHOW_ENTITY                 => 32,
        # Shows ProcessingInstruction nodes.
        SHOW_PROCESSING_INSTRUCTION => 64,
        # Shows Comment nodes.
        SHOW_COMMENT                => 128,
        # Shows Document nodes.
        SHOW_DOCUMENT               => 256,
        # Shows DocumentType nodes.
        SHOW_DOCUMENT_TYPE          => 512,
        # Shows DocumentFragment nodes.
        SHOW_DOCUMENT_FRAGMENT 	    => 1024,
        # Legacy, no more used.
        SHOW_NOTATION               => 2048,
        # Show spaces; non-standard addition
        SHOW_SPACE                  => 4096,
        
        FILTER_ACCEPT               => 1,
        FILTER_REJECT               => 2,
        FILTER_SKIP                 => 3,
    };
    our @EXPORT_OK = qw(
        SHOW_ALL SHOW_ELEMENT SHOW_ATTRIBUTE SHOW_TEXT SHOW_CDATA_SECTION 
        SHOW_ENTITY_REFERENCE SHOW_ENTITY SHOW_PROCESSING_INSTRUCTION SHOW_COMMENT 
        SHOW_DOCUMENT SHOW_DOCUMENT_TYPE SHOW_DOCUMENT_FRAGMENT SHOW_NOTATION SHOW_SPACE
        FILTER_ACCEPT FILTER_REJECT FILTER_SKIP
    );
    our %EXPORT_TAGS = ( all => [@EXPORT_OK] );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub acceptNode { return( FILTER_ACCEPT ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::NodeFilter - HTML Object DOM Node Filter

=head1 SYNOPSIS

    use HTML::Object::DOM::NodeFilter;
    my $filter = HTML::Object::DOM::NodeFilter->new || 
        die( HTML::Object::DOM::NodeFilter->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A C<NodeFilter> interface represents an object used to filter the nodes in a L<HTML::Object::DOM::NodeIterator> or L<HTML::Object::DOM::::TreeWalker>. A C<NodeFilter> knows nothing about the document or traversing nodes; it only knows how to evaluate a single node against the provided filter.

=head1 PROPERTIES

There are no properties.

=head1 METHODS

=head2 acceptNode

Returns an unsigned short that will be used to tell if a given L<Node|HTML::Object::DOM::Node> must be accepted or not by the L<HTML::Object::DOM::NodeIterator> or L<HTML::Object::DOM::TreeWalker> iteration algorithm.

This method is expected to be written by the user of a C<NodeFilter>. Possible return values are:

=over 4

=item FILTER_ACCEPT

Value returned by the L</acceptNode> method when a node should be accepted.

=item FILTER_REJECT

Value to be returned by the L</acceptNode> method when a node should be rejected. For L<HTML::Object::DOM::TreeWalker>, child nodes are also rejected.

For C<NodeIterator>, this flag is synonymous with C<FILTER_SKIP>.

=item FILTER_SKIP

Value to be returned by L</acceptNode> for nodes to be skipped by the L<HTML::Object::DOM::NodeIterator> or L<HTML::Object::DOM::TreeWalker> object.

The children of skipped nodes are still considered. This is treated as "skip this node but not its children".

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $nodeIterator = $doc->createNodeIterator(
        # Node to use as root
        $doc->getElementById('someId'),

        # Only consider nodes that are text nodes (nodeType 3)
        SHOW_TEXT,

        # Object containing the sub to use for the acceptNode method
        # of the NodeFilter
        { acceptNode => sub
            {
                my $node = shift( @_ ); # also available as $_
                # Logic to determine whether to accept, reject or skip node
                # In this case, only accept nodes that have content other than whitespace
                if( $node->data !~ /^\s*$/ )
                {
                    return( FILTER_ACCEPT );
                }
            }
        },
        0 # false
    );

    # Show the content of every non-empty text node that is a child of root
    my $node;
    while( ( $node = $nodeIterator->nextNode() ) )
    {
        say( $node->data );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeFilter/acceptNode>

=back

=head1 CONSTANTS

=over 4

=item SHOW_ALL (4294967295)

Shows all nodes.

=item SHOW_ELEMENT (1)

Shows Element nodes.

=item SHOW_ATTRIBUTE (2)

Shows attribute L<Attribute nodes|HTML::Object::DOM::Attribute>. This is meaningful only when creating a NodeIterator with an L<Attribute node|HTML::Object::DOM::Attribute> as its root; in this case, it means that the L<attribute node|HTML::Object::DOM::Attribute> will appear in the first position of the iteration or traversal. Since attributes are never children of other L<nodes|HTML::Object::DOM::Node>, they do not appear when traversing over the document tree.

=item SHOW_TEXT (4)

Shows Text nodes.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        SHOW_ELEMENT | SHOW_COMMENT | SHOW_TEXT,
        { acceptNode => sub{ return( FILTER_ACCEPT ); } },
        0 # false
    );
    if( ( $nodeIterator->whatToShow & SHOW_ALL ) ||
        ( $nodeIterator->whatToShow & SHOW_COMMENT ) )
    {
        # $nodeIterator will show comments
    }

=item SHOW_CDATA_SECTION (8)

Will always returns nothing, because there is no support for xml documents.

=item SHOW_ENTITY_REFERENCE (16)

Legacy, no more used.

=item SHOW_ENTITY (32)

Legacy, no more used.

=item SHOW_PROCESSING_INSTRUCTION (64)

Shows ProcessingInstruction nodes.

=item SHOW_COMMENT (128)

Shows Comment nodes.

=item SHOW_DOCUMENT (256)

Shows Document nodes

=item SHOW_DOCUMENT_TYPE (512)

Shows C<DocumentType> nodes

=item SHOW_DOCUMENT_FRAGMENT (1024)

Shows L<HTML::Object::DOM::DocumentFragment> nodes.

=item SHOW_NOTATION (2048)

Legacy, no more used.

=item SHOW_SPACE (4096)

Show Space nodes. This is a non-standard extension under this perl framework.

=back

And for the callback control:

=over 4

=item FILTER_ACCEPT (1)

=item FILTER_REJECT (2)

=item FILTER_SKIP (3)

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeFilter>, L<W3C specifications|https://dom.spec.whatwg.org/#interface-nodefilter>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
