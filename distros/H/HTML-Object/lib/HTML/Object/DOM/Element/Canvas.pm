##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Canvas.pm
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
package HTML::Object::DOM::Element::Canvas;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :canvas );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'canvas' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

sub captureStream { return; }

sub getContext { return; }

# Note: property height is inherited

# Note: property
sub mozOpaque : lvalue { return( shift->_set_get_property( { attribute => 'moz-opaque', is_boolean => 1 }, @_ ) ); }

# Note: property
sub mozPrintCallback : lvalue { return( shift->_set_get_code( 'mozprintcallback', @_ ) ); }

sub onwebglcontextcreationerror : lvalue { return( shift->on( 'webglcontextcreationerror', @_ ) ); }

sub onwebglcontextlost : lvalue { return( shift->on( 'webglcontextlost', @_ ) ); }

sub onwebglcontextrestored : lvalue { return( shift->on( 'webglcontextrestored', @_ ) ); }

sub toBlob { return; }

sub toDataURL { return; }

sub transferControlToOffscreen { return; }

# Note: property width is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Canvas - HTML Object DOM Canvas Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Canvas;
    my $canvas = HTML::Object::DOM::Element::Canvas->new || 
        die( HTML::Object::DOM::Element::Canvas->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides properties and methods that are used for the C<<canvas>> element. However, since this is a perl framework, there is no such capability and it is provided here only to implement the properties and methods as accessors.

This interface also inherits the properties and methods of the L<HTML::Object::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Canvas |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

The description provided here is from Mozilla documentation.

=head2 height

The height HTML attribute of the C<<canvas>> element is a positive integer reflecting the number of logical pixels (or RGBA values) going down one column of the canvas. When the attribute is not specified, or if it is set to an invalid value, like a negative, the default value of 150 is used. If no [separate] CSS height is assigned to the C<<canvas>>, then this value will also be used as the height of the canvas in the length-unit CSS Pixel.

Example:

    <canvas id="canvas" width="300" height="300"></canvas>

    my $canvas = $doc->getElementById('$canvas');
    say( $canvas->height ); # 300

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/height>

=head2 mozOpaque

Is a boolean value reflecting the moz-opaque HTML attribute of the <canvas> element. It lets the canvas know whether or not translucency will be a factor. If the canvas knows there's no translucency, painting performance can be optimized. This is only supported in Mozilla-based browsers; use the standardized canvas.getContext('2d', { alpha: false }) instead.

Example:

    <canvas id="canvas" width="300" height="300" moz-opaque></canvas>

    my $canvas = $doc->getElementById('$canvas');
    say( $canvas->mozOpaque ); # true
    # deactivate it
    $canvas->mozOpaque = 0;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/mozOpaque>

=head2 mozPrintCallback

Is a function that is initially C<undef>. Web content can set this to a JavaScript function that will be called when the canvas is to be redrawn while the page is being printed. When called, the callback is passed a C<printState> object that implements the C<MozCanvasPrintState> interface. The callback can get the context to draw to from the C<printState> object and must then call C<done()> on it when finished. The purpose of C<mozPrintCallback> is to obtain a higher resolution rendering of the canvas at the resolution of the printer being used. L<See this blog post|https://blog.mozilla.org/labs/2012/09/a-new-way-to-control-printing-output/>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/mozPrintCallback>

=head2 width

The width HTML attribute of the <canvas> element is a positive integer reflecting the number of logical pixels (or RGBA values) going across one row of the canvas. When the attribute is not specified, or if it is set to an invalid value, like a negative, the default value of 300 is used. If no [separate] CSS width is assigned to the <canvas>, then this value will also be used as the width of the canvas in the length-unit CSS Pixel.

Example:

    <canvas id="canvas" width="300" height="300"></canvas>

    my $canvas = $doc->getElementById('$canvas');
    say( $canvas->width ); # 300

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/width>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

Keep in mind that none of those methods do anything and they all return C<undef>. The description provided here is from Mozilla documentation.

=head2 captureStream

Returns C<undef> since this feature is unavailable under perl.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/captureStream>

=head2 getContext

Returns C<undef> since this feature is unavailable under perl.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/getContext>

=head2 toBlob

Returns C<undef> since this feature is unavailable under perl.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/toBlob>

=head2 toDataURL

Returns C<undef> since this feature is unavailable under perl.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/toDataURL>

=head2 transferControlToOffscreen

Returns C<undef> since this feature is unavailable under perl.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/transferControlToOffscreen>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement>, L<Mozilla documentation on canvas element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/canvas>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
