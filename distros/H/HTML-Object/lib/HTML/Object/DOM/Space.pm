##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Space.pm
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
package HTML::Object::DOM::Space;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Space HTML::Object::DOM::CharacterData );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->HTML::Object::Space::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub getAttributes { return( wantarray() ? () : [] ); }

sub getChildNodes { return( wantarray() ? () : [] ); }

sub getElementById { return; }

sub getFirstChild { return; }

sub getLastChild { return; }

sub getRootNode { return( shift->parent->getRootNode ); }

sub isAttributeNode { return(0); }

sub isCommentNode   { return(0); }

sub isElementNode   { return(0); }

sub isNamespaceNode { return(0); }

sub isPINode        { return(0); }

sub isProcessingInstructionNode { return(0); }

sub isTextNode      { return(0); }

sub isEqualNode
{
    my $self = shift( @_ );
    my $e = shift( @_ ) || return( $self->error( "No html element was provided to insert." ) );
    return( $self->error( "Element provided (", overload::StrVal( $e ), ") is not an HTML::Object::Element." ) ) if( !$self->_is_a( $e => 'HTML::Object::Element' ) );
    return(0) if( !$self->_is_a( $e => 'HTML::Object::Space' ) );
    return( $self->value eq $e->value );
}

# Note: Property
sub nodeValue : lvalue { return( shift->_set_get_lvalue( 'value', @_ ) ); }

sub parent { return( shift->_set_get_object_without_init( 'parent', 'HTML::Object::DOM::Node', @_ ) ); }

sub string_value { return( shift->value ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Space - HTML Object DOM Space Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Space;
    my $sp = HTML::Object::DOM::Space->new( value => $some_space ) || 
        die( HTML::Object::DOM::Space->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This implements the representation of a space-only chunk of data. This is a divergence from the DOM standard which treats space as text. Thus, any data chunk comprised only of spaces between tags would all be space nodes. Spaces includes space, tabulation, carriage return, new line, and any other horizontal and vertical spaces.

It inherits from L<HTML::Object::Space> and L<HTML::Object::DOM::CharacterData>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------------+     +--------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::CharacterData | --> | HTML::Object::DOM::Space |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------------+     +--------------------------+
      |                                                                                                                                        ^
      |                                                                                                                                        |
      v                                                                                                                                        |
    +-----------------------+                                                                                                                  |
    |  HTML::Object::Space  | -----------------------------------------------------------------------------------------------------------------+
    +-----------------------+

=head1 PROPERTIES

=head2 nodeValue

Sets or gets the value of this space node.

=head1 METHODS

=head2 getAttributes

Returns an empty list in list context or an empty array reference in scalar context.

=head2 getChildNodes

Returns an empty list in list context or an empty array reference in scalar context.

=head2 getElementById

Returns an empty list in list context or C<undef> in scalar context.

=head2 getFirstChild

Returns an empty list in list context or C<undef> in scalar context.

=head2 getLastChild

Returns an empty list in list context or C<undef> in scalar context.

=head2 getRootNode

Returns the value from the parent's C<getRootNode>

=head2 isAttributeNode

Returns false.

=head2 isCommentNode

Returns false.

=head2 isElementNode

Returns false.

=head2 isNamespaceNode

Returns false.

=head2 isPINode

Returns false.

=head2 isProcessingInstructionNode

Returns false.

=head2 isTextNode

Returns false.

=head2 isEqualNode

Returns true if both nodes are space nodes of equivalent value.

=head2 parent

Sets or gets the object value of this space node's parent.

=head2 string_value

Read-only.

Returns the value of this space node.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model/Whitespace>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
