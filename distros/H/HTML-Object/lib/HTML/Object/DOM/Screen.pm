##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Screen.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/31
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Screen;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::EventTarget );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Note: property availHeight
sub availHeight : lvalue { return( shift->_set_get_number( 'availheight', @_ ) ); }

# Note: property availLeft
sub availLeft : lvalue { return( shift->_set_get_number( 'availleft', @_ ) ); }

# Note: property availTop
sub availTop : lvalue { return( shift->_set_get_number( 'availtop', @_ ) ); }

# Note: property availWidth
sub availWidth : lvalue { return( shift->_set_get_number( 'availwidth', @_ ) ); }

# Note: property colorDepth
sub colorDepth : lvalue { return( shift->_set_get_number( 'colordepth', @_ ) ); }

# Note: property height
sub height : lvalue { return( shift->_set_get_number( 'height', @_ ) ); }

# Note: property left
sub left : lvalue { return( shift->_set_get_number( 'left', @_ ) ); }

sub lockOrientation { return( shift->_set_get_scalar_as_object( 'lockorientation', @_ ) ); }

# Note: property mozBrightness
sub mozBrightness : lvalue { return( shift->_set_get_number( 'mozbrightness', @_ ) ); }

# Note: property mozEnabled
sub mozEnabled : lvalue { return( shift->_set_get_boolean( 'mozenabled', @_ ) ); }

# Note: property orientation
sub orientation : lvalue { return( shift->_set_get_scalar_as_object( 'orientation', @_ ) ); }

# Note: property pixelDepth
sub pixelDepth : lvalue { return( shift->_set_get_number( 'pixeldepth', @_ ) ); }

# Note: property top
sub top : lvalue { return( shift->_set_get_number( 'top', @_ ) ); }

sub unlockOrientation { return; }

# Note: property width
sub width : lvalue { return( shift->_set_get_number( 'width', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Screen - HTML Object DOM Screen Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Screen;
    my $screen = HTML::Object::DOM::Screen->new || 
        die( HTML::Object::DOM::Screen->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The C<Screen> interface represents the screen, the only one, under perl, on which the current L<window object|HTML::Object::DOM::Window> exists, and is obtained using L<HTML::Object::DOM::Window/screen>.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +---------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Screen |
    +-----------------------+     +---------------------------+     +---------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::EventTarget>

=head2 availHeight

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this specifies the height of the screen, in pixels, minus permanent or semipermanent user interface features displayed by the operating system, such as the Taskbar on Windows.

Example:

    use HTML::Object::DOM qw( screen window );
    my $availHeight = window->screen->availHeight;

    my $paletteWindow = window->open( "panels.html", "Panels", "left=0, top=0, width=200" );

Another example:

    window->outerHeight = window->screen->availHeight;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/availHeight>

=head2 availLeft

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this returns the first available pixel available from the left side of the screen.

Example:

    use HTML::Object::DOM qw( screen window );
    my $availLeft = window->screen->availLeft;

    my $setX = window->screen->width - window->screen->availLeft;
    my $setY = window->screen->height - window->screen->availTop;
    # The following does absolutely nothing in perl, obviously
    window->moveTo( $setX, $setY );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/availLeft>

=head2 availTop

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this specifies the y-coordinate of the first pixel that is not allocated to permanent or semipermanent user interface features.

Example:

    my $availTop = window->screen->availTop;

    my $setX = window->screen->width - window->screen->availLeft;
    my $setY = window->screen->height - window->screen->availTop;
    # The following does absolutely nothing in perl, obviously
    window->moveTo( $setX, $setY );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/availTop>

=head2 availWidth

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this returns the amount of horizontal space in pixels available to the window.

Example:

    my $width = window->screen->availWidth

    my $screenAvailWidth = window->screen->availWidth;

    say( $screenAvailWidth );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/availWidth>

=head2 colorDepth

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this returns the color depth of the screen.

Example:

    use HTML::Object::DOM qw( screen window );
    # Check the color depth of the screen
    if( window->screen->colorDepth < 8 )
    {
        # Use low-color version of page
    }
    else
    {
        # Use regular, colorful page
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/colorDepth>

=head2 height

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this returns the height of the screen in pixels.

Example:

    my $height = window->screen->height

    use HTML::Object::DOM qw( screen window );
    if( window->screen->availHeight !== window->screen->height )
    {
         # Something is occupying some screen real estate!
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/height>

=head2 left

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this returns the distance in pixels from the left side of the main screen to the left side of the current screen.

Example:

    use HTML::Object::DOM qw( screen window );
    my $left = window->screen->left;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/left>

=head2 lockOrientation

Under perl environment this returns C<undef> by default, but you can set whatever value you want.

Under JavaScript, this locks the screen into a specified orientation into which to lock the screen. This is either a string or an array of strings. Passing several strings lets the screen rotate only in the selected orientations.

Possible values that are not enforced under this perl interface are:

=over 4

=item portrait-primary

It represents the orientation of the screen when it is in its primary portrait mode. A screen is considered in its primary portrait mode if the device is held in its normal position and that position is in portrait, or if the normal position of the device is in landscape and the device held turned by 90° clockwise. The normal position is device dependant.

=item portrait-secondary

It represents the orientation of the screen when it is in its secondary portrait mode. A screen is considered in its secondary portrait mode if the device is held 180° from its normal position and that position is in portrait, or if the normal position of the device is in landscape and the device held is turned by 90° counterclockwise. The normal position is device dependant.

=item landscape-primary

It represents the orientation of the screen when it is in its primary landscape mode. A screen is considered in its primary landscape mode if the device is held in its normal position and that position is in landscape, or if the normal position of the device is in portrait and the device held is turned by 90° clockwise. The normal position is device dependant.

=item landscape-secondary

It represents the orientation of the screen when it is in its secondary landscape mode. A screen is considered in its secondary landscape mode if the device held is 180° from its normal position and that position is in landscape, or if the normal position of the device is in portrait and the device held is turned by 90° counterclockwise. The normal position is device dependant.

=item portrait

It represents both portrait-primary and portrait-secondary.

=item landscape

It represents both landscape-primary and landscape-secondary.

=item default

It represents either portrait-primary and landscape-primary depends on natural orientation of devices. For example, if the panel resolution is 1280*800, default will make it landscape, if the resolution is 800*1280, default will make it to portrait.

=back

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/lockOrientation>

=head2 mozBrightness

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this Controls the brightness of a device's screen. A double between 0 and 1.0 is expected.

Example:

    use HTML::Object::DOM qw( screen window );
    my $screenBrightness = window->screen->mozBrightness;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/mozBrightness>

=head2 mozEnabled

Normally this is read-only, but under perl you can set whatever boolean value you want.

Under JavaScript, when this is set to false, it will turn off the device's screen.

Example:

    use HTML::Object::DOM qw( screen window );
    my $screenEnabled = window->screen->mozEnabled

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/mozEnabled>

=head2 orientation

Normally this returns C<undef> under perl, but you can set whatever string value you want. This returns a L<scalar object|Module::Generic::Scalar>

Under JavaScript, this returns the C<ScreenOrientation> instance associated with this screen.

Example:

    use HTML::Object::DOM qw( screen window );
    my $orientation = screen->$orientation;

    my $orientation = screen->orientation;

    if( $orientation == "landscape-primary" )
    {
        say( "That looks good." );
    }
    elsif( $orientation == "landscape-secondary" )
    {
        say( "Mmmh... the screen is upside down!" );
    }
    elsif( $orientation == "portrait-secondary" || $orientation == "portrait-primary" )
    {
        say( "Mmmh... you should rotate your device to landscape" );
    }
    elsif( $orientation == undefined )
    {
        say( "The orientation API is not supported in this browser :(" );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/orientation>

=head2 pixelDepth

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this gets the bit depth of the screen.

Example:

    use HTML::Object::DOM qw( screen window );
    my $depth = window->screen->pixelDepth

    # if there is not adequate bit depth
    # choose a simpler color
    if( window->screen->pixelDepth > 8 )
    {
        $doc->style->color = "#FAEBD7";
    }
    else
    {
        $doc->style->color = "#FFFFFF";
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/pixelDepth>

=head2 top

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this returns the distance in pixels from the top side of the current screen.

Example:

    use HTML::Object::DOM qw( screen window );
    my $top = window->screen->top;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/top>

=head2 width

Normally this returns C<undef> under perl, but you can set whatever number value you want.

Under JavaScript, this returns the width of the screen.

Example:

    use HTML::Object::DOM qw( screen window );
    my $lWidth = window->screen->width

    # Crude way to check that the screen is at least 1024x768
    if( window->screen->width >= 1024 && window->screen->height >= 768 )
    {
        # Resolution is 1024x768 or above
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/width>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::EventTarget>

=head2 unlockOrientation

This always returns C<undef> under perl.

Normally, under JavaScript, this unlocks the screen orientation (only works in fullscreen or for installed apps)

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Screen/unlockOrientation>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Window>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
