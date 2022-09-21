##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Option.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Option;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :option );
    use Want;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'option' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property defaultSelected
sub defaultSelected : lvalue { return( shift->_set_get_property({
    attribute => 'selected',
    callback => sub
    {
        my $self = shift( @_ );
        my $attr = shift( @_ );
        if( @_ )
        {
            my $value = shift( @_ );
            # Whatever true value we received, we change it to empty string so this becomes:
            # selected=""
            $value = '' if( defined( $value ) );
            $self->attr( $attr => $value );
            $self->selected( $value );
            # Will also reset our parent, if any
            $self->reset(1);
        }
        else
        {
            return( $self->attributes->has( 'selected' ) ? 1 : 0 );
        }
    }
}, @_ ) ); }

# Note: property disabled is inherited

# Note: property form read-only inherited

# Note: property index read-only
sub index
{
    my $self = shift( @_ );
    my $parent = $self->parent;
    return if( !$parent );
    return if( !$parent->can( 'options' ) );
    return( $parent->options->pos( $self ) );
}

# Note: property label read-only
sub label : lvalue { return( shift->_lvalue({
    set => sub
    {
        my $self = shift( @_ );
        my $ref = shift( @_ );
        my $val = shift( @$ref );
        # User passed undef, so we remove all text from the option
        if( !defined( $val ) )
        {
            $self->children->reset;
            return( $self );
        }
        $val = $val->value if( $self->_is_a( $val => 'HTML::Object::DOM::Element::Text' ) || $self->_is_a( $val => 'HTML::Object::DOM::Element::Space' ) );
        return( $self->error({
            message => "Value provided ($val) is not a string.",
            class => 'HTML::Object::TypeError',
        }) ) if( ref( $val ) && !overload::Method( $val, '""' ) );
        return( $self->attr( label => "$val" ) );
    },
    get => sub
    {
        my $self = shift( @_ );
        my $label = $self->attr( 'label' );
        if( defined( $label ) && CORE::length( "$label" ) )
        {
            return( $label );
        }
        else
        {
            return( $self->text );
        }
    }
}, @_ ) ); }

# Note: property selected
# Unintuitively enough, the one that affects the 'selected' attribute is the 'defaultSelected' method, not this 'selected' one ! This is just a boolean
sub selected : lvalue
{
    my $self = shift( @_ );
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg++;
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    # If a value is provided, this will set the internal boolean value, but will not affect the DOM attribute 'selected'
    if( $has_arg )
    {
        return( $self->_set_get_boolean( 'selected', $arg ) );
    }
    # If no value is provided, we return true if the DOM attribute exists, no matter its value, or false otherwise
    else
    {
        my $val = $self->attributes->has( 'selected' ) ? 1 : 0;
        return( $val );
    }
}

# Note: property text
# textContent is inherited from HTML::Object::DOM::Node and is also an lvalue method
sub text : lvalue { return( shift->textContent( @_ ) ); }

# Note: property value
sub value : lvalue
{
    my $self = shift( @_ );
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg++;
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    if( $has_arg )
    {
        return( $self->_set_get_property( 'value', $arg ) );
    }
    else
    {
        return( $self->attributes->has( 'value' ) ? $self->attr( 'value' ) : $self->textContent );
    }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Option - HTML Object DOM Option Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Option;
    my $opt = HTML::Object::DOM::Element::Option->new || 
        die( HTML::Object::DOM::Element::Option->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface represents C<<option>> elements and inherits all properties and methods of the L<HTML::Object::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Option |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 defaultSelected

Has a value of either true or false that shows the initial value of the selected HTML attribute, indicating whether the option is selected by default or not.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionElement/defaultSelected>

=head2 disabled

Has a value of either true or false representing the value of the disabled HTML attribute, which indicates that the option is unavailable to be selected. An option can also be disabled if it is a child of an <optgroup> element that is disabled.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionElement/disabled>

=head2 form

Read-only.

Is a L<HTML::Object::DOM::Element::Form> representing the same value as the form of the corresponding <select> element, if the option is a descendant of a <select> element, or C<undef> if none is found.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionElement/form>

=head2 index

Read-only.

Is a long representing the position of the option within the list of options it belongs to, in tree-order. If the option is not part of a list of options, like when it is part of the C<datalist> element, the value is C<undef>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionElement/index>

=head2 label

Read-only.

Is a string that reflects the value of the label HTML attribute, which provides a label for the option. If this attribute is not specifically set, reading it returns the element's text content.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionElement/label>

=head2 selected

Has a value of either true or false that indicates whether the option is currently selected.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionElement/selected>

=head2 text

Is a string that contains the text content of the element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionElement/text>

=head2 value

Is a string that reflects the value of the value HTML attribute, if it exists; otherwise reflects value of the Node.textContent property.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionElement/value>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionElement>, L<Mozilla documentation on option element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/option>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
