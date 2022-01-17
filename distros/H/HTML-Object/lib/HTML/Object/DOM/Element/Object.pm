##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Object.pm
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
package HTML::Object::DOM::Element::Object;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :object );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'object' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property align inherited

# Note: property archive
sub archive : lvalue { return( shift->_set_get_property( 'archive', @_ ) ); }

# Note: property border
sub border : lvalue { return( shift->_set_get_property( 'border', @_ ) ); }

# Note: object method checkValidity inherited

# Note: property code
sub code : lvalue { return( shift->_set_get_property( 'code', @_ ) ); }

# Note: property codeBase
sub codeBase : lvalue { return( shift->_set_get_property( 'codebase', @_ ) ); }

# Note: property codeType
sub codeType : lvalue { return( shift->_set_get_property( 'codetype', @_ ) ); }

# Note: property contentDocument read-only
sub contentDocument : lvalue { return( shift->_set_get_object_lvalue( 'contentdocument', 'HTML::Object::DOM::Document', @_ ) ); }

# Note: property contentWindow read-only
sub contentWindow : lvalue { return( shift->_set_get_object_lvalue( 'contentwindow', 'HTML::Object::DOM::WindowProxy', @_ ) ); }

# Note: property data
sub data : lvalue { return( shift->_set_get_property( { attribute => 'data', is_uri => 1 }, @_ ) ); }

# Note: property declare
sub declare : lvalue { return( shift->_set_get_property( { attribute => 'declare', is_boolean => 1 }, @_ ) ); }

# Note: property form read-only
sub form
{
    my $self = shift( @_ );
    my $id = $self->attr( 'form' );
    return if( !defined( $id ) || !CORE::length( "$id" ) );
    my $root = $self->root;
    return if( !$root );
    my $form = $root->getElementById( $id );
    return( $form );
}

# Note: property height inherited

# Note: property hspace
sub hspace : lvalue { return( shift->_set_get_property( 'hspace', @_ ) ); }

# Note: property name inherited

# Note: method setCustomValidity inherited

# Note: property standby
sub standby : lvalue { return( shift->_set_get_property( 'standby', @_ ) ); }

# Note: property type inherited

# Note: property typemustmatch
sub typemustmatch : lvalue { return( shift->_set_get_property( { attribute => 'type', is_boolean => 1 }, @_ ) ); }

# Note: property useMap inherited

# Note: property validationMessage read-only inherited

# Note: property validity read-only inherited

# Note: property vspace
sub vspace : lvalue { return( shift->_set_get_property( 'vspace', @_ ) ); }

# Note: property width inherited

# Note: property willValidate read-only inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Object - HTML Object DOM Object Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Object;
    my $object = HTML::Object::DOM::Element::Object->new || 
        die( HTML::Object::DOM::Element::Object->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties and methods (beyond those on the L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating the layout and presentation of C<<object>> element, representing external resources.

It is now deprecated and similarly to L<<video>|HTML::Object::DOM::Element::Video> and L<<audio>|HTML::Object::DOM::Element::Audio> tags, HTML object tag was used to enable embedding multimedia files into the web page, such as audio, video, Flash, PDF, ActiveX, and Java Applets.

    <object width="300" height="200" data="https://example.org/some/where/image.png" type="image/png">Image not found.</object>

    <object data="document.pdf" width="500" height="350" type="application/pdf"></object>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Object |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 align

Is a string representing an enumerated property indicating alignment of the element's contents with respect to the surrounding context. The possible values are C<left>, C<right>, C<justify>, and C<center>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/align>

=head2 archive

Is a string that reflects the archive HTML attribute, containing a list of archives for resources for this object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/archive>

=head2 border

Is a string that reflects the border HTML attribute, specifying the width of a border around the object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/border>

=head2 code

Is a string representing the name of an applet class file, containing either the applet's subclass, or the path to get to the class, including the class file itself.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/code>

=head2 codeBase

Is a string that reflects the codebase HTML attribute, specifying the base path to use to resolve relative URIs.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/codeBase>

=head2 codeType

Is a string that reflects the codetype HTML attribute, specifying the content type of the data.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/codeType>

=head2 contentDocument

Normally this is a read-only property, but under perl, you can set or get a L<HTML::Object::DOM::Document> object.

Under JavaScript, this returns a L<Document|HTML::Object::DOM::Document> representing the active document of the object element's nested browsing context, if any; otherwise C<undef>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/contentDocument>

=head2 contentWindow

Normally this returns C<undef> under perl, but you can set it to a L<HTML::Object::DOM::WindowProxy> object.

Under JavaScript, this is a read-only property that returns a C<WindowProxy> representing the window proxy of the object element's nested browsing context, if any; otherwise C<undef>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/contentWindow>

=head2 data

Sets or gets an L<URI> object.

This returns a string, turned into an L<URI>, that reflects the data HTML attribute, specifying the address of a resource's data.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/data>

=head2 declare

Is a boolean value that reflects the declare HTML attribute, indicating that this is a declaration, not an instantiation, of the object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/declare>

=head2 form

Read-only.

Returns a L<HTML::Object::DOM::Element::Form> representing the object element's form owner, or C<undef> if there is not one.

Example:

    <form action="/some/where/script.pl" id="form1">
        Email: <input type="text" name="email" /><br />
        <input type="submit" value="Submit" />
    </form>

    <object form="form1" width="300" height="200" data="https://example.org/some/where/image.png" type="image/png">Image not found.</object>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/form>

=head2 height

Returns a string that reflects the height HTML attribute, specifying the displayed height of the resource in CSS pixels.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/height>

=head2 hspace

Is a long representing the horizontal space in pixels around the control.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/hspace>

=head2 name

Returns a string that reflects the name HTML attribute, specifying the name of the browsing context.

Example:

    <object data="document.pdf" width="300" height="200" name="board_resolution">Alternate text.</object>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/name>

=head2 standby

Is a string that reflects the standby HTML attribute, specifying a message to display while the object loads.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/standby>

=head2 type

Is a string that reflects the type HTML attribute, specifying the MIME type of the resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/type>

=head2 typemustmatch

C<typemustmatch> indicates that the resource should only be embedded if the value of the type attribute matches with the type of the resource provided in the data attribute.

    <object data="flashFile.swf" type="image/png" width="550" height="450" typemustmatch></object>

=head2 useMap

Is a string that reflects the usemap HTML attribute, specifying a <map> element to use.

Example:

    <img src="image.png" width="320" height="320" alt="Dinosaurs" usemap="#dinosaursmap" />

    <map name="dinosaursmap">
        <area shape="rect" coords="34,44,270,350" alt="Pterodactyl" href="https://example.org/tag/Pterodactyl" />
        <area shape="rect" coords="290,172,333,250" alt="Triceratop" href="https://example.org/tag/Triceratop" />
        <area shape="circle" coords="337,300,44" alt="Tyrannosaurus" href="https://example.org/tag/Tyrannosaurus" />
    </map>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/useMap>

=head2 validationMessage

Normally this is read-only, but under perl you can set whatever string value you want.

Under JavaScript, this returns a string representing a localized message that describes the validation constraints that the control does not satisfy (if any). This is the empty string if the control is not a candidate for constraint validation (willValidate is false), or it satisfies its constraints.

Example:

    my $String = HTMLObjectElement->validationMessage;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/validationMessage>

=head2 validity

Read-only.

Returns a L<HTML::Object::DOM::ValidityState> with the validity states that this element is in.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/validity>

=head2 vspace

Is a long representing the horizontal space in pixels around the control.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/vspace>

=head2 width

Is a string that reflects the width HTML attribute, specifying the displayed width of the resource in CSS pixels.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/width>

=head2 willValidate

Normally this is read-only, but under perl you can set whatever boolean value you want.

Under JavaScript, this returns a boolean value that indicates whether the element is a candidate for constraint validation. Always false for L<HTML::Object::DOM::Element::Object> objects.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/willValidate>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 checkValidity

Normally this is read-only, but under perl you can set whatever boolean value you want.

Under JavaScript, this returns a boolean value that always is true, because object objects are never candidates for constraint validation.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/checkValidity>

=head2 setCustomValidity

Sets a custom validity message for the element. If this message is not the empty string, then the element is suffering from a custom validity error, and does not validate.

Returns a L<scalar object|Module::Generic::Scalar>

Example:

    use feature 'signatures';
    sub validate( $inputID )
    {
        my $input = $doc->getElementById( $inputID );
        my $validityState = $input->validity;

        if( $validityState->valueMissing )
        {
            $input->setCustomValidity( 'You gotta fill this out, yo!' );
        }
        elsif( $validityState->rangeUnderflow )
        {
            $input->setCustomValidity( 'We need a higher number!' );
        }
        elsif( $validityState->rangeOverflow )
        {
            $input->setCustomValidity( 'Thats too high!' );
        }
        else
        {
            $input->setCustomValidity( '' );
        }
        $input->reportValidity();
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/setCustomValidity>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement>, L<Mozilla documentation on object element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/object>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
