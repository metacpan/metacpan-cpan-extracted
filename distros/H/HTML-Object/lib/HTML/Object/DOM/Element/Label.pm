##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Label.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2021/12/23
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Label;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :label );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'label' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property read-only
sub control
{
    my $self = shift( @_ );
    my $id = $self->htmlFor;
    # return if( !defined( $id ) || !CORE::length( "$id" ) );
    if( defined( $id ) && CORE::length( "$id" ) )
    {
        my $root = $self->root;
        my $elem = $root->look_down( id => $id )->first;
        return if( !defined( $elem ) || !ref( $elem ) );
        return( $elem );
    }
    # "If the for attribute is not specified, but the label element has a labelable element descendant, then the first such descendant in tree order is the label element's labeled control."
    # <https://html.spec.whatwg.org/multipage/forms.html#htmllabelelement>
    else
    {
        my $elems = $self->look_down( _tag => qr/(?:button|input|meter|output|progress|select|textarea)/ );
        my $elem;
        $elems->foreach(sub
        {
            my $tag = $_->tag;
            if( $tag ne 'input' ||
                ( $tag eq 'input' && lc( $_->attr( 'type' ) // '' ) ne 'hidden' ) )
            {
                $elem = $_, return;
            }
        });
        return( $elem );
    }
}

# Note: property form is NOT inherited, because this is the 'form' value of the associated control, if any.
sub form
{
    my $self = shift( @_ );
    my $elem = $self->control;
    return if( !$self->_is_a( $elem => 'HTML::Object::DOM::Element' ) );
    return( $elem->form );
}

# Note: property
# labelable elements:
# "button, input (if the type attribute is not in the Hidden state) meter, output, progress, select, textarea, form-associated custom elements"
# <https://html.spec.whatwg.org/multipage/forms.html#category-label>
sub htmlFor : lvalue { return( shift->_set_get_property( 'for', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Label - HTML Object DOM Label Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Label;
    my $label = HTML::Object::DOM::Element::Label->new || 
        die( HTML::Object::DOM::Element::Label->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface gives access to properties specific to <label> elements. It inherits methods and properties from the base L<HTML::Object::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Label |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 control

Read-only.

Is a L<HTML::Object::Element> representing the control with which the label is associated. It returns C<undef> if the C<for> attribute has no id set, or no associated element could be found in the DOM.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLabelElement/control>

=head2 form

Read-only.

Is a L<HTML::Object::DOM::Element::Form> object representing the form with which the labeled control is associated, or C<undef> if there is no associated control, or if that control is not associated with a form. In other words, this is just a shortcut for:

    $e->control->form

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLabelElement/form>

=head2 htmlFor

Is a string containing the ID of the labeled control. This reflects the for attribute.

Example:

    <label for="inputId">Enter your name</label>
    my $label = $doc->getElementsByTagName( 'label' )->first;
    say( "ID is: ", $label->htmlFor );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLabelElement/htmlFor>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLabelElement>, L<Mozilla documentation on label element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/label>, L<W3C specificatins|https://html.spec.whatwg.org/multipage/forms.html#htmllabelelement>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
