##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Form.pm
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
package HTML::Object::DOM::Element::Form;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :form );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{checkValidity} = 1;
    $self->{reportValidity} = 1;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'form' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property attribute
sub acceptCharset : lvalue { return( shift->_set_get_property( 'accept-charset', @_ ) ); }

# Note: property attribute
sub action : lvalue { return( shift->_set_get_property( 'action', @_ ) ); }

# Note: property accept inherited

# Note: property autocapitalize inherited

# Note: method checkValidity inherited

# Note: property read-only
# Same as in HTML::Object::DOM::FieldSet
sub elements
{
    my $self = shift( @_ );
    my $children = $self->children;
    # my $form_elements = $self->new_array( [qw( button datalist fieldset input label legend meter optgroup option output progress select textarea )] );
    # <https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/elements#value>
    my $form_elements = $self->new_array( [qw( button fieldset input object output select textarea )] );
    my $list = $form_elements->as_hash;
    my $results = $children->grep(sub{ exists( $form_elements->{ $_->tag } ) });
    my $col = $self->new_collection;
    $col->push( $results->list );
    return( $col );
}

# Note: property
sub encoding : lvalue { return( shift->_set_get_property( 'encoding', @_ ) ); }

# Note: property
sub length : lvalue { return( shift->_set_get_property( 'length', @_ ) ); }

# Note: property
sub method : lvalue { return( shift->_set_get_property( 'method', @_ ) ); }

# Note: property name inherited

# Note: property
sub noValidate : lvalue { return( shift->_set_get_property( { attribute => 'novalidate', is_boolean => 1 }, @_ ) ); }

sub requestSubmit { return( shift->_set_get_object_without_init( 'requestSubmit', 'HTML::Object::DOM::Element', @_ ) ); }

# Note: method reportValidity inherited

sub submit { return; }

# Note: property target
sub target : lvalue { return( shift->_set_get_property( { attribute => 'target', is_uri => 1 }, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Form - HTML Object DOM Form Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Form;
    my $form = HTML::Object::DOM::Element::Form->new || 
        die( HTML::Object::DOM::Element::Form->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface represents a <form> element in the DOM. It allows access to—and, in some cases, modification of—aspects of the form, as well as access to its component elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Form |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 acceptCharset

A string reflecting the value of the form's accept-charset HTML attribute, representing the character encoding that the server accepts.

Example:

    <form action="/some/where" accept-charset="utf-8">
        <button>Ok</button>
    </form>

    my $inputs = $doc->forms->[0]->acceptCharset; # utf-8

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/acceptCharset>

=head2 action

A string reflecting the value of the form's action HTML attribute, containing the URI of a program that processes the information submitted by the form.

Example:

    var $form = $doc->forms->[0];
    $form->action = '/cgi-bin/publish';

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/action>

=head2 autocomplete

A string (C<on> or C<off>) reflecting the value of the form's autocomplete HTML attribute, indicating whether the controls in this form can have their values automatically populated by the browser.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/autocomplete>

=head2 elements

Read-only.

A L<collection object|HTML::Object::DOM::Collection> holding all L<form controls|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/elements> belonging to this form element.

Example:

    <form id="my-form">
        <input type="text" name="username">
        <input type="text" name="full-name">
        <input type="password" name="password">
    </form>

    my $inputs = $doc->getElementById("my-form")->elements;
    my $inputByIndex = $inputs->[0];
    my $inputByName = $inputs->username;

Another example:

    my $inputs = $doc->getElementById("my-form")->elements;

    # Iterate over the form controls
    for( my $i = 0; $i < $inputs->length; $i++ )
    {
        if( $inputs->[i]->nodeName == "INPUT" && $inputs->[i]->type == "text" )
        {
            # Update text input
            $inputs->[i]->value->toLocaleUpperCase();
        }
    }

Another example:

    my $inputs = $doc->getElementById("my-form")->elements;

    # Iterate over the form controls
    for( my $i = 0; $i < $inputs->length; $i++ )
    {
        # Disable all form controls
        $inputs->[$i]->setAttribute( "disabled", "" );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/elements>, L<StackOverflow question|https://stackoverflow.com/questions/34785743/javascript-about-form-elements>

=head2 encoding

A string reflecting the value of the form's enctype HTML attribute, indicating the type of content that is used to transmit the form to the server. Only specified values can be set. The two properties are synonyms.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/encoding>

=head2 length

Read-only.

A long reflecting the number of controls in the form.

Example:

    if( $doc->getElementById('form1')->length > 1 )
    {
        # more than one form control here
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/length>

=head2 method

A string reflecting the value of the form's method HTML attribute, indicating the HTTP method used to submit the form. Only specified values can be set.

Example:

    $doc->forms->myform->method = 'post';

    my $formElement = $doc->createElement("form"); # Create a form
    $doc->body->appendChild( $formElement );
    say( $formElement->method ); # 'get'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/method>

=head2 name

A string reflecting the value of the form's name HTML attribute, containing the name of the form.

Example:

    my $string = form->name;
    form->name = $string;

    my $form1name = $doc->getElementById('form1').name;

    if ($form1name != $doc->form->form1) {
        # Browser does not support this form of reference
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/name>

=head2 noValidate

A boolean value reflecting the value of the form's novalidate HTML attribute, indicating whether the form should not be validated.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/noValidate>

=head2 target

A URL reflecting the value of the form's target HTML attribute, indicating where to display the results received from submitting the form.

Example:

    $myForm->target = $doc->frames->[1]->name;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/target>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 checkValidity

In perl, this always returns true, or whatever value you would have set.

In JavaScript environment, this returns true if the element's child controls are subject to constraint validation and satisfy those constraints; returns false if some controls do not satisfy their constraints. Fires an event named invalid at any control that does not satisfy its constraints; such controls are considered invalid if the event is not canceled. It is up to the programmer to decide how to respond to false.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/checkValidity>

=head2 reportValidity

In perl, this always returns true, or whatever value you would have set.

In JavaScript environment, this returns true if the element's child controls satisfy their validation constraints. When false is returned, cancelable invalid events are fired for each invalid child and validation problems are reported to the user.

Example:

    $doc->forms->myform->addEventListener( submit => sub
    {
        $doc->forms->myform->reportValidity();
    }, { capture => 0 });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/reportValidity>

=head2 requestSubmit

Requests that the form be submitted using the specified L<submit button|HTML::Object::DOM::Element> object and its corresponding configuration.

Example:

    my $myForm = $doc->querySelector( 'form' );
    my $submitButton = $myForm->querySelector( '#main-submit' );

    if( $myForm->requestSubmit )
    {
        if( $submitButton )
        {
            $myForm->requestSubmit( $submitButton );
        }
        else
        {
            $myForm->requestSubmit();
        }
    }
    else
    {
        $myForm->submit();
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/requestSubmit>

=head2 submit

This does nothing and returns C<undef> under perl environment.

In JavaScript environment, this submits the form to the server.

Example:

    $doc->forms->myform->submit();

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement>, L<Mozilla documentation on form element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
