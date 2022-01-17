##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/IFrame.pm
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
package HTML::Object::DOM::Element::IFrame;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :iframe );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{allowfullscreen} = 0;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'iframe' if( !CORE::length( "$self->{tag}" ) );
    $self->_set_get_internal_attribute_callback( sandbox => sub
    {
        my( $this, $val ) = @_;
        my $list;
        return if( !( $list = $this->{_sanbox_list} ) );
        # $list->debug( $self->debug );
        $list->update( $val );
    });
    return( $self );
}

# Note: property attribute align inherited

# Note: property attribute
sub allow : lvalue { return( shift->_set_get_property( 'allow', @_ ) ); }

# Note: property
sub allowfullscreen : lvalue { return( shift->_set_get_boolean( 'allowfullscreen', @_ ) ); }

# TODO: property; fetch remote content and return a HTML::Object::DOM::Document object
sub contentDocument { return; }

# Note: property does nothing
sub contentWindow : lvalue { return( shift->_set_get_object_lvalue( 'contentwindow', 'HTML::Object::DOM::WindowProxy', @_ ) ); }

# Note: property
sub csp : lvalue { return( shift->_set_get_property( 'csp', @_ ) ); }

# Note: property
sub featurePolicy { return; }

# Note: property
sub frameBorder : lvalue { return( shift->_set_get_property( 'frameborder', @_ ) ); }

# Note: property height inherited

# Note: property
sub longDesc : lvalue { return( shift->_set_get_property( 'longdesc', @_ ) ); }

# Note: property
sub marginHeight : lvalue { return( shift->_set_get_property( 'marginheight', @_ ) ); }

# Note: property
sub marginWidth : lvalue { return( shift->_set_get_property( 'marginwidth', @_ ) ); }

# Note: property name inherited

# Note: property referrerPolicy inherited

# Note: property read-only
sub sandbox
{
    my $self = shift( @_ );
    unless( $self->{_sanbox_list} )
    {
        my $sandbox  = $self->attr( 'sandbox' );
        require HTML::Object::TokenList;
        $self->{_sanbox_list} = HTML::Object::TokenList->new( $sandbox, element => $self, attribute => 'sandbox', debug => $self->debug ) ||
            return( $self->pass_error( HTML::Object::TokenList->error ) );
    }
    return( $self->{_sanbox_list} );
}

# Note: property
sub scrolling : lvalue { return( shift->_set_get_property( 'scrolling', @_ ) ); }

# Note: property src inherited

# Note: property
sub srcdoc : lvalue { return( shift->_set_get_property( 'srcdoc', @_ ) ); }

# Note: property width inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::IFrame - HTML Object DOM iFrame Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::IFrame;
    my $iframe = HTML::Object::DOM::Element::IFrame->new || 
        die( HTML::Object::DOM::Element::IFrame->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The L<HTML::Object::DOM::Element::IFrame> interface provides special properties and methods (beyond those of the L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating the layout and presentation of inline frame elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::IFrame |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 align

Provided with a string and this set or get the attribute that specifies the alignment of the frame with respect to the surrounding context.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/align>

=head2 allow

A list of origins the frame is allowed to display content from. This attribute also accepts the values self and src which represent the origin in the iframe's src attribute. The default value is src.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/allow>

=head2 allowfullscreen

A boolean value indicating whether the inline frame is willing to be placed into full screen mode. See Using full-screen mode for details. This defaults to false.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/allowfullscreen>

=head2 contentDocument

This does nothing and returns C<undef> under perl environment.

In JavaScript environment, this returns a C<Document>, the active document in the inline frame's nested browsing context.

Maybe, in the future, this could fetch the remote page at the specified url, parse the html and return its L<HTML::Object::DOM> object?

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/contentDocument>

=head2 contentWindow

Normally this returns C<undef> under perl, but you can set a L<HTML::Object::DOM::WindowProxy> object.

In JavaScript environment, this returns a C<WindowProxy>, the window proxy for the nested browsing context.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/contentWindow>

=head2 csp

Provided with a value and this sets or gets the attribute that specifies the Content Security Policy that an embedded document must agree to enforce upon itself.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/csp>

=head2 featurePolicy

Read-only.

This does nothing and returns C<undef> under perl environment.

In JavaScript environment, this returns the C<FeaturePolicy> interface which provides a simple API for introspecting the feature policies applied to a specific document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/featurePolicy>

=head2 frameBorder

Provided with a string (C<yes> or C<no>) or a integer (1 or 0) and this will set or get the HTML attribute to indicate whether to create borders between frames.

Example:

    $iframe->frameBorder = 1;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/frameBorder>

=head2 height

A string that reflects the height HTML attribute, indicating the height of the frame.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/height>

=head2 longDesc

A string that contains the URI of a long description of the frame.

Example:

    <img src="some_pic.png" id="myPicture" height="1024" width="512" longdesc="/some/where/longdescription.html" />

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/longDesc>

=head2 marginHeight

A string being the height of the frame margin.

Example:

    <iframe src="/some/where" frameborder="0"  name="resource" title="Resource" marginheight="10">

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/marginHeight>

=head2 marginWidth

A string being the width of the frame margin.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/marginWidth>

=head2 name

A string that reflects the name HTML attribute, containing a name by which to refer to the frame.

Example:

    <iframe src="/some/where" frameborder="0"  name="resource" title="Resource" marginheight="10">

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/name>

=head2 referrerPolicy

A string that reflects the C<referrerpolicy> HTML attribute indicating which referrer to use when fetching the linked resource.

You can use whatever value you want, but the values supported by web browser are:

=over 4

=item C<no-referrer>

This means that the C<Referer> HTTP header will not be sent.

=item C<origin>

This means that the referrer will be the origin of the page, that is roughly the scheme, the host and the port.

=item C<unsafe-url>

This means that the referrer will include the origin and the path (but not the fragment, password, or username). This case is unsafe as it can leak path information that has been concealed to third-party by using TLS.

=back

Example:

    my $iframe = $doc->createElement("iframe");
    $iframe->src = '/';
    $iframe->referrerPolicy = "unsafe-url";
    my $body = $doc->getElementsByTagName('body')[0];
    $body->appendChild($iframe); # Fetch the image using the complete URL as the referrer

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/referrerPolicy>

=head2 sandbox

Read-only.

A L<TokenList|HTML::Object::DOM::TokenList> object that reflects the sandbox HTML attribute, indicating extra restrictions on the behavior of the nested content.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/sandbox>

=head2 scrolling

Provided with a string (C<true> or C<false>) and this set or gets a string that indicates whether the browser should provide scrollbars for the frame.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/scrolling>

=head2 src

A string that reflects the src HTML attribute, containing the address of the content to be embedded. Note that programmatically removing an <iframe>'s src attribute (e.g. via L<HTML::Object::DOM::Element/emoveAttribute>) causes about:blank to be loaded in the frame in Firefox (from version 65), Chromium-based browsers, and Safari/iOS.

Example:

    my $iframe = $doc->createElement( 'iframe' );
    $iframe->src = '/';
    my $body = $doc->getElementsByTagName( 'body' )->[0];
    $body->appendChild( $iframe ); # Fetch the image using the complete URL as the referrer

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/src>

=head2 srcdoc

This does nothing and returns C<undef> under perl environment.

In JavaScript environment, this sets a string that represents the content to display in the frame.

Example:

    var iframe = document.createElement("iframe");
    iframe.srcdoc = `<!DOCTYPE html><p>Hello World!</p>`;
    document.body.appendChild(iframe);

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/srcdoc>

=head2 width

A string that reflects the width HTML attribute, indicating the width of the frame.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLiFrameElement/width>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement>, L<Mozilla documentation on iframe element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
