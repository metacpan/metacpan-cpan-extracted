##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Declaration.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/13
## Modified 2021/12/13
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Declaration;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Declaration HTML::Object::DOM::Node );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{name} = 'html';
    $self->{_init_strict_use_sub} = 1;
    $self->HTML::Object::Declaration::init( @_ ) || return( $self->pass_error );
    $self->message( 4, "Returning the declaration object '", overload::StrVal( $self ), "'" );
    return( $self );
}

sub after
{
    my $self = shift( @_ );
    my $parent = $self->parent ||
        return( $self->error( "No parent document is set for this DTD" ) );
    return if( !$parent );
    my $nodes = $self->_list_to_nodes( @_ );
    return if( $nodes->is_empty );
    my $refNode = $self;
    foreach my $node ( @$nodes )
    {
        $parent->insertAfter( $node, $refNode );
        $refNode = $node;
    }
    return( $self );
}

sub before
{
    my $self = shift( @_ );
    my $parent = $self->parent ||
        return( $self->error( "No parent document is set for this DTD" ) );
    return if( !$parent );
    my $nodes = $self->_list_to_nodes( @_ );
    return if( $nodes->is_empty );
    my $refNode = $self;
    foreach my $node ( @$nodes )
    {
        $parent->insertBefore( $node, $refNode );
        $refNode = $node;
    }
    return( $self );
}

# Note: property internalSubset read-only
sub internalSubset { return( shift->new_scalar ); }

# Note: property name read-only
sub name : lvalue { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

# Note: property notations read-only
sub notations { return; }

# Note: property publicId read-only
sub publicId
{
    my $self = shift( @_ );
    if( my $rv = $self->original->match( qr/PUBLIC[[:blank:]\h]+\"([^\"]+)\"/ ) )
    {
        return( $rv->capture->first );
    }
    return( '' );
}

sub remove
{
    my $self = shift( @_ );
    my $parent = $self->parent || return;
    $parent->removeChild( $self );
    return( $self );
}

sub replaceWith
{
    my $self = shift( @_ );
    my $parent = $self->parent || return;
    my $list = $self->_list_to_nodes( @_ ) || return( $self->pass_error );
    my $pos = $parent->nodes->pos( $self );
    return( $self->error( "Unable to find our DTD object in our parent's nodes" ) ) if( !defined( $pos ) );
    my $dtd;
    $list->foreach(sub
    {
        $_->parent( $parent );
        if( $self->_is_a( $_ => 'HTML::Object::DOM::Declaration' ) )
        {
            $dtd = $_;
        }
    });
    $parent->nodes->splice( $pos, 1, $list->list );
    # Either an DTD object, if we found one, or undef
    $parent->declaration( $dtd );
    $parent->reset(1);
    return( $self );
}

sub string_value { return; }

# Note: property systemId read-only
sub systemId
{
    my $self = shift( @_ );
    if( my $rv = $self->original->match( qr/[[:blank:]\h]+\"(http[^\"]+)\"/ ) )
    {
        return( $rv->capture->first );
    }
    return( '' );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Declaration - HTML Object DOM DTD

=head1 SYNOPSIS

    use HTML::Object::DOM::Declaration;
    my $decl = HTML::Object::DOM::Declaration->new || 
        die( HTML::Object::DOM::Declaration->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module implements an HTTML declaration for the DOM. It inherits from L<HTML::Object::Declaration> and L<HTTML::Object::DOM::Node>

=head1 INHERITANCE

    +---------------------------+     +---------------------------+     +-------------------------+     +--------------------------------+
    |   HTML::Object::Element   | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Declaration |
    +---------------------------+     +---------------------------+     +-------------------------+     +--------------------------------+
      |                                                                                                   ^
      |                                                                                                   |
      v                                                                                                   |
    +---------------------------+                                                                         |
    | HTML::Object::Declaration | ------------------------------------------------------------------------+
    +---------------------------+

=head1 PROPERTIES

Inherits properties from its parents L<HTML::Object::Declaration> and L<HTML::Object::DOM::Node>

=head2 internalSubset

Read-only.

A string of the internal subset, or C<undef> if there is none. Eg "<!ELEMENT foo (bar)>".

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/internalSubset>

=head2 name

Read-only.

A string, eg "html" for <!DOCTYPE HTML>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/name>

=head2 notations

Always returns C<undef> under perl.

Normally, under JavaScript, this returns s C<NamedNodeMap> with notations declared in the DTD.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/notations>

=head2 publicId

Read-only.

A string, eg "-//W3C//DTD HTML 4.01//EN", empty string for HTML5.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/publicId>

=head2 systemId

Read-only.

A string, eg "http://www.w3.org/TR/html4/strict.dtd", empty string for HTML5.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/systemId>

=head1 METHODS

Inherits methods from its parents L<HTML::Object::Declaration> and L<HTML::Object::DOM::Node>

=head2 after

Inserts a set of L<Node|HTML::Object::DOM::Node> or string objects in the children list of the
C<DocumentType>'s parent, just after the C<DocumentType> object.

Example:

    my $docType = $doc->implementation->createDocumentType("html", "", "");
    my $myDoc = $doc->implementation->createDocument("", "", $docType);

    $docType->after($doc->createElement('html'));

    $myDoc->childNodes;
    # NodeList [<!DOCTYPE html>, <html>]

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/after>

=head2 before

Inserts a set of Node or string objects in the children list of the
C<DocumentType>'s parent, just before the C<DocumentType> object.

Example:

    my $docType = $doc->implementation->createDocumentType("html", "", "");
    my $myDoc = $doc->implementation->createDocument("", "", $docType);

    $docType->before( $doc->createComment('<!--[if !IE]> conditional comment <![endif]-->') );

    $myDoc->childNodes;
    # NodeList [<!--[if !IE]> conditional comment <![endif]-->, <!DOCTYPE html>]

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/before>

=head2 remove

Removes the object from its parent children list.

Example:

    $doc->doctype; # "<!DOCTYPE html>'
    $doc->doctype->remove();
    $doc->doctype; # null

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/remove>

=head2 replaceWith

Replaces the document type with a set of given nodes.

Example:

    my $svg_dt = $doc->implementation->createDocumentType(
        'svg:svg',
        '-//W3C//DTD SVG 1.1//EN',
        'http://www->w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'
    );

    $doc->doctype->replaceWith($svg_dt);

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/replaceWith>

=head2 string_value

Always returns C<undef>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
