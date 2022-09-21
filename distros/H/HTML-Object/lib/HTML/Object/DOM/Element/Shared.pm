##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Shared.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/25
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Shared;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( @EXPORT_OK %EXPORT_TAGS $VERSION );
    use Exporter qw( import );
    our @EXPORT_OK = qw(
        accept accessKey align allowdirs alt autocapitalize autocomplete autofocus checked checkValidity compact crossOrigin currentSrc defaultChecked defaultValue dirName disabled download files form formAction formEnctype formMethod formNoValidate formTarget hash height host hostname href hreflang indeterminate inputmode labels list max maxLength min minLength multiple name origin password pathname pattern placeholder port protocol readOnly referrerPolicy rel relList reportValidity required selectionDirection selectionEnd selectionStart search setCustomValidity size src step target type useMap username value validationMessage validity valueAsDate valueAsNumber webkitdirectory webkitEntries willValidate width
    );
    our %EXPORT_TAGS = (
        anchor  => [qw( download hash host hostname href hreflang origin password pathname port protocol referrerPolicy rel relList search target username )],
        area    => [qw( accessKey alt download hash host hostname href hreflang origin password pathname port protocol referrerPolicy rel relList search target username )],
        base    => [qw( href target )],
        button  => [qw(
            form formAction formEnctype formMethod formNoValidate formTarget
            accessKey autofocus disabled form labels name type validationMessage validity value willValidate
        )],
        canvas  => [qw( height width )],
        caption => [qw( align )],
        dir     => [qw( compact )],
        div     => [qw( align )],
        dl      => [qw( compact )],
        embed   => [qw( align height name src width )],
        fieldset    => [qw( disabled checkValidity form name reportValidity setCustomValidity validationMessage validity willValidate )],
        form    => [qw(
            accept autocapitalize autocomplete name
            
            checkValidity reportValidity
        )],
        heading => [qw( align )],
        hr      => [qw( align size width )],
        iframe  => [qw( align height name referrerPolicy src width )],
        img     => [qw( alt crossOrigin currentSrc height referrerPolicy src useMap width )],
        input   => [qw(
            accept accessKey align allowdirs alt autocapitalize autocomplete autofocus checked 
            defaultChecked defaultValue dirName disabled files form 
            formAction formEnctype formMethod formNoValidate formTarget height indeterminate 
            inputmode labels list max maxLength min minLength multiple name pattern placeholder 
            readOnly required selectionDirection selectionEnd selectionStart size src step 
            type useMap validationMessage validity value valueAsDate valueAsNumber 
            webkitEntries webkitdirectory width willValidate
        )],
        label   => [qw( form )],
        legend  => [qw( accessKey align form )],
        li      => [qw( type value )],
        'link'  => [qw( crossOrigin disabled href hreflang referrerPolicy rel relList type )],
        'map'   => [qw( name )],
        marquee => [qw( height width )],
        media   => [qw( crossOrigin currentSrc src )],
        menu    => [qw( compact type )],
        meter   => [qw( labels max min value )],
        object  => [qw( align checkValidity height name setCustomValidity type useMap validity validationMessage width willValidate )],
        ol      => [qw( compact type )],
        optgroup    => [qw( disabled )],
        option  => [qw( disabled form )],
        output  => [qw( checkValidity form labels setCustomValidity type validity validationMessage value willValidate )],
        paragraph   => [qw( align )],
        param   => [qw( name type value )],
        pre     => [qw( width )],
        progress    => [qw( labels value )],
        script  => [qw( crossOrigin src referrerPolicy type )],
        'select'    => [qw( checkValidity disabled form labels name reportValidity required setCustomValidity type validationMessage validity value willValidate )],
        slot    => [qw( name )],
        source  => [qw( src type )],
        style   => [qw( disabled type )],
        table   => [qw( align width )],
        tablecaption    => [qw( align )],
        tablecell   => [qw( align height width )],
        tablecol    => [qw( align width )],
        tablerow    => [qw( align )],
        tablesection    => [qw( align )],
        track   => [qw( src )],
        ulist   => [qw( compact type )],
        video   => [qw( height width )],
    );
    $EXPORT_TAGS{all} = [@EXPORT_OK];
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

# Note: property for input
sub accept : lvalue { return( shift->_set_get_property( 'accept', @_ ) ); }

# Note: property for input
sub accessKey : lvalue { return( shift->_set_get_property( 'accesskey', @_ ) ); }

# Note: property for embed
sub align : lvalue { return( shift->_set_get_property( 'align', @_ ) ); }

# Note: property for input
sub allowdirs : lvalue { return( shift->_set_get_boolean( 'allowdirs', @_ ) ); }

# Note: property for img, input
sub alt : lvalue { return( shift->_set_get_property( 'alt', @_ ) ); }

# Note: property for input
sub autocapitalize : lvalue { return( shift->_set_get_property( 'autocapitalize', @_ ) ); }

# Note: property for input
sub autocomplete : lvalue { return( shift->_set_get_property( 'autocomplete', @_ ) ); }

# Note: property for input
sub autofocus : lvalue { return( shift->_set_get_property( { attribute => 'autofocus', is_boolean => 1 }, @_ ) ); }

# Note: property boolean for input
sub checked : lvalue { return( shift->_set_get_property( { attribute => 'checked', is_boolean => 1 }, @_ ) ); }

# Note: method
sub checkValidity { return( shift->_set_get_boolean( 'checkValidity', @_ ) ); }

# Note: property
sub compact : lvalue { return( shift->_set_get_property( { attribute => 'compact', is_boolean => 1 }, @_ ) ); }

# Note: property
sub crossOrigin : lvalue { return( shift->_set_get_property( 'crossorigin', @_ ) ); }

# Note: property
sub currentSrc : lvalue { return( shift->_set_get_property( 'currentsrc', @_ ) ); }

# Note: property boolean for input
sub defaultChecked : lvalue { return( shift->_set_get_property( { attribute => 'defaultchecked', is_boolean => 1 }, @_ ) ); }

# Note: property for input
sub defaultValue : lvalue { return( shift->_set_get_property( 'value', @_ ) ); }

# Note: property for input
sub dirName { return( shift->_set_get_scalar_as_object( 'dirName', @_ ) ); }

# Note: property for input
sub disabled : lvalue { return( shift->_set_get_property( { attribute => 'disabled', is_boolean => 1 }, @_ ) ); }

# Note: property for anchor, area
sub download : lvalue { return( shift->_set_get_property( 'download', @_ ) ); }

# Note: property for input
sub files { return( shift->_set_get_object( 'files', 'HTML::Object::DOM::FileList' ) ); }

# Note: property read-only
sub form
{
    my $self = shift( @_ );
    # If the element has a 'form' attribute containing the form it, we use it to find the specific form, otherwise we search for the parent form
    my $id = $self->attr( 'form' );
    if( defined( $id ) && CORE::length( "$id" ) )
    {
        my $root = $self->root;
        return if( !defined( $root ) );
        # my $form = $root->getElementById( $id );
        my $forms = $root->look_down( _tag => 'form', id => $id );
        return( $forms->first );
    }
    else
    {
        return( $self->_get_parent_form );
    }
}

# Note: property for input
sub formAction : lvalue { return( shift->_set_get_form_attribute( 'action', @_ ) ); }

# Note: property for input
sub formEnctype : lvalue { return( shift->_set_get_form_attribute( 'enctype', @_ ) ); }

# Note: property for input
sub formMethod : lvalue { return( shift->_set_get_form_attribute( 'method', @_ ) ); }

# Note: property for input
sub formNoValidate : lvalue { return( shift->_set_get_form_attribute( 'novalidate', @_ ) ); }

# Note: property for input
sub formTarget : lvalue { return( shift->_set_get_form_attribute( 'target', @_ ) ); }

# Note: property for anchor
sub hash : lvalue { return( shift->_set_get_uri_property( 'hash', @_ ) ); }

# Note: property for input
sub height : lvalue { return( shift->_set_get_property( 'height', @_ ) ); }

# Note: property for anchor
sub host : lvalue { return( shift->_set_get_uri_property( 'host', @_ ) ); }

# Note: property for anchor
sub hostname : lvalue { return( shift->_set_get_uri_property( 'hostname', @_ ) ); }

# Note: property for anchor
sub href : lvalue { return( shift->_set_get_property( { attribute => 'href', is_uri => 1 }, @_ ) ); }

# Note: property for anchor
sub hreflang : lvalue { return( shift->_set_get_property( 'hreflang', @_ ) ); }

# Note: property boolean for input
sub indeterminate : lvalue { return( shift->_set_get_property( { attribute => 'indeterminate', is_boolean => 1 }, @_ ) ); }

#Note: property for input
sub inputmode : lvalue { return( shift->_set_get_property( 'inputmode', @_ ) ); }

# Note: property
sub labels
{
    my $self = shift( @_ );
    my $results = $self->new_array;
    # No need to go further really
    my $id = $self->attributes->get( 'id' );
    return( $results ) if( !defined( $id ) || !length( $id ) );
    my $root = $self->root || return( $results );
    $results = $root->look_down( _tag => 'label', 'for' => $id );
    return( $self->new_nodelist( $results ) );
}

# Note: property for input; an element object pointing to <datalist>
sub list
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->_set_get_object_without_init( 'list', 'HTML::Object::DOM::Element', @_ ) );
    }
    else
    {
        return( $self->{list} ) if( ref( $self->{list} ) );
        my $root = $self->root;
        my $id   = $self->attr( 'list' );
        return( $self->new_null ) if( !defined( $id ) );
        my $elem = $root->look_down( _tag => 'datalist', id => $id );
        return( $self->{list} = $elem );
    }
}

# Note: property for input
sub max : lvalue { return( shift->_set_get_property( 'max', @_ ) ); }

# Note: property for input
sub maxLength : lvalue { return( shift->_set_get_property( 'maxlength', @_ ) ); }

# Note: property for input
sub min : lvalue { return( shift->_set_get_property( 'min', @_ ) ); }

# Note: property for input
sub minLength : lvalue { return( shift->_set_get_property( 'minlength', @_ ) ); }

# Note: property boolean for input
sub multiple : lvalue { return( shift->_set_get_property( { attribute => 'multiple', is_boolean => 1 }, @_ ) ); }

# Note: property for input
sub name : lvalue { return( shift->_set_get_property( 'name', @_ ) ); }

# Note: property for anchor
sub origin
{
    my $self = shift( @_ );
    my $uri  = $self->_set_get_anchor_uri;
    # We use ref() and not ->isa on purpose, because URI::https (for example) is a subclass of URI::_generic
    # so ->isa( 'URI::_generic' ) will always return true
    return if( ref( $uri ) eq 'URI::_generic' );
    return if( !$uri->host );
    # The web standard is to return a hostname without its port if it is a standard port, even if it was specified
    # e.g. https://example.org:443 -> https://example.org
    # return( $uri->canonical );
    # I need a way to remove the port if it is standard. URI->canonical gives us that, but also includes the path, which we do not want
    # and we do not want a trailing '/', which canonical adds
    my $origin = URI->new( join( '', $uri->scheme, '://', $uri->host_port ) )->canonical;
    # substr( $origin, -1, 1, '' ) if( substr( $origin, -1, 1 ) eq '/' );
    $origin->path( substr( $origin->path, 0, -1 ) ) if( substr( $origin->path, -1, 1 ) eq '/' );
    return( $origin );
}

# Note: property for anchor
sub password : lvalue { return( shift->_set_get_uri_property( 'password', @_ ) ); }

# Note: property for anchor
sub pathname : lvalue { return( shift->_set_get_uri_property( 'pathname', @_ ) ); }

# Note: property for input
sub pattern : lvalue { return( shift->_set_get_property( 'pattern', @_ ) ); }

# Note: property for input
sub placeholder : lvalue { return( shift->_set_get_property( 'placeholder', @_ ) ); }

# Note: property for anchor
sub port : lvalue { return( shift->_set_get_uri_property( 'port', @_ ) ); }

# Note: property for anchor
sub protocol : lvalue { return( shift->_set_get_uri_property( 'protocol', @_ ) ); }

# Note: property boolean for input
sub readOnly  : lvalue { return( shift->_set_get_property( { attribute => 'readonly', is_boolean => 1 }, @_ ) ); }

# Note: property for anchor
sub referrerPolicy : lvalue { return( shift->_set_get_property( 'referrerpolicy', @_ ) ); }

# Note: property for anchor
sub rel : lvalue { return( shift->_set_get_property( 'rel', @_ ) ); }

# Note: property for anchor
sub relList
{
    my $self = shift( @_ );
    unless( $self->{_rel_list} )
    {
        my $rel  = $self->attr( 'rel' );
        require HTML::Object::TokenList;
        $self->{_rel_list} = HTML::Object::TokenList->new( $rel, element => $self, attribute => 'rel', debug => $self->debug ) ||
            return( $self->pass_error( HTML::Object::TokenList->error ) );
    }
    return( $self->{_rel_list} );
}

# Note: method
sub reportValidity { return( shift->_set_get_boolean( 'reportValidity', @_ ) ); }

# Note: property for input
sub required : lvalue { return( shift->_set_get_property( { attribute => 'required', is_boolean => 1 }, @_ ) ); }

# Note: property for input
sub selectionDirection : lvalue { return( shift->_set_get_property( 'selectiondirection', @_ ) ); }

# Note: property for input
sub selectionEnd : lvalue { return( shift->_set_get_property( 'selectionend', @_ ) ); }

# Note: property for input
sub selectionStart : lvalue { return( shift->_set_get_property( 'selectionstart', @_ ) ); }

# Note: property for anchor
sub search : lvalue { return( shift->_set_get_uri_property( 'search', @_ ) ); }

# Note: method for fieldset, input, object
sub setCustomValidity { return( shift->_set_get_scalar_as_object( 'setcustomvalidity', @_ ) ); }

sub size : lvalue { return( shift->_set_get_property( 'selectionstart', @_ ) ); }

# Note: property for input
sub src : lvalue { return( shift->_set_get_property( { attribute => 'src', is_uri => 1 }, @_ ) ); }

# Note: property for input
sub step : lvalue { return( shift->_set_get_property( 'step', @_ ) ); }

# Note: tabIndex is inherited directly HTML::Object::DOM::Element

# Note: property for anchor
sub target : lvalue { return( shift->_set_get_property( 'target', @_ ) ); }

# Note: property for input
sub type : lvalue { return( shift->_set_get_property( 'type', @_ ) ); }

# Note: property for img, input
sub useMap : lvalue { return( shift->_set_get_property( 'usemap', @_ ) ); }

# Note: property for anchor
sub username : lvalue { return( shift->_set_get_uri_property( 'username', @_ ) ); }

# Note: property for input
sub value : lvalue { return( shift->_set_get_property( 'value', @_ ) ); }

# Note: property read-only for input
sub validationMessage : lvalue { return( shift->_set_get_scalar_as_object( 'validationmessage', @_ ) ); }

# Note: property read-only for input
sub validity { return( shift->_set_get_object( 'validity', 'HTML::Object::DOM::ValidityState', @_ ) ); }

# Note: property for input
sub valueAsDate : lvalue { return( shift->_set_get_property( { attribute => 'value', is_datetime => 1 }, @_ ) ); }

# Note: property for input
sub valueAsNumber : lvalue { return( shift->_set_get_property( { attribute => 'value', is_number => 1 }, @_ ) ); }

# Note: property boolean for input
sub webkitdirectory : lvalue { return( shift->_set_get_property( { attribute => 'webkitdirectory', is_boolean => 1 }, @_ ) ); }

sub webkitEntries { return; }

# Note: property read-only for input
sub willValidate : lvalue { return( shift->_set_get_boolean( 'willvalidate', @_ ) ); }

# Note: property for input
sub width : lvalue { return( shift->_set_get_property( 'width', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Shared - HTML Object DOM Form Shared Code

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Shared qw( :input );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module implements properties and methods shared among several form elements

=head1 PROPERTIES

=head2 accept

Set or return the element's accept attribute, containing comma-separated list of file types accepted by the server when type is file.

=head2 accessKey

Sets or gets the element's attribute representing a string containing a single character that switches input focus to the control when pressed.

=for Pod::Coverage align

=head2 allowdirs

Set or get a boolean value. This does not do anything otherwise since this is not an attribute.

This is part of Mozilla non-standard Directory Upload API. It indicates whether or not to allow directories and files both to be selected in the file list.

=head2 alt

Sets or returns the element's alt attribute, containing alternative text to use when type is image.

=head2 autocapitalize

Defines the capitalization behavior for user input. Valid values are C<none>, C<off>, C<characters>, C<words>, or C<sentences>. 

=head2 autocomplete

Set or returns a string that represents the element's autocomplete attribute, indicating whether the value of the control can be automatically completed by the browser. Ignored if the value of the type attribute is C<hidden>, C<checkbox>, C<radio>, C<file>, or a C<button> type (C<button>, C<submit>, C<reset>, C<image>). Possible values are:

=over 4

=item on

The browser can autocomplete the value using previously stored value

=item off

The user must explicity enter a value

=back

=head2 autofocus

Set or returns a boolean value that represents the element's autofocus attribute, which specifies that a form control should have input focus when the page loads, unless the user overrides it, for example by typing in a different control. Only one form element in a document can have the autofocus attribute. It cannot be applied if the type attribute is set to hidden (that is, you cannot automatically set focus to a hidden control).

=head2 checked

Set or returns a boolean value the current state of the element when type is checkbox or radio.

=for Pod::Coverage compact

=head2 crossOrigin

A string of a keyword specifying the CORS mode to use when fetching the image resource. If you do not specify crossOrigin, the underlying element is fetched without CORS (the fetch no-cors mode).

Permitted values are:

=over 4

=item * C<anonymous>

Requests by the underlying element have their mode set to cors and their credentials mode set to same-origin. This means that CORS is enabled and credentials are sent if the underlying element is fetched from the same origin from which the document was loaded.

=item * C<use-credentials>

Requests by the L<HTML::Object::DOM::Element> will use the cors mode and the include credentials mode; all underlying element requests by the element will use CORS, regardless of what domain the fetch is from.

=back

If crossOrigin is an empty string (""), the anonymous mode is selected. 

See L<Mozilla documentation for more information|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/crossorigin>

=for Pod::Coverage currentSrc

=head2 defaultChecked

Set or returns a boolean value that sets the default state of a radio button or checkbox as originally specified in HTML that created this object.

=for Pod::Coverage defaultValue

=head2 dirName

Sets or gets the directionality of the element.

=head2 disabled

Set or returns a boolean value that represents the element's disabled attribute, indicating that the control is not available for interaction. The input values will not be submitted with the form. See also L</readonly>

=for Pod::Coverage download

=head2 files

This returns a L<HTML::Object::DOM::FileList> object.

Under JavaScript, this returns or accepts a C<FileList> object, which contains a list of C<File> objects representing the files selected for upload.

=head2 form

The C<form> HTML element represents a document section containing interactive controls for submitting information.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form>

=head2 formAction

Is a string reflecting the L<URI> of a resource that processes information submitted by the button. If specified, this property overrides the action attribute of the C<<form>> element that owns this element.

This is used by L<HTML::Object::DOM::Element::Input>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/formAction>

=head2 formEnctype

Is a string reflecting the type of content that is used to submit the form to the server. If specified, this property overrides the enctype attribute of the C<<form>> element that owns this element.

This is used by L<HTML::Object::DOM::Element::Input>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/formEnctype>

=head2 formMethod

Is a string reflecting the HTTP method that the browser uses to submit the form. If specified, this property overrides the method attribute of the <form> element that owns this element.

This is used by L<HTML::Object::DOM::Element::Input>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/formMethod>

=head2 formNoValidate

Is a boolean value indicating that the form is not to be validated when it is submitted. If specified, this property overrides the novalidate attribute of the <form> element that owns this element.

This is used by L<HTML::Object::DOM::Element::Input>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/formNoValidate>

=head2 formTarget

Is a string reflecting a name or keyword indicating where to display the response that is received after submitting the form. If specified, this property overrides the target attribute of the <form> element that owns this element.

This is used by L<HTML::Object::DOM::Element::Input>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLButtonElement/formTarget>

=head2 hash

The hash property of the Location interface returns a string containing a '#' followed by the fragment identifier of the URL — the ID on the page that the URL is trying to target.

The fragment is not percent-decoded. If the URL does not have a fragment identifier, this property contains an empty string, "". 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Location/hash>

=head2 height

Sets or returns the element's height attribute, which defines the height of the image displayed for the button, if the value of type is image.

=head2 host

The host property of the Location interface is a string containing the host, that is the hostname, and then, if the port of the URL is nonempty, a ':', and the port of the URL. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Location/host>

=head2 hostname

The hostname property of the Location interface is a string containing the domain of the URL.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Location/hostname>

=head2 href

The href property of the Location interface is a stringifier that returns a string containing the whole URL, and allows the href to be updated. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Location/href>

=for Pod::Coverage hreflang

=head2 indeterminate

Set or returns a boolean value that describes whether the checkbox or radio button is in indeterminate state. For checkboxes, the effect is that the appearance of the checkbox is obscured/greyed in some way as to indicate its state is indeterminate (not checked but not unchecked). Does not affect the value of the checked attribute, and clicking the checkbox will set the value to false. 

=head2 inputmode

Provides a hint to browsers as to the type of virtual keyboard configuration to use when editing this element or its contents. 

=head2 labels

Returns a list of C<<label>> elements that are labels for this element, as an L<array object|Module::Generic::Array>.

=head2 list

Sets or returns the L<element|HTML::Object::DOM::Element> pointed by the C<list> attribute, which returns an ID. The property may be C<undef> if no HTML element found in the same tree. 

=head2 max

Set or returns a string that represents the element's C<max> attribute, containing the maximum (numeric or date-time) value for this item, which must not be less than its minimum (min attribute) value.

=head2 maxLength

Set or returns an integer that represents the element's C<maxlength> attribute, containing the maximum number of characters (in Unicode code points) that the value can have. (If you set this to a negative number, an exception will be thrown.)

=head2 min

Set or returns a string that represents the element's C<min> attribute, containing the minimum (numeric or date-time) value for this item, which must not be greater than its maximum (max attribute) value.

=head2 minLength

Set or returns an integer that represents the element's C<minlength> attribute, containing the minimum number of characters (in Unicode code points) that the value can have. (If you set this to a negative number, an exception will be thrown.)

=head2 multiple

Sets or returns a boolean that represents the element's multiple attribute, indicating whether more than one value is possible (e.g., multiple files). 

=head2 name

Set or returns the element's name attribute, containing a name that identifies the element when submitting the form.

=for Pod::Coverage origin

=head2 password

The password property of the Location interface is a string containing the password specified before the domain name.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Location/password>

=head2 pathname

The pathname property of the Location interface is a USVString containing the path of the URL for the location, which will be the empty string if there is no path. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Location/pathname>

=head2 pattern

Set or returns a string that represents the element's C<pattern> attribute, containing a regular expression that the control's value is checked against. Use the C<title> attribute to describe the pattern to help the user. This attribute applies when the value of the type attribute is C<text>, C<search>, C<tel>, C<url> or C<email>; otherwise it is ignored.

=head2 placeholder

Set or returns a string that represents the element's C<placeholder> attribute, containing a hint to the user of what can be entered in the control. The C<placeholder> text must not contain carriage returns or line-feeds. This attribute applies when the value of the type attribute is C<text>, C<search>, C<tel>, C<url> or C<email>; otherwise it is ignored.

=for Pod::Coverage port

=for Pod::Coverage protocol

=head2 readOnly

Set or returns a boolean that represents the element's C<readonly> attribute, indicating that the user cannot modify the value of the control.
This is ignored if the value of the type attribute is C<hidden>, C<range>, C<color>, C<checkbox>, C<radio>, C<file>, or a C<button> type.

=for Pod::Coverage referrerPolicy

=head2 rel

The rel attribute defines the relationship between a linked resource and the current document. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel>

=for Pod::Coverage relList

=head2 required

Set or returns a boolean value that represents the element's required attribute, indicating that the user must fill in a value before submitting a form.

=head2 search

The search property of the Location interface is a search string, also called a query string; that is, a USVString containing a '?' followed by the parameters of the URL. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Location/search>

=head2 selectionDirection

Set or returns a string that represents the direction in which selection occurred. Possible values are:

=over 4

=item forward

if selection was performed in the start-to-end direction of the current locale

=item backward

for the opposite direction

=item none

if the direction is unknown

=back

=head2 selectionEnd

Set or returns an integer that represents the end index of the selected text. When there's no selection, this returns the offset of the character immediately following the current text input cursor position.

=head2 selectionStart

Set or returns an integer that represents the beginning index of the selected text. When nothing is selected, this returns the position of the text input cursor (caret) inside of the <input> element.

=for Pod::Coverage setCustomValidity

=head2 size

Set or returns an integer that represents the element's C<size> attribute, containing visual size of the control. This value is in pixels unless the value of type is text or password, in which case, it is an integer number of characters. Applies only when type is set to C<text>, C<search>, C<tel>, C<url>, C<email>, or C<password>; otherwise it is ignored.

=head2 step

Set or returns the element's step attribute, which works with C<min> and C<max> to limit the increments at which a numeric or date-time value can be set. It can be the string any or a positive floating point number. If this is not set to C<any>, the control accepts only values at multiples of the step value greater than the minimum.

=head2 src

Sets or returns the element's src attribute, which specifies a URI for the location of an image to display on the graphical submit button, if the value of type is image; otherwise it is ignored.

=for Pod::Coverage target

=head2 type

Set or returns the element's type attribute, indicating the type of control to display. See type attribute of C<<input>> for possible values.

=for Pod::Coverage useMap

=for Pod::Coverage username

=head2 value

Set or returns the current value of the control.

=head2 valueAsDate

Sets or returns the value of the element, interpreted as a L<DateTime> object, or C<undef> if conversion is not possible.

=head2 valueAsNumber

Returns the value of the L<element|HTML::Object::DOM::Element>, interpreted as one of the following, in order:

=over 4

=item * A time value

=item * A number

=item * C<undef> if conversion is impossible

=back

=head2 validity

Read-only.

L<ValidityState object|HTML::Object::DOM::ValidityState>: Returns the element's current validity state.

=head2 validationMessage

Read-only.

Set or returns a localised message that describes the validation constraints that the control does not satisfy (if any). This is the empty string if the control is not a candidate for constraint validation (willvalidate is false), or it satisfies its constraints. This value can be set by the setCustomValidity method.

=head2 webkitdirectory

A boolean value: Returns the webkitdirectory attribute; if true, the file system picker interface only accepts directories instead of files.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/webkitdirectory>

=head2 webkitEntries

This does nothing under perl, and returns C<undef>

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/webkitEntries>

=head2 width

Sets or returns the element's width attribute, which defines the width of the image displayed for the button, if the value of type is image.

=head2 willValidate

Read-only.

Set or returns a boolean value that describes whether the element is a candidate for constraint validation. It is false if any conditions bar it from constraint validation, including: its type is hidden, reset, or button; it has a <datalist> ancestor; its disabled property is true. 

=head1 METHODS

=head2 checkValidity

In perl, this always returns true, or whatever value you would have set.

In JavaScript environment, this returns true if the element's child controls are subject to constraint validation and satisfy those constraints; returns false if some controls do not satisfy their constraints. Fires an event named invalid at any control that does not satisfy its constraints; such controls are considered invalid if the event is not canceled. It is up to the programmer to decide how to respond to false.

See also L<Mozilla documentation on form|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/checkValidity>, L<Mozilla doc on input|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/checkValidity>

=head2 reportValidity

In perl, this always returns true, or whatever value you would have set.

In JavaScript environment, this returns true if the element's child controls satisfy their validation constraints. When false is returned, cancelable invalid events are fired for each invalid child and validation problems are reported to the user.

Example:

    $doc->forms->myform->addEventListener( submit => sub
    {
        $doc->forms->myform->reportValidity();
    }, { capture => 0 });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/reportValidity>, L<Mozilla doc on input|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/reportValidity>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::DOM::Element>, L<HTML::Object::DOM::Element::Anchor> L<HTML::Object::DOM::Element::Area> L<HTML::Object::DOM::Element::Audio> L<HTML::Object::DOM::Element::Base> L<HTML::Object::DOM::Element::Body> L<HTML::Object::DOM::Element::BR> L<HTML::Object::DOM::Element::Button> L<HTML::Object::DOM::Element::Canvas> L<HTML::Object::DOM::Element::DataList> L<HTML::Object::DOM::Element::Data> L<HTML::Object::DOM::Element::Details> L<HTML::Object::DOM::Element::Dialog> L<HTML::Object::DOM::Element::Directory> L<HTML::Object::DOM::Element::Div> L<HTML::Object::DOM::Element::DList> L<HTML::Object::DOM::Element::Embed> L<HTML::Object::DOM::Element::FieldSet> L<HTML::Object::DOM::Element::Form> L<HTML::Object::DOM::Element::Heading> L<HTML::Object::DOM::Element::Head> L<HTML::Object::DOM::Element::HR> L<HTML::Object::DOM::Element::HTML> L<HTML::Object::DOM::Element::IFrame> L<HTML::Object::DOM::Element::Image> L<HTML::Object::DOM::Element::Input> L<HTML::Object::DOM::Element::Label> L<HTML::Object::DOM::Element::Legend> L<HTML::Object::DOM::Element::Link> L<HTML::Object::DOM::Element::LI> L<HTML::Object::DOM::Element::Map> L<HTML::Object::DOM::Element::Marquee> L<HTML::Object::DOM::Element::Media> L<HTML::Object::DOM::Element::Menu> L<HTML::Object::DOM::Element::Meta> L<HTML::Object::DOM::Element::Meter> L<HTML::Object::DOM::Element::Mod> L<HTML::Object::DOM::Element::Object> L<HTML::Object::DOM::Element::OList> L<HTML::Object::DOM::Element::OptGroup> L<HTML::Object::DOM::Element::Option> L<HTML::Object::DOM::Element::Output> L<HTML::Object::DOM::Element::Paragraph> L<HTML::Object::DOM::Element::Param> L<HTML::Object::DOM::Element::Picture> L<HTML::Object::DOM::Element::Pre> L<HTML::Object::DOM::Element::Progress> L<HTML::Object::DOM::Element::Quote> L<HTML::Object::DOM::Element::Script> L<HTML::Object::DOM::Element::Select> L<HTML::Object::DOM::Element::Slot> L<HTML::Object::DOM::Element::Source> L<HTML::Object::DOM::Element::Span> L<HTML::Object::DOM::Element::Style> L<HTML::Object::DOM::Element::TableCaption> L<HTML::Object::DOM::Element::TableCell> L<HTML::Object::DOM::Element::TableCol> L<HTML::Object::DOM::Element::Table> L<HTML::Object::DOM::Element::TableRow> L<HTML::Object::DOM::Element::TableSection> L<HTML::Object::DOM::Element::Template> L<HTML::Object::DOM::Element::TextArea> L<HTML::Object::DOM::Element::Time> L<HTML::Object::DOM::Element::Title> L<HTML::Object::DOM::Element::Track> L<HTML::Object::DOM::Element::UList> L<HTML::Object::DOM::Element::Unknown> L<HTML::Object::DOM::Element::Video>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
