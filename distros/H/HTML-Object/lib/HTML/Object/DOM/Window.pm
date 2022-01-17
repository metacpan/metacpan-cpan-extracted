##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Window.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/31
## Modified 2021/12/31
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Window;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::EventTarget );
    # perl -nE 'print if( s,^sub (\w+) : lvalue.*?$,$1, )' ./lib/HTML/Object/DOM/Window.pm | tr "\n" " "
    our @LVALUE_METHODS = qw( closed document event frames fullScreen innerHeight innerWidth isSecureContext location name onappinstalled onbeforeinstallprompt ondevicemotion ondeviceorientation ondeviceorientationabsolute ondeviceproximity onerror ongamepadconnected ongamepaddisconnected onlanguagechange onorientationchange onrejectionhandled onresize onstorage onuserproximity onvrdisplayactivate onvrdisplayblur onvrdisplayconnect onvrdisplaydeactivate onvrdisplaydisconnect onvrdisplayfocus onvrdisplaypresentchange outerHeight outerWidth parent screen scrollX scrollY self status top visualViewport );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{captureEvents} = 0;
    $self->{fullscreen} = 0;
    $self->{issecurecontext} = 1;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub alert { shift; return( warn( @_ ) ); }

sub blur { return; }

sub cancelAnimationFrame { return; }

sub cancelIdleCallback { return; }

sub captureEvents
{
    my $self = shift( @_ );
    my $bit = shift( @_ );
    return( $self->{captured_events} |= $bit );
}

sub clearImmediate { return; }

# Note: property clientInformation read-only
sub clientInformation { return; }

sub close { return( shift->closed(1) ); }

# Note: property closed read-only
sub closed : lvalue { return( shift->_set_get_boolean( 'closed', @_ ) ); }

sub confirm { return; }

# Note: property console read-only
sub console { return; }

# Note: property crypto read-only
sub crypto { return; }

# Note: property customElements read-only
sub customElements { return; }

# Note: property devicePixelRatio read-only
sub devicePixelRatio { return; }

# Note: property document read-only
sub document : lvalue { return( shift->_set_get_object_lvalue( 'document', 'HTML::Object::DOM::Document', @_ ) ); }

# Note: property DOMMatrix read-only
sub DOMMatrix { return; }

# Note: property DOMMatrixReadOnly read-only
sub DOMMatrixReadOnly { return; }

# Note: property DOMPoint read-only
sub DOMPoint { return; }

# Note: property DOMPointReadOnly read-only
sub DOMPointReadOnly { return; }

# Note: property DOMQuad read-only
sub DOMQuad { return; }

# Note: property DOMRect read-only
sub DOMRect { return; }

# Note: property DOMRectReadOnly read-only
sub DOMRectReadOnly { return; }

sub dump
{
    my $self = shift( @_ );
    $self->_load_class( 'Data::Dump' ) || return( $self->pass_error );
    return( print( STDERR Data::Dump::dump( @_ ), "\n" ) );
}

# Note: property event read-only
sub event : lvalue { return( shift->_set_get_object_lvalue( 'event', 'HTML::Object::Event', @_ ) ); }

sub find { return; }

sub focus { return; }

# Note: property frameElement read-only
sub frameElement { return; }

# Note: property frames read-only
sub frames : lvalue
{
    my $self = shift( @_ );
    my $results = $self->new_array;
    my $doc = $self->document || return( $results );
    $results = $doc->look_down( _tag => 'iframes' );
    return( $results );
}

# Note: property fullScreen
sub fullScreen : lvalue { return( shift->_set_get_boolean( 'fullscreen', @_ ) ); }

sub getComputedStyle { return; }

sub getDefaultComputedStyle { return; }

sub getSelection { return; }

# Note: property history read-only
sub history { return; }

# Note: property innerHeight read-only
sub innerHeight : lvalue { return( shift->_set_get_number( 'innerheight', @_ ) ); }

# Note: property innerWidth read-only
sub innerWidth : lvalue { return( shift->_set_get_number( 'innerwidth', @_ ) ); }

# Note: property isSecureContext read-only
sub isSecureContext : lvalue { return( shift->_set_get_boolean( 'issecurecontext', @_ ) ); }

# Note: property length read-only
sub length { return( shift->frames->length ); }

# Note: property localStorage read-only
sub localStorage { return; }

# Note: property location
sub location : lvalue { return( shift->_set_get_uri( 'location', @_ ) ); }

# Note: property locationbar read-only
sub locationbar { return; }

sub matchMedia { return; }

# Note: property menubar read-only
sub menubar { return; }

# Note: property messageManager
sub messageManager { return; }

sub moveBy { return; }

sub moveTo { return; }

# Note: property mozInnerScreenX read-only
sub mozInnerScreenX { return; }

# Note: property mozInnerScreenY read-only
sub mozInnerScreenY { return; }

# Note: property name
sub name : lvalue { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

# Note: property navigator read-only
sub navigator { return; }

sub onappinstalled : lvalue { return( shift->on( 'appinstalled', @_ ) ); }

sub onbeforeinstallprompt : lvalue { return( shift->on( 'beforeinstallprompt', @_ ) ); }

sub ondevicemotion : lvalue { return( shift->on( 'devicemotion', @_ ) ); }

sub ondeviceorientation : lvalue { return( shift->on( 'deviceorientation', @_ ) ); }

sub ondeviceorientationabsolute : lvalue { return( shift->on( 'deviceorientationabsolute', @_ ) ); }

sub ondeviceproximity : lvalue { return( shift->on( 'deviceproximity', @_ ) ); }

sub onerror : lvalue { return( shift->on( 'error', @_ ) ); }

sub ongamepadconnected : lvalue { return( shift->on( 'gamepadconnected', @_ ) ); }

sub ongamepaddisconnected : lvalue { return( shift->on( 'gamepaddisconnected', @_ ) ); }

sub onlanguagechange : lvalue { return( shift->on( 'languagechange', @_ ) ); }

sub onorientationchange : lvalue { return( shift->on( 'orientationchange', @_ ) ); }

sub onrejectionhandled : lvalue { return( shift->on( 'rejectionhandled', @_ ) ); }

sub onresize : lvalue { return( shift->on( 'resize', @_ ) ); }

sub onstorage : lvalue { return( shift->on( 'storage', @_ ) ); }

sub onuserproximity : lvalue { return( shift->on( 'userproximity', @_ ) ); }

sub onvrdisplayactivate : lvalue { return( shift->on( 'vrdisplayactivate', @_ ) ); }

sub onvrdisplayblur : lvalue { return( shift->on( 'vrdisplayblur', @_ ) ); }

sub onvrdisplayconnect : lvalue { return( shift->on( 'vrdisplayconnect', @_ ) ); }

sub onvrdisplaydeactivate : lvalue { return( shift->on( 'vrdisplaydeactivate', @_ ) ); }

sub onvrdisplaydisconnect : lvalue { return( shift->on( 'vrdisplaydisconnect', @_ ) ); }

sub onvrdisplayfocus : lvalue { return( shift->on( 'vrdisplayfocus', @_ ) ); }

sub onvrdisplaypresentchange : lvalue { return( shift->on( 'vrdisplaypresentchange', @_ ) ); }

sub open { return( shift->new( @_ ) ); }

# Note: property opener
sub opener { return; }

# Note: property outerHeight read-only
sub outerHeight : lvalue { return( shift->_set_get_number( 'outerheight', @_ ) ); }

# Note: property outerWidth read-only
sub outerWidth : lvalue { return( shift->_set_get_number( 'outerwidth', @_ ) ); }

# Note: property pageXOffset read-only
sub pageXOffset { return; }

# Note: property pageYOffset read-only
sub pageYOffset { return; }

# Note: property parent read-only
sub parent : lvalue { return( shift->_set_get_object_lvalue( 'parent', 'HTML::Object::DOM::Window', @_ ) ); }

# Note: property performance read-only
sub performance { return; }

# Note: property personalbar read-only
sub personalbar { return; }

sub postMessage { return; }

sub print { return; }

sub prompt { return; }

sub releaseEvents
{
    my $self = shift( @_ );
    my $bit = shift( @_ );
    $self->{captured_events} = ( $self->{captured_events} ^ $bit );
    return( $self->{captured_events} );
}

sub requestAnimationFrame { return; }

sub requestIdleCallback { return; }

sub resizeBy { return; }

sub resizeTo { return; }

# Note: property screen read-only
sub screen : lvalue { return( shift->_set_get_object_lvalue( 'screen', 'HTML::Object::DOM::Screen', @_ ) ); }

# Note: property screenX read-only
sub screenX { return; }

# Note: property screenY read-only
sub screenY { return; }

sub scroll { return; }

sub scrollBy { return; }

sub scrollByLines { return; }

sub scrollByPages { return; }

# Note: property scrollMaxX read-only
sub scrollMaxX { return; }

# Note: property scrollMaxY read-only
sub scrollMaxY { return; }

sub scrollTo { return; }

# Note: property scrollX read-only
sub scrollX : lvalue { return( shift->_set_get_number( 'scrollx', @_ ) ); }

# Note: property scrollY read-only
sub scrollY : lvalue { return( shift->_set_get_number( 'scrolly', @_ ) ); }

# Note: property scrollbars read-only
sub scrollbars { return; }

# Note: property self read-only
sub self : lvalue { return( shift( @_ ) ); }

# Note: property sessionStorage
sub sessionStorage { return; }

sub setImmediate { return; }

sub setResizable { return; }

sub showDirectoryPicker { return; }

sub showOpenFilePicker { return; }

sub showSaveFilePicker { return; }

# Note: property sidebar read-only
sub sidebar { return; }

sub sizeToContent { return; }

# Note: property speechSynthesis read-only
sub speechSynthesis { return; }

# Note: property status
sub status : lvalue { return( shift->_set_get_scalar_as_object( 'status', @_ ) ); }

# Note: property statusbar read-only
sub statusbar { return; }

sub stop { return; }

# Note: property toolbar read-only
sub toolbar { return; }

# Note: property top read-only
sub top : lvalue { return( shift->_set_get_object_lvalue( 'top', 'HTML::Object::DOM::Window', @_ ) ); }

sub updateCommands { return; }

# Note: property visualViewport read-only
sub visualViewport : lvalue { return( shift->_set_get_number( 'visualviewport', @_ ) ); }

# Note: property window read-only
sub window { return( shift( @_ ) ); }

sub is_property { return( scalar( grep( /^$_[1]$/i, @LVALUE_METHODS ) ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Window - HTML Object DOM Window Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Window;
    my $window = HTML::Object::DOM::Window->new || 
        die( HTML::Object::DOM::Window->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The Window interface represents a window containing a L<DOM document|HTML::Object::DOM::Document>; the L<document property|/document> points to the L<DOM document|HTML::Object::DOM::Document> loaded in that window.

A window for a given document can be obtained using the L<document->defaultView property|HTML::Object::DOM/defaultView.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +---------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Window |
    +-----------------------+     +---------------------------+     +---------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::EventTarget>

=head2 DOMMatrix

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to a C<DOMMatrix> object, which represents 4x4 matrices, suitable for 2D and 3D operations.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/DOMMatrix>

=head2 DOMMatrixReadOnly

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to a C<DOMMatrixReadOnly> object, which represents 4x4 matrices, suitable for 2D and 3D operations.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/DOMMatrixReadOnly>

=head2 DOMPoint

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to a C<DOMPoint> object, which represents a 2D or 3D point in a coordinate system.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/DOMPoint>

=head2 DOMPointReadOnly

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to a C<DOMPointReadOnly> object, which represents a 2D or 3D point in a coordinate system.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/DOMPointReadOnly>

=head2 DOMQuad

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to a C<DOMQuad> object, which provides represents a quadrilaterial object, that is one having four corners and four sides.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/DOMQuad>

=head2 DOMRect

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to a C<DOMRect> object, which represents a rectangle.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/DOMRect>

=head2 DOMRectReadOnly

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to a C<DOMRectReadOnly> object, which represents a rectangle.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/DOMRectReadOnly>

=head2 clientInformation

This always returns C<undef> under perl.

Normally, under JavaScript, this is an alias for Window.navigator.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/navigator>

=head2 closed

This always returns C<undef> under perl.

Normally, under JavaScript, this property indicates whether the current window is closed or not.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/closed>

=head2 console

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to the console object which provides access to the browser's debugging console.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/console>

=head2 crypto

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the browser crypto object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/crypto_property>

=head2 customElements

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to the C<CustomElementRegistry> object, which can be used to register new custom elements and get information about previously registered custom elements.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/customElements>

=head2 devicePixelRatio

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the ratio between physical pixels and device independent pixels in the current display.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/devicePixelRatio>

=head2 document

Read-only.

Returns a reference to the L<document|HTML::Object::DOM::Document> that the window contains.

Example:

    my $parser = HTML::Object::DOM->new;
    $parser->parse_data( $html );
    say( $parser->window->document->title );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/document>

=head2 event

Read-only.

Returns the current event, which is the event currently being handled by the C<JavaScript> code's context, or undefined if no event is currently being handled. The Event object passed directly to event handlers should be used instead whenever possible.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/event>

=head2 frameElement

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the element in which the window is embedded, or C<undef> if the window is not embedded.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/frameElement>

=head2 frames

Read-only.

Returns an array of the subframes in the current window.

Example:

    my $frameList = $parser->window->frames;

    my $frames = $parser->window->frames; # or my $frames = $parser->window->parent->frames;
    for( my $i = 0; $i < $frames->length; $i++ )
    {
        # do something with each subframe as $frames->[$i]
        $frames->[$i]->document->body->style->background = "red";
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/frames>

=head2 fullScreen

This boolean value is set to false under perl, but you can change it.

Normally, under JavaScript, this property indicates whether the window is displayed in full screen or not.

Example:

    if( $parser->window->fullScreen ) {
        # it's fullscreen!
    }
    else {
        # not fullscreen!
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/fullScreen>

=head2 history

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to the history object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/history>

=head2 innerHeight

Normally this is read-only, but under perl you can set whatever number value you want.

Under JavaScript, this gets the height of the content area of the browser window including, if rendered, the horizontal scrollbar.

Example:

    my $intViewportHeight = $parser->window->innerHeight;

    my $intFrameHeight = $parser->window->innerHeight; # or

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/innerHeight>

=head2 innerWidth

Normally this is read-only, but under perl you can set whatever number value you want.

Under JavaScript, this gets the width of the content area of the browser window including, if rendered, the vertical scrollbar.

Example:

    my $intViewportWidth = $parser->window->innerWidth;

    # This will return the width of the viewport
    my $intFrameWidth = $parser->window->innerWidth;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/innerWidth>

=head2 is_property

Provided with a property name and this will return true if it is indeed a window property or false otherwise.

=head2 isSecureContext

This is not used under perl, but you can set whatever boolean value you want. By default this returns true.

Normally, under JavaScript, this indicates whether a context is capable of using features that require secure contexts.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/isSecureContext>

=head2 length

Read-only.

Returns the number of frames in the window. See also L</frames>.

Example:

    if( $parser->window->length ) {
        # this is a document with subframes
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/length>

=head2 localStorage

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to the local storage object used to store data that may only be accessed by the origin that created it.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage>

=head2 location

By default, this returns C<undef>, but you can set it to whatever URI you want. If set, it will return a L<URI> object.

Gets/sets the location, or current URL, of the window object.

Example:

    say( $parser->window->location ); # alerts "https://example.org/some/where"

    $parser->window->location->assign( "https://example.org" ); # or
    $parser->window->location = "https://example.org";

Another example:

    $parser->window->location->reload();

Another example:

    sub reloadPageWithHash() {
        my $initialPage = $parser->window->location->pathname;
        $parser->window->location->replace('http://example.org/#' + $initialPage);
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/location>

=head2 locationbar

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the locationbar object, whose visibility can be toggled in the window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/locationbar>

=head2 menubar

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the menubar object, whose visibility can be toggled in the window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/menubar>

=head2 messageManager

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the message manager object for this window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/messageManager>

=head2 mozInnerScreenX

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the horizontal (X) coordinate of the top-left corner of the window's viewport, in screen coordinates. This value is reported in CSS pixels. See mozScreenPixelsPerCSSPixel in nsIDOMWindowUtils for a conversion factor to adapt to screen pixels if needed.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/mozInnerScreenX>

=head2 mozInnerScreenY

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the vertical (Y) coordinate of the top-left corner of the window's viewport, in screen coordinates. This value is reported in CSS pixels. See mozScreenPixelsPerCSSPixel for a conversion factor to adapt to screen pixels if needed.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/mozInnerScreenY>

=head2 name

Gets/sets the name of the window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/name>

=head2 navigator

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to the navigator object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/navigator>

=head2 onerror

Sets the event listener for when error occur on this window interface.

=head2 onlanguagechange

Sets the event listener for when the language is changed. This event does not get fired automatically, but you can trigger it yourself. See L<HTML::Object::DOM::EventTarget>

=head2 onorientationchange

Sets the event listener for when there is a change of orientation. This event does not get fired automatically, but you can trigger it yourself. See L<HTML::Object::DOM::EventTarget>

=head2 onresize

Sets the event listener for when the screen gets resized. This event does not get fired automatically, but you can trigger it yourself. See L<HTML::Object::DOM::EventTarget>

=head2 onstorage

Sets the event listener for when the screen storage facility has been changed. This event does not get fired automatically, but you can trigger it yourself. See L<HTML::Object::DOM::EventTarget>

=head2 opener

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to the window that opened this current window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/opener>

=head2 outerHeight

Normally this is read-only, but under perl you can set whatever number value you want.

Under JavaScript, this gets the height of the outside of the browser window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/outerHeight>

=head2 outerWidth

Normally this is read-only, but under perl you can set whatever number value you want.

Under JavaScript, this gets the width of the outside of the browser window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/outerWidth>

=head2 pageXOffset

This always returns C<undef> under perl.

Normally, under JavaScript, this is an alias for window.scrollX.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollX>

=head2 pageYOffset

This always returns C<undef> under perl.

Normally, under JavaScript, this is an alias for window.scrollY

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollY>

=head2 parent

Read-only.

Returns a reference to the parent of the current window or subframe, if any. By default this returns C<undef>, but you can set it to a L<window object|HTML::Object::DOM::Window>.

Example:

    my $parentWindow = $parser->window->parent;

    if( $parser->window->parent != $parser->window->top) {
        # We're deeper than one down
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/parent>

=head2 performance

Read-only.

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a C<Performance> object, which includes the timing and navigation attributes, each of which is an object providing performance-related data. See also Using Navigation Timing for additional information and examples.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/performance_property>

=head2 personalbar

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the personalbar object, whose visibility can be toggled in the window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/personalbar>

=head2 screen

Read-only.

Returns a reference to the L<screen object|HTML::Object::DOM::Screen> associated with the window.

Example:

    use HTML::Object::DOM qw( window screen );
    if( screen->pixelDepth < 8 ) {
        # use low-color version of page
    } else {
        # use regular, colorful page
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/screen>

=head2 screenX

This always returns C<undef> under perl.

Normally, under JavaScript, both properties return the horizontal distance from the left border of the user's browser viewport to the left side of the screen.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/screenX>

=head2 screenY

This always returns C<undef> under perl.

Normally, under JavaScript, both properties return the vertical distance from the top border of the user's browser viewport to the top side of the screen.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/screenY>

=head2 scrollMaxX

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the maximum offset that the window can be scrolled to horizontally, that is the document width minus the viewport width.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollMaxX>

=head2 scrollMaxY

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the maximum offset that the window can be scrolled to vertically (i.e., the document height minus the viewport height).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollMaxY>

=head2 scrollX

Normally this is read-only, but under perl you can set whatever number value you want. BY default this is C<undef>

Under JavaScript, this returns the number of pixels that the document has already been scrolled horizontally.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollX>

=head2 scrollY

Normally this is read-only, but under perl you can set whatever number value you want. BY default this is C<undef>

Under JavaScript, this returns the number of pixels that the document has already been scrolled vertically.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollY>

=head2 scrollbars

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the scrollbars object, whose visibility can be toggled in the window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollbars>

=head2 self

Read-only.

Returns an object reference to the window object itself.

Example:

    use HTML::Object::DOM qw( window );
    if( window->parent->frames->[0] != window->self )
    {
        # this window is not the first frame in the list
    }

    my $w1 = window;
    my $w2 = self;
    my $w3 = window->window;
    my $w4 = window->self;
    # $w1, $w2, $w3, $w4 all strictly equal, but only $w2 will sub in workers

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/self>

=head2 sessionStorage

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to the session storage object used to store data that may only be accessed by the origin that created it.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/sessionStorage>

=head2 sidebar

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a reference to the window object of the sidebar.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/sidebar>

=head2 speechSynthesis

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a C<SpeechSynthesis> object, which is the entry point into using Web Speech API speech synthesis functionality.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/speechSynthesis>

=head2 status

Normally this is read-only, but under perl you can set whatever text value you want. It returns a L<scalar object|Module::Generic::Scalar>.

Under JavaScript, this gets/sets the text in the statusbar at the bottom of the browser.

Example:

    use HTML::Object::DOM qw( window );
    window->status = $string;
    my $value = window->status;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/status>

=head2 statusbar

This always returns C<undef> under perl.

Normally, under JavaScript, this return the statusbar object, whose visibility can be toggled in the window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/statusbar>

=head2 toolbar

This always returns C<undef> under perl.

Normally, under JavaScript, this return the toolbar object, whose visibility can be toggled in the window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/toolbar>

=head2 top

Normally this is read-only, but under perl you can set whatever L<window object|HTML::Object::DOM::Window> you want.

Under JavaScript, this returns a reference to the topmost window in the window hierarchy. This property is read only.

Example:

    use HTML::Object::DOM qw( window );
    my $topWindow = window->top;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/top>

=head2 visualViewport

Normally this is read-only, but under perl you can set whatever number value you want.

Under JavaScript, this a C<VisualViewport> object which represents the visual viewport for a given window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/visualViewport>

=head2 window

Read-only.

Returns a reference to the current window.

Example:

    use HTML::Object::DOM qw( window );
    window->window
    window->window->window
    window->window->window->window
    # ...

    my $global = {data: 0};
    say( $global == window->global ); # displays "true"

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/window>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::EventTarget>

=head2 alert

Under perl, this calls L<perlfunc/warn> passing it whatever arguments you provide.

Under JavaScript, this displays an alert dialog.

Example:

    use HTML::Object::DOM qw( window );
    my $parser = HTML::Object::DOM->new;
    window->alert( $message );

    window->alert( "Hello world!" );
    $parser->window->alert( "Hello world!" );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/alert>

=head2 blur

This always returns C<undef> under perl.

Normally, under JavaScript, this sets focus away from the window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/blur>

=head2 cancelAnimationFrame

This always returns C<undef> under perl.

Normally, under JavaScript, this enables you to cancel a callback previously scheduled with Window.requestAnimationFrame.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/cancelAnimationFrame>

=head2 cancelIdleCallback

This always returns C<undef> under perl.

Normally, under JavaScript, this enables you to cancel a callback previously scheduled with Window.requestIdleCallback.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/cancelIdleCallback>

=head2 captureEvents

Registers the window to capture all events of the specified type.

Example:

    use HTML::Object::DOM qw( window );
    use HTML::Object::Event qw( events );
    window->captureEvents( CLICK );
    window->onclick = \&page_click;

Note that you can pass a list of events to this method using the following syntax:

    window.captureEvents( KEYPRESS | KEYDOWN | KEYUP ).

Although you can still use it, this method is deprecated in favour of L<EventTarget/addEventListener>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/captureEvents>

=head2 clearImmediate

This always returns C<undef> under perl.

Normally, under JavaScript, this cancels the repeated execution set using setImmediate.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/clearImmediate>

=head2 close

Under perl, this does nothing in particular, but under JavaScript, this closes the current window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/close>

=head2 confirm

This always returns C<undef> under perl.

Normally, under JavaScript, this displays a dialog with a message that the user needs to respond to.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/confirm>

=head2 dump

Under perl, this use L<Data::Dump/dump> to print out data provided to the C<STDERR>.

Under JavaScript, this writes a message to the console.

Example:

    use HTML::Object::DOM qw( window );
    window->dump( $message );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/dump>

=head2 find

This always returns C<undef> under perl.

Normally, under JavaScript, this searches for a given string in a window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/find>

=head2 focus

This always returns C<undef> under perl.

Normally, under JavaScript, this sets focus on the current window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/focus>

=head2 getComputedStyle

This always returns C<undef> under perl.

Normally, under JavaScript, this gets computed style for the specified element. Computed style indicates the computed values of all CSS properties of the element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/getComputedStyle>

=head2 getDefaultComputedStyle

This always returns C<undef> under perl.

Normally, under JavaScript, this gets default computed style for the specified element, ignoring author stylesheets.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/window/getDefaultComputedStyle>

=head2 getSelection

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the selection object representing the selected item(s).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/getSelection>

=head2 matchMedia

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a C<MediaQueryList> object representing the specified media query string.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/matchMedia>

=head2 moveBy

This always returns C<undef> under perl.

Normally, under JavaScript, this moves the current window by a specified amount.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/moveBy>

=head2 moveTo

This always returns C<undef> under perl.

Normally, under JavaScript, this moves the window to the specified coordinates.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/moveTo>

=head2 open

Under perl, this merely returns a new L<window object>.

Under JavaScript, this opens a new window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/open>

=head2 postMessage

This always returns C<undef> under perl.

Normally, under JavaScript, this provides a secure means for one window to send a string of data to another window, which need not be within the same domain as the first.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage>

=head2 print

This always returns C<undef> under perl.

Normally, under JavaScript, this opens the Print Dialog to print the current document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/print>

=head2 prompt

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the text entered by the user in a prompt dialog.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/prompt>

=head2 releaseEvents

Releases the window from trapping events of a specific type.

Example:

    use HTML::Object::DOM qw( window );
    window->releaseEvents( KEYPRESS );

Note that you can pass a list of events to this method using the following syntax:

    window->releaseEvents( KEYPRESS | KEYDOWN | KEYUP );
 
=head2 requestAnimationFrame

This always returns C<undef> under perl.

Normally, under JavaScript, this tells the browser that an animation is in progress, requesting that the browser schedule a repaint of the window for the next animation frame.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame>

=head2 requestIdleCallback

This always returns C<undef> under perl.

Normally, under JavaScript, this enables the scheduling of tasks during a browser's idle periods.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/requestIdleCallback>

=head2 resizeBy

This always returns C<undef> under perl.

Normally, under JavaScript, this resizes the current window by a certain amount.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/resizeBy>

=head2 resizeTo

This always returns C<undef> under perl.

Normally, under JavaScript, this dynamically resizes window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/resizeTo>

=head2 scroll

This always returns C<undef> under perl.

Normally, under JavaScript, this scrolls the window to a particular place in the document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scroll>

=head2 scrollBy

This always returns C<undef> under perl.

Normally, under JavaScript, this scrolls the document in the window by the given amount.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollBy>

=head2 scrollByLines

This always returns C<undef> under perl.

Normally, under JavaScript, this scrolls the document by the given number of lines.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollByLines>

=head2 scrollByPages

This always returns C<undef> under perl.

Normally, under JavaScript, this scrolls the current document by the specified number of pages.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollByPages>

=head2 scrollTo

This always returns C<undef> under perl.

Normally, under JavaScript, this scrolls to a particular set of coordinates in the document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollTo>

=head2 setImmediate

This always returns C<undef> under perl.

Normally, under JavaScript, this executes a function after the browser has finished other heavy tasks

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/setImmediate>

=head2 setResizable

This always returns C<undef> under perl.

Normally, under JavaScript, this toggles a user's ability to resize a window.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/setResizable>

=head2 showDirectoryPicker

This always returns C<undef> under perl.

Normally, under JavaScript, this displays a directory picker which allows the user to select a directory.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/showDirectoryPicker>

=head2 showOpenFilePicker

This always returns C<undef> under perl.

Normally, under JavaScript, this shows a file picker that allows a user to select a file or multiple files.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/showOpenFilePicker>

=head2 showSaveFilePicker

This always returns C<undef> under perl.

Normally, under JavaScript, this shows a file picker that allows a user to save a file.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/showSaveFilePicker>

=head2 sizeToContent

This always returns C<undef> under perl.

Normally, under JavaScript, this sizes the window according to its content.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/sizeToContent>

=head2 stop

This always returns C<undef> under perl.

Normally, under JavaScript, this method stops window loading.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/stop>

=head2 updateCommands

This always returns C<undef> under perl.

Normally, under JavaScript, this updates the state of commands of the current chrome window (UI).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/updateCommands>

=head1 EVENTS

Event listeners for those events can also be found by prepending C<on> before the event type:

C<click> event listeners can be set also with C<onclick> method:

    $e->onclick(sub{ # do something });
    # or as an lvalue method
    $e->onclick = sub{ # do something };

=head2 error

Under perl, this is fired when this window object encounters an error.

Under JavaScript, this is fired when a resource failed to load, or cannot be used. For example, if a script has an execution error or an image can't be found or is invalid.
Also available via the onerror property.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/error_event>

=head1 UNSUPPORTED EVENTS

The following events are unsupported under perl, but you can still fire them by yourself using the L<HTML::Object::EventTarget/dispatchEvent>

=head2 devicemotion

Fired at a regular interval, indicating the amount of physical force of acceleration the device is receiving and the rate of rotation, if available.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/devicemotion_event>

=head2 deviceorientation

Fired when fresh data is available from the magnetometer orientation sensor about the current orientation of the device as compared to the Earth coordinate frame.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/deviceorientation_event>

=head2 languagechange

Fired at the global scope object when the user's preferred language changes.
Also available via the onlanguagechange property.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/languagechange_event>

=head2 orientationchange

Fired when the orientation of the device has changed.
Also available via the onorientationchange property.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/orientationchange_event>

=head2 resize

Fired when the window has been resized.
Also available via the onresize property.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/resize_event>

=head2 storage

Fired when a storage area (localStorage or sessionStorage) has been modified in the context of another document.
Also available via the onstorage property.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/storage_event>

=head1 UNSUPPORTED EVENT HANDLERS

Although those event handlers exist, their related events never get fired unless you fire them yourself.

=head2 onappinstalled

Called when the page is installed as a webapp. See appinstalled event.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/onappinstalled>

=head2 onbeforeinstallprompt

An event handler property dispatched before a user is prompted to save a web site to a home screen on mobile.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/onbeforeinstallprompt>

=head2 ondevicemotion

Called if accelerometer detects a change (For mobile devices)

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/ondevicemotion>

=head2 ondeviceorientation

Called when the orientation is changed (For mobile devices)

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/ondeviceorientation>

=head2 ondeviceorientationabsolute

An event handler property for any device orientation changes.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/ondeviceorientationabsolute>

=head2 ondeviceproximity

An event handler property for device proximity event (see C<DeviceProximityEvent>)

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/ondeviceproximity>

=head2 ongamepadconnected

Represents an event handler that will run when a gamepad is connected (when the gamepadconnected event fires).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/ongamepadconnected>

=head2 ongamepaddisconnected

Represents an event handler that will run when a gamepad is disconnected (when the gamepaddisconnected event fires).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/ongamepaddisconnected>

=head2 onrejectionhandled

An event handler for handled Promise rejection events.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onrejectionhandled>

=head2 onuserproximity

An event handler property for user proximity events (see C<UserProximityEvent>).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/onuserproximity>

=head2 onvrdisplayactivate

Represents an event handler that will run when a display is able to be presented to (when the vrdisplayactivate event fires), for example if an HMD has been moved to bring it out of standby, or woken up by being put on.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/onvrdisplayactivate>

=head2 onvrdisplayblur

Represents an event handler that will run when presentation to a display has been paused for some reason by the browser, OS, or VR hardware (when the vrdisplayblur event fires) — for example, while the user is interacting with a system menu or browser, to prevent tracking or loss of experience.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/onvrdisplayblur>

=head2 onvrdisplayconnect

Represents an event handler that will run when a compatible VR device has been connected to the computer (when the vrdisplayconnected event fires).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/onvrdisplayconnect>

=head2 onvrdisplaydeactivate

Represents an event handler that will run when a display can no longer be presented to (when the vrdisplaydeactivate event fires), for example if an HMD has gone into standby or sleep mode due to a period of inactivity.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/onvrdisplaydeactivate>

=head2 onvrdisplaydisconnect

Represents an event handler that will run when a compatible VR device has been disconnected from the computer (when the vrdisplaydisconnected event fires).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/onvrdisplaydisconnect>

=head2 onvrdisplayfocus

Represents an event handler that will run when presentation to a display has resumed after being blurred (when the vrdisplayfocus event fires).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/onvrdisplayfocus>

=head2 onvrdisplaypresentchange

represents an event handler that will run when the presenting state of a VR device changes — i.e. goes from presenting to not presenting, or vice versa (when the vrdisplaypresentchange event fires).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window/onvrdisplaypresentchange>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window>, L<W3C specifications|https://html.spec.whatwg.org/multipage/window-object.html>, L<StackOverlow about WindowProxy|https://stackoverflow.com/questions/16092835/windowproxy-and-window-objects>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
