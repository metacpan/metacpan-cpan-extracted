##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Image.pm
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
package HTML::Object::DOM::Element::Image;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :img );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{complete} = 1;
    $self->{decoding} = 'auto';
    $self->{naturalheight} = 0;
    $self->{naturalwidth}  = 0;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'image' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property alt inherited

# Note: property read-only
sub complete : lvalue { return( shift->_set_get_boolean( 'complete', @_ ) ); }

# Note: property crossOrigin inherited

# Note: property read-only currentSrc inherited

sub decode { return; }

# Note: property
sub decoding : lvalue { return( shift->_set_get_scalar_as_object( 'decoding', @_ ) ); }

# Note: property height inherited

# Note: property
sub isMap : lvalue { return( shift->_set_get_property( { attribute => 'ismap', is_boolean => 1 }, @_ ) ); }

# Note: property
sub loading : lvalue { return( shift->_set_get_property( 'loading', @_ ) ); }

# Note: property read-only
sub naturalHeight : lvalue { return( shift->_set_get_number( 'naturalheight', @_ ) ); }

# Note: property read-only
sub naturalWidth : lvalue { return( shift->_set_get_number( 'naturalwidth', @_ ) ); }

# Note: property referrerPolicy inherited

# Note: property
sub sizes : lvalue { return( shift->_set_get_property( 'sizes', @_ ) ); }

# Note: property src inherited

# Note: property
sub srcset : lvalue { return( shift->_set_get_property( 'srcset', @_ ) ); }

# Note: property useMap inherited

# Note: property width inherited

# Note: property read-only
sub x : lvalue { return( shift->_set_get_number( 'x', @_ ) ); }

# Note: property read-only
sub y : lvalue { return( shift->_set_get_number( 'y', @_ ) ); } # ::

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Image - HTML Object DOM Image Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Image;
    my $img = HTML::Object::DOM::Element::Image->new || 
        die( HTML::Object::DOM::Element::Image->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface represents an HTML C<<img>> element, providing the properties and methods used to manipulate image elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Image |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 alt

A string that reflects the alt HTML attribute, thus indicating the alternate fallback content to be displayed if the image has not been loaded.

Example:

    <img src="/some/file/image.png" alt="Great Picture" />

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/alt>

=head2 complete

This does nothing and always returns true under perl environment.

Under JavaScript environment, this returns a boolean value that is true if the browser has finished fetching the image, whether successful or not. That means this value is also true if the image has no src value indicating an image to load.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/complete>

=head2 crossOrigin

A string specifying the CORS setting for this image element. See CORS settings attributes for further details. This may be C<undef> if CORS is not used.

Example:

    my $image = $doc->createElement( 'img' );
    $image->crossOrigin = "anonymous";

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/crossOrigin>

=head2 currentSrc

Under perl environment, this returns the same value as L</src>, but under JavaScript environment, this returns a string representing the URL from which the currently displayed image was loaded. This may change as the image is adjusted due to changing conditions, as directed by any media queries which are in place.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/currentSrc>

=head2 decoding

An optional string representing a hint given to the browser on how it should decode the image. If this value is provided, it must be one of the possible permitted values: C<sync> to decode the image synchronously, C<async> to decode it asynchronously, or C<auto> to indicate no preference (which is the default). Read the decoding page for details on the implications of this property's values.

Example:

    my $img = $doc->createElement( 'img' );
    $img->decoding = 'sync';
    $img->src = '/some/where/logo.png';

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/decoding>

=head2 height

An integer value that reflects the height HTML attribute, indicating the rendered height of the image in CSS pixels.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/height>

=head2 isMap

Provided with a boolean value and this sets or gets the HTML attribute C<ismap> that indicates that the image is part of a server-side image map. This is different from a client-side image map, specified using an C<<img>> element and a corresponding C<<map>> which contains C<<area>> elements indicating the clickable areas in the image. The image must be contained within an C<<a>> element; see the ismap page for details.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/isMap>

=head2 loading

Provided with a string (C<eager> or C<lazy>) and this sets or gets the C<loading> HTML attribute that provides a hint to the browser to optimize loading the document by determining whether to load the image immediately (C<eager>) or on an as-needed basis (C<lazy>).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/loading>

=head2 naturalHeight

Under perl environment, this always return 0, but you can change this value.

Under JavaScript environment, this returns an integer value representing the intrinsic height of the image in CSS pixels, if it is available; else, it shows 0. This is the height the image would be if it were rendered at its natural full size.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/naturalHeight>

=head2 naturalWidth

Under perl environment, this always return 0, but you can change this value.

Under JavaScript environment, this returns an integer value representing the intrinsic width of the image in CSS pixels, if it is available; otherwise, it will show 0. This is the width the image would be if it were rendered at its natural full size.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/naturalWidth>

=head2 referrerPolicy

A string that reflects the referrerpolicy HTML attribute, which tells the user agent how to decide which referrer to use in order to fetch the image.

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

    my $img = $doc->createElement( 'img' );
    $img->src = '/some/where/logo.png';
    $img->referrerPolicy = 'origin';

    my $div = $doc->getElementById('divAround');
    $div->appendChild( $img ); # Fetch the image using the origin as the referrer

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/referrerPolicy>

=head2 sizes

A string reflecting the C<sizes> HTML attribute. This string specifies a list of comma-separated conditional sizes for the image; that is, for a given viewport size, a particular image size is to be used. Read the documentation on the C<sizes> page for details on the format of this string.

Example:

    <img src="/files/16870/new-york-skyline-wide->jpg"
         srcset="/files/16870/new-york-skyline-wide->jpg 3724w,
                         /files/16869/new-york-skyline-4by3->jpg 1961w,
                         /files/16871/new-york-skyline-tall->jpg 1060w"
         sizes="((min-width: 50em) and (max-width: 60em)) 50em,
                        ((min-width: 30em) and (max-width: 50em)) 30em,
                        (max-width: 30em) 20em">

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/sizes>

=head2 src

A string that reflects the src HTML attribute, which contains the full URL of the image including base URI.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/src>

=head2 srcset

A string reflecting the srcset HTML attribute. This specifies a list of candidate images, separated by commas (',', U+002C COMMA). Each candidate image is a URL followed by a space, followed by a specially-formatted string indicating the size of the image. The size may be specified either the width or a size multiple. Read the Mozilla srcset documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/srcset> for specifics on the format of the size substring.

Example:

    "images/team-photo.jpg 1x, images/team-photo-retina.jpg 2x, images/team-photo-full 2048w"

Another example:

    "header640.png 640w, header960.png 960w, header1024.png 1024w, header.png"

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/srcset>

=head2 useMap

A string reflecting the usemap HTML attribute, containing the page-local URL of the C<<map>> element describing the image map to use. The page-local URL is a pound (hash) symbol (#) followed by the ID of the C<<map>> element, such as #my-map-element. The C<<map>> in turn contains C<<area>> elements indicating the clickable areas in the image.

Example:

    <map name="mainmenu-map">
        <area shape="circle" coords="25, 25, 75" href="/index.html" alt="Return to home page">
        <area shape="rect" coords="25, 25, 100, 150" href="/index.html" alt="Shop">
    </map>

    <img src="menubox->png" usemap="#mainmenu-map" />

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/useMap>

=head2 width

An integer value that reflects the width HTML attribute, indicating the rendered width of the image in CSS pixels.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/width>

=head2 x

Provided with an integer, and this sets or gets the horizontal offset of the left border edge of the image's CSS layout box relative to the origin of the C<<html>> element's containing block.

Since this is a perl environment, this has no effect, but you can still set whatever value you want.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/x>

=head2 y

Provided with an integer, and this sets or gets the vertical offset of the top border edge of the image's CSS layout box relative to the origin of the C<<html>> element's containing block.

Since this is a perl environment, this has no effect, but you can still set whatever value you want.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/y>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 decode

Since this is a perl environment, there is no decoding of the image, and this always returns C<undef>.

Under a JavaScript environment, this returns a Promise that resolves when the image is decoded and it's safe to append the image to the DOM. This prevents rendering of the next frame from having to pause to decode the image, as would happen if an undecoded image were added to the DOM.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/decode>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement>, L<Mozilla documentation on image element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
