##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Style.pm
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
package HTML::Object::DOM::Element::Style;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :style );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{scoped} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'style' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property disabled inherited

# Note: property media
sub media : lvalue { return( shift->_set_get_property( 'media', @_ ) ); }

# Note: property scoped
sub scoped : lvalue { return( shift->_set_get_boolean( 'scoped', @_ ) ); }

# Note: property sheet read-only
sub sheet { return; }

# Note: property type inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Style - HTML Object DOM Style Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Style;
    my $style = HTML::Object::DOM::Element::Style->new || 
        die( HTML::Object::DOM::Element::Style->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface represents a C<style> element. It inherits properties and methods from its parent, L<HTML::Object::DOM::Element>.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Style |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 disabled

Is a boolean value reflecting the HTML attribute representing whether or not the stylesheet is disabled (true) or not (false).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLStyleElement/disabled>

=head2 media

Is a string representing the intended destination medium for style information.

Example:

    <!doctype html>
    <html>
        <head>
            <link id="LinkedStyle" rel="stylesheet" href="document.css" type="text/css" media="screen" />
            <style id="InlineStyle" rel="stylesheet" type="text/css" media="screen, print">
            p { color: blue; }
            </style>
        </head>
        <body>
        </body>
    </html>

    say( 'LinkedStyle: ' . $doc->getElementById( 'LinkedStyle' )->media ); # 'screen'
    say( 'InlineStyle: ' . $doc->getElementById( 'InlineStyle' )->media ); # 'screen, print'

Operators that can be used in the C<media> value:

=over 4

=item * and

Specifies an AND operator

=item * , (comma)

Specifies an OR operator

=item * not

Specifies a NOT operator

=back

Device names (not enforced by this interface) that can be used in the C<media> value:

=over 4

=item * all

Suitable for all devices. This is the default.

=item * aural

Speech synthesizers

=item * braille

Braille feedback devices -- for the visually impaired

=item * handheld

Handheld devices with small screens and limited bandwidth

=item * projection

Projector devices

=item * print

Printed pages or in print-preview mode

=item * screen

Computer screens

=item * tty

Teletypes and similar devices using a fixed-pitch character grid

=item * tv

Television type devices with low resolution and limited scrolling

=back

Tokens that can be used in the C<media> value:

=over 4

=item * aspect-ratio (width/height)

Ratio of width/height of the targeted display. Name can be prefixed with min- or max-.

=item * color (integer)

Bits per color of targeted display. Name can be prefixed with min- or max-.

=item * color-index (integer)

Number of colors the targeted display supports. Name can be prefixed with min- or max-.

=item * device-aspect-ratio (width/height)

Ratio of width/height of the device or paper. Name can be prefixed with min- or max-.

=item * device-height (pixels)

Height of the device or paper. Name can be prefixed with min- or max-.

=item * device-width (pixels)

Width of the device or paper. Name can be prefixed with min- or max-.

=item * grid (1 = grid, 0 = otherwise)

Whether output device is a grid or bitmap type.

=item * height (pixels)

Height of targeted display. Name can be prefixed with min- or max-.

=item * monochrome (integer)

Bits per pixel in a monochrome frame buffer. Name can be prefixed with min- or max-.

=item * orientation (landscape, portrait)

Orientation of the device or paper.

=item * resolution (dpi or dpcm)

Pixel density of the targeted display or paper. Name can be prefixed with min- or max-.

=item * scan (progressive interlace)

Scanning method of a tv display.

=item * width (pixels)

Width of targeted display. Name can be prefixed with min- or max-.

=back

Example:

    <style media="all and (orientation: portrait)"></style>
    <style media="screen and (aspect-ratio: 16/10)"></style>
    <style media="screen , (device-height: 540px)"></style>
    <style media="screen , (aspect-ratio: 5/4)"></style>
    <style media="screen and not (min-color-index: 512)"></style>
    <style media="screen and (min-width: 1200px)"></style>
    <style media="screen and (max-height: 720px)"></style>
    <style media="handheld and (grid: 1)"></style>
    <style media="tv and (scan: interlace)"></style>
    <style media="print and (resolution: 400dpi)"></style>
    <style media="screen and (max-monochrome: 2)"></style>
    <style media="screen and not (device-width: 360px)"></style>
    <style media="screen , (color: 8)"></style>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLStyleElement/media>

=head2 scoped

Is a boolean value indicating if the element applies to the whole document (false) or only to the parent's sub-tree (true).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLStyleElement/scoped>

=head2 sheet

Under perl, this always returns C<undef>, because processing a stylesheet would be time consuming, and an object is returned only when there is a C<href> HTML attribute set.

Under JavaScript, this returns the C<CSSStyleSheet> object associated with the given element, or C<undef> if there is none

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLStyleElement/sheet>

=head2 type

Is a string representing the type of style being applied by this statement.

Example:

    if( $newStyle->type != "text/css" )
    {
         # not supported!
         warnCSS();
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLStyleElement/type>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLStyleElement>, L<Mozilla documentation on style element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/style>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
