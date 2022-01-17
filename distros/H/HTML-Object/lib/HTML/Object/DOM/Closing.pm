##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Closing.pm
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
package HTML::Object::DOM::Closing;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Closing HTML::Object::DOM::Node );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->HTML::Object::Closing::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub getAttributes { return( wantarray() ? () : [] ); }

sub getChildNodes { return( wantarray() ? () : [] ); }

sub getElementById { return; }

sub getFirstChild { return; }

sub getLastChild { return; }

sub getParentNode { return( shift->parent ); }

sub getRootNode { return( shift->parent->getRootNode ); }

sub isAttributeNode { return(0); }

sub isCommentNode   { return(0); }

sub isElementNode   { return(0); }

sub isEqualNode
{
    my $self = shift( @_ );
    my $e = shift( @_ ) || return( $self->error( "No html element was provided to insert." ) );
    return( $self->error( "Element provided (", overload::StrVal( $e ), ") is not an HTML::Object::Element." ) ) if( !$self->_is_a( $e => 'HTML::Object::Element' ) );
    return(0) if( !$self->_is_a( $e => 'HTML::Object::Closing' ) );
    return( $self->tag eq $e->tag );
}
sub isNamespaceNode { return(0); }

sub isPINode        { return(0); }

sub isProcessingInstructionNode { return(0); }

sub isTextNode      { return(0); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Closing - HTML Object

=head1 SYNOPSIS

    use HTML::Object::DOM::Closing;
    my $this = HTML::Object::DOM::Closing->new( tag => 'div' ) || 
        die( HTML::Object::DOM::Closing->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module implements a closing tag for the DOM. It inherits from L<HTML::Object::Closing> and L<HTML::Object::DOM::Node>

Closing tags exists, but are not part of the nodes, so they are transparent.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Closing |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+
      |                                                                                               ^
      |                                                                                               |
      v                                                                                               |
    +-----------------------+                                                                         |
    | HTML::Object::Closing | ------------------------------------------------------------------------+
    +-----------------------+

=head1 PROPERTIES

There is no property.

=head1 METHODS

=head2 getAttributes

Returns an empty list in list context, or an empty array reference in scalar context.

=head2 getChildNodes

Returns an empty list in list context, or an empty array reference in scalar context.

=head2 getElementById

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getFirstChild

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getLastChild

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getParentNode

Returns the parent node, if any.

=head2 getRootNode

Returns the L<root node|HTML::Object::DOM::Document>

=head2 isAttributeNode

Returns false.

=head2 isCommentNode

Returns false.

=head2 isElementNode

Returns false.

=head2 isEqualNode

Provided with another element object, and this returns true if both closing element have the same tag value, or false otherwise.

=head2 isNamespaceNode

Returns false.

=head2 isPINode

Returns false.

=head2 isProcessingInstructionNode

Returns false.

=head2 isTextNode

Returns false.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::Element/close>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
