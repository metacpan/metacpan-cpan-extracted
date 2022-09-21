##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Comment.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/13
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Comment;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Comment HTML::Object::DOM::CharacterData );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->HTML::Object::Comment::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub getAttributes { return( wantarray() ? () : [] ); }

sub getChildNodes { return( wantarray() ? () : [] ); }

sub getElementById { return; }

sub getFirstChild { return; }

sub getLastChild { return; }

sub getParentNode { return( shift->parent ); }

sub getRootNode { return( shift->parent->getRootNode ); }

sub getValue { return( shift->value ); }

sub isEqualNode
{
    my $self = shift( @_ );
    my $e = shift( @_ ) || return( $self->error( "No html element was provided to insert." ) );
    return( $self->error( "Element provided (", overload::StrVal( $e ), ") is not an HTML::Object::Element." ) ) if( !$self->_is_a( $e => 'HTML::Object::Element' ) );
    return(0) if( !$self->_is_a( $e => 'HTML::Object::Comment' ) );
    return( $self->value eq $e->value );
}

sub isAttributeNode { return(0); }

sub isCommentNode   { return(1); }

sub isElementNode   { return(0); }

sub isNamespaceNode { return(0); }

sub isPINode        { return(0); }

sub isProcessingInstructionNode { return(0); }

sub isTextNode { return(0); }

# Note: Property
sub nodeValue : lvalue { return( shift->_set_get_lvalue( 'value', @_ ) ); }

sub string_value { return( shift->value ); }

sub toString { return( shift->value ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Comment - HTML Object DOM Comment Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Comment;
    my $this = HTML::Object::DOM::Comment->new( value => $some_comment ) || 
        die( HTML::Object::DOM::Comment->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The L<Comment|HTML::Object::DOM::Comment> interface represents textual notations within markup; although it is generally not visually shown, such comments are available to be read in the source view.

Comments are represented in HTML and XML as content between '<!--' and '-->'. In XML, like inside SVG or MathML markup, the character sequence '--' cannot be used within a comment.

It inherits from L<HTML::Object::Comment> and L<HTML::Object::DOM::CharacterData>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------------+     +----------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::CharacterData | --> | HTML::Object::DOM::Comment |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------------+     +----------------------------+
      |                                                                                                                                        ^
      |                                                                                                                                        |
      v                                                                                                                                        |
    +-----------------------+                                                                                                                  |
    | HTML::Object::Comment | -----------------------------------------------------------------------------------------------------------------+
    +-----------------------+

=head1 PROPERTIES

=head2 nodeValue

Sets or gets the text value for this element.

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

=head2 getValue

Returns the text value of this comment, i.e. the text between C<<!--> and C<-->>

=head2 isAttributeNode

Returns false.

=head2 isCommentNode

Returns true.

=head2 isElementNode

Returns false.

=head2 isEqualNode

Provided with another element object, and this returns true if both comment element are the same, or false otherwise.

=head2 isNamespaceNode

Returns false.

=head2 isPINode

Returns false.

=head2 isProcessingInstructionNode

Returns false.

=head2 isTextNode

Returns false.

=head2 string_value

Returns the content of the comment as a string.

=head2 toString

Returns the content of the comment as a string.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Comment>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
