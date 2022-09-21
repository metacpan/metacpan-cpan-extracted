##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Button.pm
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
package HTML::Object::DOM::Element::Button;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :button );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'button' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property accessKey inherited

# Note: property autofocus inherited

# Note: property disabled inherited

# Note: property read-only form inherited

# Imported from FormShared
# # Note: property
# sub formAction : lvalue { return( shift->_set_get_form_attribute( 'action', @_ ) ); }
# 
# # Note: property
# sub formEnctype : lvalue { return( shift->_set_get_form_attribute( 'enctype', @_ ) ); }
# 
# # Note: property
# sub formMethod : lvalue { return( shift->_set_get_form_attribute( 'method', @_ ) ); }
# 
# # Note: property
# sub formNoValidate : lvalue { return( shift->_set_get_form_attribute( 'novalidate', @_ ) ); }
# 
# # Note: property
# sub formTarget : lvalue { return( shift->_set_get_form_attribute( 'target', @_ ) ); }

# Note: property labels inherited

# Note: property, but NOT an lvalue method
sub menu { return( shift->_set_get_object( 'menu', 'HTML::Object::DOM::Element::Menu', @_ ) ); }

# Note: property name inherited

# Note: property tabIndex from HTML::Object::DOM::Element

# Note: property type inherited

# Note: property validationMessage inherited

# Note: property validity inherited

# Note: property value inherited

# Note: property willValidate inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Button - HTML Object DOM Button Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Button;
    my $button = HTML::Object::DOM::Element::Button->new || 
        die( HTML::Object::DOM::Element::Button->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides properties and methods (beyond the regular L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating <button> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Button |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 accessKey

Is a string indicating the single-character keyboard key to give access to the button.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/accessKey>

=head2 autofocus

Is a boolean value indicating whether or not the control should have input focus when the page loads, unless the user overrides it, for example by typing in a different control. Only one form-associated element in a document can have this attribute specified.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/autofocus>

=head2 disabled

Is a boolean value indicating whether or not the control is disabled, meaning that it does not accept any clicks.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/disabled>

=head2 form

Read-only.

Is a L<HTML::Object::DOM::Element::Form> reflecting the form that this button is associated with. If the button is a descendant of a form element, then this property is the L<object|HTML::Object::DOM::Element::Form> of that form element.
If the button is not a descendant of a L<form element|HTML::Object::DOM::Element::Form>, then the property can be the object of any form element in the same document it is related to, or the C<undef> value if none matches.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/form>

=head2 formAction

Is a string reflecting the L<URI> of a resource that processes information submitted by the button. If specified, this property overrides the action attribute of the <form> element that owns this element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/formAction>

=head2 formEnctype

Is a string reflecting the type of content that is used to submit the form to the server. If specified, this property overrides the enctype attribute of the <form> element that owns this element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/formEnctype>

=head2 formMethod

Is a string reflecting the HTTP method that the browser uses to submit the form. If specified, this property overrides the method attribute of the <form> element that owns this element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/formMethod>

=head2 formNoValidate

Is a boolean value indicating that the form is not to be validated when it is submitted. If specified, this property overrides the novalidate attribute of the <form> element that owns this element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/formNoValidate>

=head2 formTarget

Is a string reflecting a name or keyword indicating where to display the response that is received after submitting the form. If specified, this property overrides the target attribute of the <form> element that owns this element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/formTarget>

=head2 labels

Read-only.

Is a NodeList that represents a list of <label> elements that are labels for this button.

Example:

    <label id="label1" for="test">Label 1</label>
    <button id="test">Button</button>
    <label id="label2" for="test">Label 2</label>

    $doc->addEventListener( load => sub
    {
        my $button = $doc->getElementById("test");
        for( my $i = 0; $i < $button->labels->length; $i++ )
        {
            say( $button->labels->[$i]->textContent ); # "Label 1" and "Label 2"
        }
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/labels>

=head2 menu

Is a L<HTML::Object::DOM::Element::Menu> representing the menu element to be displayed if the button is clicked and is of type="menu".

Be careful that you cannot use this as an lvalue method. So you can only write:

    $button->menu( $menu_object );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/menu>

=head2 name

Is a string representing the name of the object when submitted with a form. If specified, it must not be the empty string.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/name>

=head2 tabIndex

Is a long that represents this element's position in the tabbing order.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/tabIndex>

=head2 type

Is a string indicating the behavior of the button. This is an enumerated attribute with the following possible values:

=over 4

=item submit

The button submits the form. This is the default value if the attribute is not specified, or if it is dynamically changed to an empty or invalid value.

=item reset

The button resets the form.

=item button

The button does nothing.

=item menu

The button displays a menu.

=back

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/type>

=head2 validationMessage

Read-only.

Is a string representing the localized message that describes the validation constraints that the control does not satisfy (if any). This attribute is the empty string if the control is not a candidate for constraint validation (willValidate is false), or it satisfies its constraints.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/validationMessage>

=head2 validity

Read-only.

Is a L<ValidityState|HTML::Object::DOM::ValidityState> object representing the validity states that this button is in.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/validity>

=head2 value

Is a string representing the current form control value of the button.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/value>

=head2 willValidate

Read-only.

Is a boolean value indicating whether the button is a candidate for constraint validation. It is false if any conditions bar it from constraint validation, including: its type property is reset or button; it has a <datalist> ancestor; or the disabled property is set to true.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/willValidate>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement>, Mozilla documentation on button element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
