##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/TokenList.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/09
## Modified 2021/12/09
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::TokenList;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my $tokens = shift( @_ );
    $self->{attribute}  = undef;
    $self->{items}      = [];
    $self->{element}    = undef;
    $self->{tokens}     = undef;
    if( defined( $tokens ) && CORE::length( $tokens ) )
    {
        $self->{items} = $self->_string2array( $tokens )->unique(1);
        $self->{tokens} = $tokens;
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub add
{
    my $self = shift( @_ );
    my $a    = $self->_string2array( @_ );
    $self->message( 4, "Adding tokens '", $a->join( "', '" )->scalar, "'" );
    $self->items->push( $a->list );
    $self->items->unique(1);
    $self->_reset;
    return( $self );
}

sub as_string { return( shift->items->join( ' ' )->scalar ); }

sub attribute { return( shift->_set_get_scalar_as_object( 'attribute', @_ ) ); }

sub contains { return( shift->items->has( _trim( @_ ) ) ); }

sub element { return( shift->_set_get_object_without_init( 'element', 'HTML::Object::Element', @_ ) ); }

sub entries { return; }

sub forEach
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No anonymous subroutine was provided." ) );
    return( $self->error( "Callback provided is not an anonymous subroutine" ) ) if( ref( $code ) ne 'CODE' );
    my $elem = $self->element;
    # We do not sort on purpose. Change in the order will trigger a cache reset on the associated element
    my $before = $self->items->join( ',' )->scalar if( $elem );
    $self->items->foreach( $code );
    if( $elem )
    {
        my $after = $self->items->join( ',' )->scalar;
        $elem->_reset(1) if( $before ne $after );
    }
    return( $self );
}

sub item { return( shift->items->index( shift( @_ ) ) ); }

sub items
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $ref = $self->_set_get_array_as_object( 'items', @_ );
        $self->_reset;
        return( $ref );
    }
    else
    {
        # Check if the value has changed on the element so we keep in sync
        my $attr = $self->attribute;
        my $elem = $self->element;
        if( $attr && $elem )
        {
            my $elem_tokens = $elem->attr( $attr );
            $self->message( 4, "Element's tokens are '$elem_tokens' and our tokens are '", $self->tokens, "'" );
            if( $elem_tokens eq $self->tokens )
            {
                return( $self->_set_get_array_as_object( 'items' ) );
            }
            # Element attribute value takes precedence over us
            else
            {
                return( $self->{items} = $self->_string2array( $elem_tokens ) );
            }
        }
        return( $self->_set_get_array_as_object( 'items' ) );
    }
}

sub keys { return; }

# Property
sub length { return( shift->items->length ); }

sub remove { return( shift->items->remove( _trim( @_ )->_reset ) ); }

sub replace
{
    my $self = shift( @_ );
    my $ok = $self->items->replace( @_ ) ? $self->true : $self->false;
    $self->items->unique(1);
    # Reset the associated element cache, if any.
    $self->_reset;
    return( $ok );
}

sub reset
{
    my $self = shift( @_ );
    $self->items->reset;
    $self->tokens->reset;
    $self->_reset;
    return( $self );
}

sub supports { return( shift->true ); }

sub toggle
{
    my $self = shift( @_ );
    my $token = shift( @_ ) || return( $self->error( "No token was provided to toggle." ) );
    $token = _trim( $token );
    my $rv;
    if( $self->items->has( $token ) )
    {
        $rv = $self->items->remove( $token ) ? $self->true : $self->false;
    }
    else
    {
        $self->items->push( $token );
        $rv = $self->true;
    }
    $self->_reset;
    return( $rv );
}

sub tokens { return( shift->_set_get_scalar_as_object( 'tokens', @_ ) ); }

sub update
{
    my $self = shift( @_ );
    if( scalar( @_ ) )
    {
        if( scalar( @_ ) == 1 && !defined( $_[0] ) )
        {
            $self->tokens->reset;
            $self->items->reset;
        }
        else
        {
            my $items = $self->_string2array( @_ );
            # $self->message( 4, "Updating tokens list with '", $items->join( "', '" )->scalar, "'" );
            $self->tokens( $items->join( ' ' )->scalar );
            $self->{items} = $items;
        }
    }
    return( $self );
}

# Property
sub value { return( shift->as_string ); }

sub values { return; }

sub _reset
{
    my $self = shift( @_ );
    my $elem = $self->element;
    my $tokens = $self->as_string;
    $self->tokens( $tokens );
    $self->message( 4, "Pushing change for element '", ( ref( $elem ) ? $elem->tag : '' ), " (", overload::StrVal( $elem ), ") with attribute '", ( $self->attribute ? $self->attribute : '' ), "'" );
    return( $self ) if( !ref( $elem ) );
    my $attr = $self->attribute || return( $self );
    $self->message( 4, "Setting element attribute '$attr' to '$tokens'" );
    $elem->attr( $attr => $tokens );
    $elem->reset(1);
    return( $self );
}

sub _string2array
{
    my $self = shift( @_ );
    my @tokens = ();
    for( @_ )
    {
        if( $self->_is_array( $_ ) )
        {
            push( @tokens, @$_ );
        }
        # space-delimited tokens
        else
        {
            push( @tokens, split( /[[:blank:]\h]+/, _trim( @_ ) ) );
        }
    }
    return( $self->new_array( \@tokens )->unique(1) );
}

sub _trim
{
    my $str  = shift( @_ );
    $str =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
    $str =~ s/[[:blank:]\h]+/ /g;
    return( $str );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::TokenList - HTML Object Token List Class

=head1 SYNOPSIS

    use HTML::Object::TokenList;
    # standalone, i.e. without connection to an element
    my $list = HTML::Object::TokenList->new( 'some class to edit' ) || 
        die( HTML::Object::TokenList->error, "\n" );

Or

    use HTML::Object::Element;
    my $e = HTML::Object::Element->new( tag => 'div' );
    my $list = $e->classList;

    $list->add( 'another-class' );
    $list->remove( 'edit' );
    $list->length;
    $list->value;
    $list->as_string;
    $list->contains( 'some' );
    $list->forEach(sub
    {
        my $c = shift( @_ ); # also available as $_
        # do something
    });
    $list->item(3); # 'edit'
    $list->replace( 'to' = 'other' );
    $list->toggle( 'visible' ); # activate it
    $list->toggle( 'visible' ); # now remove it

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<TokenList> interface represents a set of space-separated tokens. Such a set is returned by L<HTML::Object::DOM::Element/classList> or L<HTML::Object::DOM::AnchorElement/relList>.

A C<TokenList> is indexed beginning with 0 as with perl array. C<TokenList> is always case-sensitive.

This module can be used independently or be instantiated by an L<element|HTML::Object::DOM::Element>, and in which case, any modification made will be reflected in the associated element's attribute.

=head1 PROPERTIES

=head2 length

Read-only. This returns an L<integer|Module::Generic::Number> representing the number of objects stored in the object.

=head2 value

A stringifier property that returns the value of the list as a string. See also L</as_string>

=head1 METHODS

=head2 add

Adds the specified tokens to the list. Returns the current object for chaining.

The tokens can be provided either as a list of string, an array reference of strings, or a space-delimited string of tokens.

=head2 as_string

A stringifier property that returns the value of the list as a string. See also L</value>

=head2 attribute

Set or get the element attribute to which C<TokenList> is bound. For example a C<class> attribute or a C<rel> attribute

This is optional if you want to use this class independently from any element, or if you want to set the element later.

=head2 contains

Returns true if the list contains the given token, otherwise false.

=head2 element

Set or get the L<element|HTML::Object::Element>

This is optional if you want to use this class independently from any element, or if you want to set the element later.

=head2 entries

This does nothing.

Normally, under JavaScript, this would return an iterator, allowing you to go through all key/value pairs contained in this object.

=head2 forEach

Executes a provided callback function once for each DOMTokenList element.

=head2 item

Returns the item in the list by its index, or undefined if the index is greater than or equal to the list's length.

=head2 items

Sets or gets the list of token items. It returns the L<array object|Module::Generic::Array> containing all the tokens.

=head2 keys

This does nothing.

Normally, under JavaScript, this would return an iterator, allowing you to go through all keys of the key/value pairs contained in this object.

=head2 remove

Removes the specified tokens from the list.

=head2 replace

Replaces the token with another one.

It returns a boolean value, which is true if the old entry was successfully replaced, or false if not. 

See the L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/replace> for more information.

=head2 reset

Reset the tokens list to an empty list and, of course, propagate that change to the associated element's attribute, if any was set.

Returns the current object.

=head2 supports

Returns true if the given token is in the associated attribute's supported tokens.

For the purpose of the perl environment, this actually always returns true.

=head2 toggle

Removes the token from the list if it exists, or adds it to the list if it does not. Returns a boolean indicating whether the token is in the list after the operation.

=head2 tokens

Sets or get the L<array object|Module::Generic::Array> of tokens.

=head2 update

This method is called by an internal callback in L<HTML::Object::Element> when the value of an registered attribute has been changed. It does not propagate the change back to the element since it is triggered by the element itself.

If C<undef> is provided as its sole argument, this will empty the tokens list, otherwise it will set the new tokens list with a space-delimited string of tokens, a list or array reference of tokens.

Returns the current object.

=head2 values

This does nothing.

Normally, under JavaScript, this would return an iterator, allowing you to go through all values of the key/value pairs contained in this object.

=head1 EXAMPLES

In the following simple example, we retrieve the list of classes set on a <p> element as a L<HTML::Object::TokenList> using L<HTML::Object::Element/classList>, add a class using L<HTML::Object::TokenList/add>, and then update the C<textContent> of the <p> to equal the L<HTML::Object::TokenList>.

    <p class="a b c"></p>

    my $para = $doc->querySelector("p");
    my $classes = $para->classList;
    $para->classList->add("d");
    $para->textContent = qq{paragraph classList is "${classes}"};

would yield:

    paragraph classList is "a b c d"

=head1 WHITESPACE AND DUPLICATES

Methods that modify the TokenList (such as L<HTML::Object::TokenList/add>) automatically trim any excess whitespace and remove duplicate values from the list. For example:

    <span class="    d   d e f"></span>

    my $span = $doc->querySelector("span");
    my $classes = $span->classList;
    $span->classList->add("x");
    $span->textContent = qq{span classList is "${classes}"};

would yield:

    span classList is "d e f x"

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::Element>

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
