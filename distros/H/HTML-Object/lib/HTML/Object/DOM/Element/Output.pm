##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Output.pm
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
package HTML::Object::DOM::Element::Output;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :output );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{defaultvalue} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'output' if( !CORE::length( "$self->{tag}" ) );
    $self->{type} = 'output';
    $self->_set_get_internal_attribute_callback( 'for' => sub
    {
        my( $this, $val ) = @_;
        my $list;
        return if( !( $list = $this->{_for_list} ) );
        # $list->debug( $self->debug );
        $list->update( $val );
    });
    return( $self );
}

# Note: method checkValidity inherited

# Note: property defaultValue
sub defaultValue : lvalue { return( shift->_set_get_property( 'defaultvalue', @_ ) ); }

# Note: property form read-only inherited

# Note: property htmlFor read-only
sub htmlFor
{
    my $self = shift( @_ );
    unless( $self->{_for_list} )
    {
        my $for = $self->attr( 'for' );
        require HTML::Object::TokenList;
        $self->{_for_list} = HTML::Object::TokenList->new( $for, element => $self, attribute => 'for', debug => $self->debug ) ||
            return( $self->pass_error( HTML::Object::TokenList->error ) );
    }
    return( $self->{_for_list} );
}

# Note: property labels read-only inherited

# Note: property name inherited

# Note: method reportValidity inherited

# Note: method setCustomValidity inherited

# Note: property type read-only inherited

# Note: property validationMessage read-only inherited

# Note: property validity read-only inherited

# Note: property value
{
    no warnings 'redefine';
    sub value : lvalue { return( shift->textContent( @_ ) ); }
}

# Note: property willValidate read-only inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Output - HTML Object DOM Output Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Output;
    my $output = HTML::Object::DOM::Element::Output->new || 
        die( HTML::Object::DOM::Element::Output->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides properties and methods (beyond those inherited from L<HTML::Object::Element>) for manipulating the layout and presentation of C<<output>> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Output |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 defaultValue

A string representing the default value of the element, initially the empty string.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/defaultValue>

=head2 form

Read-only.

An L<HTML::Object::DOM::Element::Form> indicating the form associated with the control, reflecting the form HTML attribute if it is defined.

Example:

    <form
        action="/action_page.php"
        id="numform"
        oninput="x.value=parseInt(a.value)+parseInt(b.value)">
        <input type="range" id="a" name="a" value="50" />
        + <input type="number" id="b" name="b" value="25" />
        <input type="submit" />
    </form>

    <output form="numform" id="x" name="x" for="a b"></output> 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/form>

=head2 htmlFor

Read-only.

A L<TokenList|HTML::Object::TokenList> reflecting the for HTML attribute, containing a list of IDs of other elements in the same document that contribute to (or otherwise affect) the calculated value.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/htmlFor>

=head2 labels

Read-only.

Returns a L<HTML::Object::DOM::NodeList> of L<<label>|HTML::Object::DOM::Element::Label> elements associated with the element.

Example:

    <label id="label1" for="test">Label 1</label>
    <output id="test">Output</output>
    <label id="label2" for="test">Label 2</label>

    use HTML::Object::DOM qw( window );
    window->addEventListener( DOMContentLoaded => sub
    {
        my $output = $doc->getElementById( 'test' );
        for( my $i = 0; $i < $output->labels->length; $i++ )
        {
            say( $output->labels->[$i]->textContent ); # "Label 1" and "Label 2"
        }
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/labels>

=head2 name

A string reflecting the name HTML attribute, containing the name for the control that is submitted with form data.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/name>

=head2 type

Normally this is read-only, but under perl you can set whatever string value you want. By default the value is C<output>.

Under JavaScript, this is a read-only property that returns the string C<output>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/type>

=head2 validationMessage

Read-only.

A string representing a localized message that describes the validation constraints that the control does not satisfy (if any). This is the empty string if the control is not a candidate for constraint validation (willValidate is false), or it satisfies its constraints.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/validationMessage>

=head2 validity

Read-only.

A C<ValidityState> representing the validity states that this element is in.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/validity>

=head2 value

A string representing the value of the contents of the elements. Behaves like the L<HTML::Object::DOM::Node/textContent> property.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/value>

=head2 willValidate

Read-only.

A boolean value indicating whether the element is a candidate for constraint validation.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/willValidate>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 checkValidity

Checks the validity of the element and returns a boolean value holding the check result.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/checkValidity>

=head2 reportValidity

This method reports the problems with the constraints on the element, if any, to the user. If there are problems, fires an invalid event at the element, and returns false; if there are no problems, it returns true.
When the problem is reported, the user agent may focus the element and change the scrolling position of the document or perform some other action that brings the element to the user's attention. User agents may report more than one constraint violation if this element suffers from multiple problems at once. If the element is not rendered, then the user agent may report the error for the running script instead of notifying the user.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/reportValidity>

=head2 setCustomValidity

Sets a custom validity message for the element. If this message is not the empty string, then the element is suffering from a custom validity error, and does not validate.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement/setCustomValidity>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOutputElement>, L<Mozilla documentation on output element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/output>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
