##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Source.pm
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
package HTML::Object::DOM::Element::Source;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :source );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'source' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property media
sub media : lvalue { return( shift->_set_get_property( 'media', @_ ) ); }

# Note: property sizes
sub sizes : lvalue { return( shift->_set_get_property( 'sizes', @_ ) ); }

# Note: property src inherited

# Note: property srcset
sub srcset : lvalue { return( shift->_set_get_property( 'srcset', @_ ) ); }

# Note: property type inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Source - HTML Object DOM Source Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Source;
    my $source = HTML::Object::DOM::Element::Source->new || 
        die( HTML::Object::DOM::Element::Source->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties (beyond the regular L<HTML::Object::DOM::Element> object interface it also has available to it by inheritance) for manipulating <source> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Source |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 media

Is a string reflecting the media L<HTML attribute|HTML::Object::DOM::Attribute>, containing the intended type of the media resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSourceElement/media>

=head2 sizes

The sizes HTML attribute on an C<source> element specifies different image widths.

These widths are tied to browser conditions which helps create responsive images.

Example:

    <picture>
        <source srcset="/some/where/image-sm.jpg 120w,
                        /some/where/image.jpg 193w,
                        /some/where/image-lg.jpg 278w"
                sizes="(max-width: 710px) 120px,
                       (max-width: 991px) 193px,
                       278px" />
        <img src="/some/where/image-lg.jpg" alt="Some image" />
    </picture>

This means that:

=over 4

=item * A small image is used with a screen between 0 - 710px. The layout width is 120px.

=item * A medium image is used with a screen between 711px - 991px. The layout width is 193px.

=item * A large image is used with a screen 992px and larger. The layout width is 278px.

=back

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSourceElement/sizes>

=head2 src

Is a string reflecting the src L<HTML attribute|HTML::Object::DOM::Attribute>, containing the URL for the media resource. The C<src> property has a meaning only when the associated C<source> element is nested in a media element that is a L<video|HTML::Object::DOM::Element::Video> or an L<audio|HTML::Object::DOM::Element::Audio> element. It has no meaning and is ignored when it is nested in a C<picture> element.

Note: If the C<src> property is updated (along with any siblings), the parent L<HTML::Object::DOM::Element::Media>'s load method should be called when done, since C<source> elements are not re-scanned automatically.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSourceElement/src>

=head2 srcset

Is a string reflecting the srcset L<HTML attribute|HTML::Object::DOM::Attribute>, containing a list of candidate images, separated by a comma (',', U+002C COMMA). A candidate image is a URL followed by a 'w' with the width of the images, or an 'x' followed by the pixel density.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSourceElement/srcset>

=head2 type

Is a string reflecting the type L<HTML attribute|HTML::Object::DOM::Attribute>, containing the type of the media resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSourceElement/type>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSourceElement>, L<Mozilla documentation on source element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/source>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
